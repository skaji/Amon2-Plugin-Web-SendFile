requires 'perl', '5.008005';
requires 'Amon2';
requires 'URI::Escape';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'HTTP::Request::Common';
};
