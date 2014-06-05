class Fluent::SixpackOutput < Fluent::Output
  Fluent::Plugin.register_output('sixpack', self)

  def initialize
    super
    require 'net/http'
    require 'uri'
    require 'resolve/hostname'
  end

  config_param :sixpackapi_url, :string
  config_param :key_experiment, :default   => 'experiment'
  config_param :key_alternatives, :default => 'alternatives'
  config_param :key_alternative, :default     => 'alternative'
  config_param :key_client_id, :default    => 'client_id'
  config_param :key_record_type, :default  => 'record_type'

  config_param :user_agent, :default       => 'user_agent'
  config_param :ip_address, :default       => 'ip_address'

  config_param :ssl, :bool, :default => false
  config_param :verify_ssl, :bool, :default => false

  config_param :mode, :string, :default => 'gauge' # or count/modified

  config_param :background_post, :bool, :default => false

  config_param :timeout, :integer, :default => nil # default 60secs
  config_param :retry, :bool, :default => true
  config_param :keepalive, :bool, :default => true

  config_param :authentication, :string, :default => nil # nil or 'none' or 'basic'
  config_param :username, :string, :default => ''
  config_param :password, :string, :default => ''

  SIXPACK_PATH= {
    :participate => '/participate',
    :convert     => '/convert'
  }

  # Define `log` method for v0.10.42 or earlier
  unless method_defined?(:log)
    define_method("log") { $log }
  end

  def configure(conf)
    super

    @mode = case @mode
            when 'count' then :count
            when 'modified' then :modified
            else
              :gauge
            end

    @auth = case @authentication
            when 'basic' then :basic
            else
              :none
            end
    @resolver = Resolve::Hostname.new(:system_resolver => true)
  end

  def start
    super

    @running = true
    @thread = nil
    @queue = nil
    @mutex = nil
    if @background_post
      @mutex = Mutex.new
      @queue = []
      @thread = Thread.new(&method(:poster))
    end
  end

  def shutdown
    @running = false
    @thread.join if @thread
    super
  end

  def poster
    while @running
      if @queue.size < 1
        sleep(0.2)
        next
      end

      events = @mutex.synchronize {
        es,@queue = @queue,[]
        es
      }
      begin
        post_events(events) if events.size > 0
      rescue => e
        log.warn "HTTP POST in background Error occures to sixpack server", :error_class => e.class, :error => e.message
      end
    end
  end

  def connect_to
    url = URI.parse(@sixpackapi_url)
    return url.host, url.port
  end

  def http_connection(host, port)
    http = Net::HTTP.new(@resolver.getaddress(host), port)
    if @timeout
      http.open_timeout = @timeout
      http.read_timeout = @timeout
    end
    if @ssl
      http.use_ssl = true
      unless @verify_ssl
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end
    http
  end

  def map_sixpack_path(record)
    sixpack_path
  end

  def map_sixpack_path_with_query(record)
    sixpack_path = SIXPACK_PATH[record[@key_record_type].to_sym]
    case record[@key_record_type]
    when 'participate'
      return sixpack_path, URI.encode_www_form({
               :experiment   => record[@key_experiment],
               :alternatives => record[@key_alternatives].split(','),
               :alternative  => record[@key_alternative],
               :client_id    => record[@key_client_id],
             })
    when 'convert'
      return sixpack_path, URI.encode_www_form({
               :experiment   => record[@key_experiment],
               :client_id    => record[@key_client_id],
             })
    else
      log.warn 'failed to map sixpack path and query'
      raise
    end
  end

  def post_request(event)
    uri = URI.parse(@sixpackapi_url)
    uri.path, uri.query = map_sixpack_path_with_query(event[:record])
    req = Net::HTTP::Get.new(uri.request_uri)
    if @auth and @auth == :basic
      req.basic_auth(@username, @password)
    end
    req['Host'] = uri.host
    if @keepalive
      req['Connection'] = 'Keep-Alive'
    end

    req
  end

  def post(event)
    url = @sixpackapi_url
    res = nil
    begin
      host,port = connect_to
      req = post_request(event)
      http = http_connection(host, port)
      res = http.start {|http| http.request(req) }
    rescue IOError, EOFError, SystemCallError
      # server didn't respond
      log.warn "net/http GET raises exception: #{$!.class}, '#{$!.message}'"
    end
    unless res and res.is_a?(Net::HTTPSuccess)
      log.warn "failed to post to sixpack #{url}, record#{event[:record]}, code: #{res && res.code}"
    end
  end

  def post_keepalive(events) # [{:tag=>'',:name=>'',:value=>X}]
    return if events.size < 1

    # sixpack host/port is same for all events (host is from configuration)
    host,port = connect_to

    requests = events.map{|e| post_request(e)}

    http = nil
    requests.each do |req|
      begin
        unless http
          http = http_connection(host, port)
          http.start
        end
        res = http.request(req)
        unless res and res.is_a?(Net::HTTPSuccess)
          log.warn "failed to post to sixpack: #{host}:#{port}#{req.path}, post_data: #{req.body} code: #{res && res.code}"
        end
      rescue IOError, EOFError, Errno::ECONNRESET, Errno::ETIMEDOUT, SystemCallError
        log.warn "net/http keepalive POST raises exception: #{$!.class}, '#{$!.message}'"
        begin
          http.finish
        rescue
          # ignore all errors for connection with error
        end
        http = nil
      end
    end
    begin
      http.finish
    rescue
      # ignore
    end
  end

  def post_events(events)
    if @keepalive
      post_keepalive(events)
    else
      events.each do |event|
        post(event)
      end
    end
  end

  def emit(tag, es, chain)
    events = []

    es.each {|time,record|
      if SIXPACK_PATH.has_key?(record[@key_record_type].to_sym)
        events.push({:time => time, :tag => tag, :record => record})
      end
    }

    if @thread
      @mutex.synchronize do
        @queue += events
      end
    else
      begin
        post_events(events)
      rescue => e
        log.warn "HTTP POST Error occures to sixpack server", :error_class => e.class, :error => e.message
        raise if @retry
      end
    end

    chain.next
  end
end
