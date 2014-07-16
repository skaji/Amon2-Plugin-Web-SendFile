use strict;
use warnings;
use utf8;
use HTTP::Request::Common;
use Plack::Test;
use Test::More;
use Data::Dumper;
use URI::Escape 'uri_unescape';
use Encode 'decode_utf8';
use File::Temp 'tempdir';
sub spew {
    my ($file, $string) = @_;
    open my $fh, ">:utf8", $file or die;
    print {$fh} $string;
}
my $tempdir = tempdir CLEANUP => 1;
my $content = "this is file.txt";
my $content_length = length($content);
spew "$tempdir/file.txt", $content;

{ package MyApp; use parent qw/Amon2/; }
{
    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    __PACKAGE__->load_plugin('Web::SendFile');
    sub dispatch { MyApp::Web::Dispather->dispatch(shift) }
}
{
    package MyApp::Web::Dispather;
    use Amon2::Web::Dispatcher::RouterBoom;
    get "/die1" => sub {
        my $c = shift;
        $c->send_file;
    };
    get "/die2" => sub {
        my $c = shift;
        $c->send_file( body => "hoge" ); # filename is missing
    };
    get "/die3" => sub {
        my $c = shift;
        $c->send_file( body => "hoge", path => "$tempdir/file.txt" ); # both body and filename NG
    };
    get "/body-string" => sub {
        my $c = shift;
        $c->send_file(body => "hoge", filename => "hoge.txt");
    };
    get "/body-io" => sub {
        my $c = shift;
        open my $fh, "<", "$tempdir/file.txt" or die;
        $c->send_file(body => $fh, filename =>"hoge.txt");
    };
    get "/non-ascii" => sub {
        my $c = shift;
        $c->send_file(body => "hoge", filename => "ファイル.txt");
    };
    get "/path" => sub {
        my $c = shift;
        $c->send_file(path => "$tempdir/file.txt");
    };
    get "/status-418" => sub {
        my $c = shift;
        $c->send_file(status => 418, body => "hoge", filename => "hoge.txt");
    };
    get "/utf8" => sub {
        my $c = shift;
        $c->send_file(utf8 => 1, body => "hoge", filename => "hoge.txt");
    };
}

my $app = MyApp::Web->to_app;

test_psgi $app, sub {
    my $cb  = shift;
    my %header = ( 'user-agent' => "test agent" );
    for (1..3) {
        my $res = $cb->( GET "/die$_", %header );
        is $res->code, 500;
    }
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET "/body-string" );
    is $res->code, 200;
    is $res->header('content-type'), "application/octet-stream";
    is $res->header('content-length'), length("hoge");
    is $res->header('content-disposition'), qq[attachment; filename="hoge.txt"];
    is $res->content, "hoge";
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET "/body-io" );
    is $res->code, 200;
    is $res->header('content-type'), "application/octet-stream";
    is $res->header('content-length'), $content_length;
    is $res->header('content-disposition'), qq[attachment; filename="hoge.txt"];
    is $res->content, $content;
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET "/non-ascii" );
    is $res->code, 200;
    is $res->header('content-type'), "application/octet-stream";
    is $res->header('content-length'), length("hoge");
    my $content_disposition = $res->header('content-disposition');
    my ($escaped_filename)
        = $content_disposition =~ /^attachment; filename\*=UTF-8''(.+)$/;
    if ($escaped_filename) {
        is decode_utf8(uri_unescape($escaped_filename)), "ファイル.txt";
    } else {
        fail "Oops";
    }
    is $res->content, "hoge";
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET "/path" );
    is $res->code, 200;
    is $res->header('content-type'), "application/octet-stream";
    is $res->header('content-length'), $content_length;
    is $res->header('content-disposition'), qq[attachment; filename="file.txt"];
    is $res->content, $content;
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET "/status-418" );
    is $res->code, 418;
    is $res->header('content-type'), "application/octet-stream";
    is $res->header('content-length'), length("hoge");
    is $res->header('content-disposition'), qq[attachment; filename="hoge.txt"];
    is $res->content, "hoge";
};

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET "/utf8" );
    is $res->code, 200;
    is $res->header('content-type'), "application/octet-stream";
    is $res->header('content-length'), length("hoge");
    is $res->header('content-disposition'), qq[attachment; filename*=UTF-8''hoge.txt];
    is $res->content, "hoge";
};

done_testing;

