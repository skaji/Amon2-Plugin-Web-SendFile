package Amon2::Plugin::Web::SendFile;
use 5.008005;
use strict;
use warnings;
use utf8;
use Carp 'croak';
use File::Basename 'basename';
use URI::Escape 'uri_escape_utf8';

our $VERSION = "0.01";

use Amon2::Util ();

sub init {
    my ($class, $c, $config) = @_;
    Amon2::Util::add_method($c, 'send_file', sub {
        my ($c, %option) = @_;
        if ($option{path} && $option{body}) {
            croak "Cannot specify both 'path' and 'body' option";
        }
        if (!$option{path} && !$option{filename}) {
            croak "Cannot determine 'filename'";
        }

        my ($body, $length) = ($option{body}, $option{length});
        unless ($body) {
            open my $fh, "<", $option{path}
                or croak "Cannot open '$option{path}': $!";
            $body = $fh;
        }
        $length ||= ref $body ? -s $body : length $body;

        my $filename = $option{filename} || basename($option{path});

        my $filename_field;
        if ($filename =~ /[^\x00-\x7f]/) { # XXX [^\x00-\xff] ?
            $filename_field =  q[filename*=UTF-8''] . uri_escape_utf8($filename);
        } else {
            $filename_field = qq[filename="$filename"];
        }

        my $res = $c->create_response( $option{status} || 200 );
        $res->content_type( "application/octet-stream" );
        $res->content_length( $length );
        $res->header( 'content-disposition' => qq[attachment; $filename_field] );
        $res->body( $body );
        $res;
    });
}

1;
__END__

=encoding utf-8

=for stopwords wget

=head1 NAME

Amon2::Plugin::Web::SendFile - add send_file() method to your Amon2 application

=head1 SYNOPSIS

    use Amon2::Lite;

    __PACKAGE__->load_plugin('Web::SendFile');

    get '/download/hoge.zip' => sub {
        my $c = shift;
        return $c->send_file(filename => "hoge.zip", path => "/local/path/hoge.zip");
    };

    __PACKAGE__->to_app;

=head1 DESCRIPTION

Amon2::Plugin::Web::SendFile adds C<send_file()> method to your Amon2 application.

=head3 C<< $c->send_file(%option) >>

C<send_file(%option)> method creates a Amon2::Web::Response object that has:

=over 4

=item content-type: application/octet-stream

=item content-disposition: attachment; filename="filename"

=back

Here C<%option> may be:

=over 4

=item path

path to local file. If you specify this, its filehandle will be set in the response body.

=item body

response body. You can specify either a string or a filehandle.

=item filename

filename. If you specify a string with ordinal value > 0x7f, then
it is passed to C<URI::Escape::uri_escape_utf8()>.

=item length

content length.

=item status

http status. default: 200

=back

=head1 TIPS

=head3 How to respect the filename field when using curl or wget?

    > wget --content-disposition http://your-host/path/to/file
    > curl -J -O http://your-host/path/to/file

=head1 SEE ALSO

http://qiita.com/kuboon/items/fbf2c84b343d95e46663

http://greenbytes.de/tech/tc2231/

=head1 LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shoichi Kaji E<lt>skaji@cpan.orgE<gt>

=cut

