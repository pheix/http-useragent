use v6;
use Test;
use HTTP::UserAgent;

plan 2;

unless %*ENV<NETWORK_TESTING> {
  diag "NETWORK_TESTING was not set";
  skip-rest("NETWORK_TESTING was not set");
  exit;
}

constant conn_num = 10;

my $ua  = HTTP::UserAgent.new;
my $req = HTTP::Request.new( GET => 'http://gitlab.com' );

subtest {
    for ^conn_num {
        my $conn = $ua.get-connection($req);

        ok ($ua.store_connection(:name($_.Str), :conn($conn)) >= 0),
            'connection <' ~ $_ ~ '> is stored';

        ok $ua.check_connection(:name($_.Str)),
            'connection <' ~ $_ ~ '> is checked';

        my %c  = $ua.fetch_connection(:name($_.Str));
        my %cc = name => $_.Str, conn => $conn;
        is-deeply %c, %cc, 'connection <' ~ $_ ~ '> is fetched';

        ok $ua.close_connection(:name($_.Str)),
            'connection <' ~ $_ ~ '> is closed';
    }

    is $ua.connections.elems, 0,
        'found no stored connections';
}, 'store, check, fetch and close connection methods';

subtest {
    for ^conn_num {
        my $conn = $ua.get-connection($req);

        ok ($ua.store_connection(:name($_.Str), :conn($conn)) >= 0),
            'connection <' ~ $_ ~ '> is stored';
    }

    for ^conn_num {
        is $ua.request($req, :conn_name($_.Str)).code, 200,
            'connection <' ~ $_ ~ '> is reused';
        ok $ua.close_connection(:name($_.Str), :skipclean(True)),
            'connection <' ~ $_ ~ '> is closed';
    }

    is $ua.cleanup_connections, 0,
        'connections cleanup';

    nok $ua.connections.elems,
        'no stored connections';
}, 'connection reuse and cleanup';
