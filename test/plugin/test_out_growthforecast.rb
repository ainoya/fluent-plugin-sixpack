require 'helper'

class SixpackOutputTest < Test::Unit::TestCase
  # setup/teardown and tests of dummy sixpack server defined at the end of this class...
  SIXPACK_TEST_LISTEN_PORT = 5125

  CONFIG_NON_KEEPALIVE = %[
      sixpackapi_url http://127.0.0.1:#{SIXPACK_TEST_LISTEN_PORT}/
      keepalive false
  ]

  CONFIG_THREADING_KEEPALIVE = %[
      sixpackapi_url http://127.0.0.1:#{SIXPACK_TEST_LISTEN_PORT}/
      background_post true
      keepalive true
      timeout   120
  ]

  CONFIG_THREADING_NON_KEEPALIVE = %[
      sixpackapi_url http://127.0.0.1:#{SIXPACK_TEST_LISTEN_PORT}/
      keepalive false
  ]

  def create_driver(conf=CONFIG_NON_KEEPALIVE, tag='test.metrics')
    Fluent::Test::OutputTestDriver.new(Fluent::SixpackOutput, tag).configure(conf)
  end

  def test_convert
    d = create_driver(CONFIG_NON_KEEPALIVE, 'test.metrics')
    d.emit({'record_type' => 'convert',
            'client_id'  => "0000-0000-0000-0000",
            'experiment' => 'experiment_test_convert'})
    sleep 0.5 # wait internal posting thread loop

    assert_equal 1, @posted.size

    assert_equal '0000-0000-0000-0000', @posted[0][:client_id]
    assert_equal 'experiment_test_convert', @posted[0][:experiment]
  end

  def test_invalid_type
    d = create_driver(CONFIG_NON_KEEPALIVE, 'test.metrics')
    d.emit({'record_type' => 'invalid_type',
            'client_id'  => "0000-0000-0000-0000",
            'experiment' => 'experiment_test_invalid_type'})
    sleep 0.5 # wait internal posting thread loop

    assert_equal 0, @posted.size
  end

  def test_non_keepalive
    d = create_driver(CONFIG_NON_KEEPALIVE, 'test.metrics')
    ['red', 'blue', 'green'].each_with_index do |color, i|
      d.emit({'record_type' => 'participate',
             'alternatives' => 'red,blue,green',
             'alternative'  =>  color,
             'client_id'  => "0000-0000-0000-000#{i}",
             'experiment' => 'experiment_test_threading_non_keepalive'})
      sleep 0.5 # wait internal posting thread loop
    end

    assert_equal 3, @posted.size
    v1st = @posted[0]
    v2nd = @posted[1]
    v3rd = @posted[2]

    assert_equal 'red', v1st[:alternative]
    assert_equal '0000-0000-0000-0000', v1st[:client_id]
    assert_nil v1st[:auth]
    assert_equal 'experiment_test_threading_non_keepalive', v1st[:experiment]

    assert_equal 'blue', v2nd[:alternative]
    assert_equal '0000-0000-0000-0001', v2nd[:client_id]
    assert_nil v2nd[:auth]
    assert_equal 'experiment_test_threading_non_keepalive', v2nd[:experiment]

    assert_equal 'green', v3rd[:alternative]
    assert_equal '0000-0000-0000-0002', v3rd[:client_id]
    assert_nil v3rd[:auth]
    assert_equal 'experiment_test_threading_non_keepalive', v3rd[:experiment]
  end

  def test_threading
    d = create_driver(CONFIG_THREADING_KEEPALIVE, 'test.metrics')
    ['red', 'blue', 'green'].each_with_index do |color, i|
      d.emit({'record_type' => 'participate',
             'alternatives' => 'red,blue,green',
             'alternative'  =>  color,
             'client_id'  => "0000-0000-0000-000#{i}",
             'experiment' => 'experiment_test_threading_non_keepalive'})
      sleep 0.5 # wait internal posting thread loop
    end

    assert_equal 3, @posted.size
    v1st = @posted[0]
    v2nd = @posted[1]
    v3rd = @posted[2]

    assert_equal 'red', v1st[:alternative]
    assert_equal '0000-0000-0000-0000', v1st[:client_id]
    assert_nil v1st[:auth]
    assert_equal 'experiment_test_threading_non_keepalive', v1st[:experiment]

    assert_equal 'blue', v2nd[:alternative]
    assert_equal '0000-0000-0000-0001', v2nd[:client_id]
    assert_nil v2nd[:auth]
    assert_equal 'experiment_test_threading_non_keepalive', v2nd[:experiment]

    assert_equal 'green', v3rd[:alternative]
    assert_equal '0000-0000-0000-0002', v3rd[:client_id]
    assert_nil v3rd[:auth]
    assert_equal 'experiment_test_threading_non_keepalive', v3rd[:experiment]
  end

  def test_threading_non_keepalive
    d = create_driver(CONFIG_THREADING_NON_KEEPALIVE, 'test.metrics')
    ['red', 'blue', 'green'].each_with_index do |color, i|
      d.emit({'record_type' => 'participate',
             'alternatives' => 'red,blue,green',
             'alternative'  =>  color,
             'client_id'  => "0000-0000-0000-000#{i}",
             'experiment' => 'experiment_test_threading_non_keepalive'})
      d.run
      sleep 0.5 # wait internal posting thread loop
    end

    assert_equal 3, @posted.size
    v1st = @posted[0]
    v2nd = @posted[1]
    v3rd = @posted[2]

    assert_equal 'red', v1st[:alternative]
    assert_equal '0000-0000-0000-0000', v1st[:client_id]
    assert_nil v1st[:auth]
    assert_equal 'experiment_test_threading_non_keepalive', v1st[:experiment]

    assert_equal 'blue', v2nd[:alternative]
    assert_equal '0000-0000-0000-0001', v2nd[:client_id]
    assert_nil v2nd[:auth]
    assert_equal 'experiment_test_threading_non_keepalive', v2nd[:experiment]

    assert_equal 'green', v3rd[:alternative]
    assert_equal '0000-0000-0000-0002', v3rd[:client_id]
    assert_nil v3rd[:auth]
    assert_equal 'experiment_test_threading_non_keepalive', v3rd[:experiment]
  end


  # setup / teardown for servers
  def setup
    Fluent::Test.setup
    @posted = []
    @prohibited = 0
    @auth = false
    @enable_float_number = false
    @dummy_server_thread = Thread.new do
      srv = if ENV['VERBOSE']
              WEBrick::HTTPServer.new({:BindAddress => '127.0.0.1', :Port => SIXPACK_TEST_LISTEN_PORT})
            else
              logger = WEBrick::Log.new('/dev/null', WEBrick::BasicLog::DEBUG)
              WEBrick::HTTPServer.new({:BindAddress => '127.0.0.1', :Port => SIXPACK_TEST_LISTEN_PORT, :Logger => logger, :AccessLog => []})
            end
      begin
        srv.mount_proc('/participate') { |req,res|
          unless req.request_method == 'GET'
            res.status = 405
            res.body = 'request method mismatch'
            next
          end
          if @auth and req.header['authorization'][0] == 'Basic YWxpY2U6c2VjcmV0IQ==' # pattern of user='alice' passwd='secret!'
            # ok, authorized
          elsif @auth
            res.status = 403
            @prohibited += 1
            next
          else
            # ok, authorization not required
          end

          @posted.push({
              :alternatives=> req.query["alternatives"],
              :alternative => req.query["alternative"],
              :client_id   => req.query["client_id"],
              :experiment  => req.query["experiment"]
            })

          res.status = 200
        }
        srv.mount_proc('/convert') { |req,res|
          @posted.push({
              :client_id   => req.query["client_id"],
              :experiment  => req.query["experiment"]
            })
          res.status = 200
        }
        srv.mount_proc('/') { |req,res|
          res.status = 200
          res.body = 'running'
        }
        srv.start
      ensure
        srv.shutdown
      end
    end

    # to wait completion of dummy server.start()
    require 'thread'
    cv = ConditionVariable.new
    watcher = Thread.new {
      connected = false
      while not connected
        begin
          get_content('localhost', SIXPACK_TEST_LISTEN_PORT, '/')
          connected = true
        rescue Errno::ECONNREFUSED
          sleep 0.1
        rescue StandardError => e
          p e
          sleep 0.1
        end
      end
      cv.signal
    }
    mutex = Mutex.new
    mutex.synchronize {
      cv.wait(mutex)
    }
  end

  def test_dummy_server
    d = create_driver
    d.instance.sixpackapi_url =~ /^http:\/\/([.:a-z0-9]+)\//
    server = $1
    host = server.split(':')[0]
    port = server.split(':')[1].to_i
    client = Net::HTTP.start(host, port)

    assert_equal '200', client.request_get('/').code
    assert_equal '200', client.request_get('/participate?experiment=experiment_test_threading_non_keepalive&alternatives=red&alternatives=blue&alternatives=green&alternative=green&client_id=0000-0000-0000-0001').code

    assert_equal 1, @posted.size

    assert_equal 'green', @posted[0][:alternative]
    assert_equal '0000-0000-0000-0001', @posted[0][:client_id]
    assert_nil @posted[0][:auth]
    assert_equal 'experiment_test_threading_non_keepalive', @posted[0][:experiment]

    @auth = true

    req_with_auth = lambda do |number, mode, user, pass|
      url = URI.parse("http://#{host}:#{port}/participate")
      req = Net::HTTP::Get.new(url.path)
      req.basic_auth user, pass
      req.set_form_data({'number'=>number, 'mode'=>mode})
      req
    end

    assert_equal '403', client.request(req_with_auth.call(500, 'count', 'alice', 'wrong password!')).code

    assert_equal 1, @posted.size

    assert_equal '200', client.request(req_with_auth.call(500, 'count', 'alice', 'secret!')).code

    assert_equal 2, @posted.size

  end

  def teardown
    @dummy_server_thread.kill
    @dummy_server_thread.join
  end

end
