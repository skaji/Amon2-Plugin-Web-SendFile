# NAME

Amon2::Plugin::Web::SendFile - add send\_file() method to your Amon2 application

# SYNOPSIS

    use Amon2::Lite;

    __PACKAGE__->load_plugin('Web::SendFile');

    get '/download/hoge.zip' => sub {
        my $c = shift;
        return $c->send_file(filename => "hoge.zip", path => "/local/path/hoge.zip");
    };

    __PACKAGE__->to_app;

# DESCRIPTION

Amon2::Plugin::Web::SendFile adds `send_file()` method to your Amon2 application.

### `$c->send_file(%option)`

`send_file(%option)` method creates a Amon2::Web::Response object that has:

- content-type: application/octet-stream
- content-disposition: attachment; filename="filename"

Here `%option` may be:

- path

    path to local file. If you specify this, its filehandle will be set in the response body.

- body

    response body. You can specify either a string or a filehandle.

- filename

    filename. If you specify a string with ordinal value > 0x7f, then
    it is passed to `URI::Escape::uri_escape_utf8()`.

- length

    content length.

- status

    http status. default: 200

# LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>
