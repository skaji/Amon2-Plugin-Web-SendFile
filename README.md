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

    filename. If filename contains a wide character,
    then it is assumed `utf8` option true.

- utf8

    if true, `filename` is passed to `URI::Escape::uri_escape_utf8()`
    and `content-disposition` header will be

        q[attachment; filename*=UTF-8''] . URI::Escape::uri_escape_utf8(filename)

- length

    content length.

- status

    http status. default: 200

# TIPS

### How to respect the filename field when using curl or wget?

    > wget --content-disposition http://your-host/path/to/file
    > curl -J -O http://your-host/path/to/file

# SEE ALSO

http://qiita.com/kuboon/items/fbf2c84b343d95e46663

http://greenbytes.de/tech/tc2231/

# LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>
