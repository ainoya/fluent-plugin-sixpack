# fluent-plugin-sixpack

## SixpackOutput

[![Build Status](https://travis-ci.org/ainoya/fluent-plugin-sixpack.svg?branch=master)](https://travis-ci.org/ainoya/fluent-plugin-sixpack)

[Fluentd](http://fluentd.org) plugin to execute A/B testing with application log.

To get A/B test statistics, this plugin forwards logs to Sixpack server.

About Sixpack, see:
* Github: https://github.com/seatgeek/sixpack
* Product site: http://sixpack.seatgeek.com

### Configuration

For messages to participate A/B test such as:

    tag:your.arbitrary.tag {"record_type":"participate", "experiment":"header-color", "alternatives":"red,green,blue", "alternative":"red", "client_id":"ID-0000-0001"}

Or messages to convert A/B test such as

    tag:your.arbitrary.tag {"record_type":"convert", "experiment":"header-color", "client_id":"ID-0000-0001"}
    #you can also specify kpi id
    tag:your.arbitrary.tag {"record_type":"convert", "experiment":"header-color", "client_id":"ID-0000-0001", "kpi":"conversion-100dollar"}

Configuration example for graphs in sixpack with POST api url `http://sixpack:5000/(participate|convert)`. You must set this parameter.

    <match app.abtest.log>
      type sixpack
      sixpackapi_url http://sixpack.local:5000/
    </match>

With this configuration, out_sixpack posts urls below.

## Parameters

### Sixpack parameters

You can change assignment between param keys and values, with using settings below.

- `key_experiment, :default   => 'experiment'`
- `key_alternatives, :default => 'alternatives'`
- `key_alternative, :default  => 'alternative'`
- `key_client_id, :default    => 'client_id'`
- `key_record_type, :default  => 'record_type'`
- `key_kpi ,        :default  => 'kpi'`

### Configuration parameters

* background_post

    Post to Sixpack in background thread, without retries for failures (Default: false)

* timeout

    Read/Write timeout seconds (Default: 60)

* retry

    Do retry for HTTP request failures, or not. This feature will be set as false for `background_post yes` automatically. (Default: true)

* ssl

    Use SSL (https) or not. Default is false.

* verify\_ssl

    Do SSL verification or not. Default is false (ignore the SSL verification).

* authentication

    Specify `basic` if your Sixpack protected with basic authentication. Default is 'none' (no authentication).

* username

    The username for authentication.

* password

    The password for authentication.

## TODO

* More Test
* More Documents
* Full compatibility with sixpack api

## Contributing

Once you've made your great commits:

1. [Fork][fk] fluent-plugin-sixpack
2. Create your feature branch (``git checkout -b my-new-feature``)
3. Write tests
4. Run tests with ``rake test``
5. Commit your changes (``git commit -am 'Added some feature'``)
6. Push to the branch (``git push origin my-new-feature``)
7. Create new pull request
8. That's it!

Or, you can create an [Issue][is].

## License

### Copyright

* Copyright (c) 2014- Naoki AINOYA
* License
  * Apache License, Version 2.0

## Other Licence

### Copyright of fluent-plugin-growthforecast

This plugin implementation is based on [fluent-plugin-growthforecast](https://github.com/tagomoris/fluent-plugin-growthforecast).

* Copyright (c) 2012- TAGOMORI Satoshi (tagomoris)
* License
  * Apache License, Version 2.0

[fk]: http://help.github.com/forking/
