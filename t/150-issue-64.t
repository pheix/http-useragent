#!perl6

use v6;
use Test;
use HTTP::UserAgent;

plan 3;

unless %*ENV<NETWORK_TESTING> {
  diag "NETWORK_TESTING was not set";
  skip-rest("NETWORK_TESTING was not set");
  exit;
}

my $purl = 'http://purl.org/dc/elements/1.1/';

my $ua = HTTP::UserAgent.new(
    useragent =>
        'Mozilla/5.0 (X11; Fedora-Pheix; Linux x86_64; rv:72.0) ' ~
        'Gecko/20100101 Firefox/72.0'
);

my HTTP::Response $resp;

lives-ok { $resp = $ua.get($purl) }, "make request to '$purl' lives";
ok($resp.is-success, "request was successful");
ok($resp.content.defined, "and got some content back");


done-testing();
# vim: expandtab shiftwidth=4 ft=perl6
