# fluent-plugin-sixpack 

## SixpackOutput

[Fluentd](http://fluentd.org) plugin to 

About Sixpack, see:
* Github: https://github.com/seatgeek/sixpack
* Product site: http://sixpack.seatgeek.com

### Configuration

For messages such as:
    tag:metrics {"field1":300, "field2":20, "field3diff":-30}

Configuration example for graphs in sixpack with POST api url `http://sixpack.local/(participate|convert)`

    <match app.abtest.log>
      type sixpack
      gfapi_url http://sixpack.local/api/
    </match>

With this configuration, out_sixpack posts urls below.

## Parameters

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

* patches welcome!

## Licence

## Copyright of fluent-plugin-growthforecast

This plugin implementation is based on [fluent-plugin-growthforecast](https://github.com/tagomoris/fluent-plugin-growthforecast).

* Copyright (c) 2012- TAGOMORI Satoshi (tagomoris)
* License
  * Apache License, Version 2.0
