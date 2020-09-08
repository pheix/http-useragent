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
my @req = [HTTP::Request.new(GET => 'http://gitlab.com'), HTTP::Request.new(GET => 'https://github.com')];

subtest {
    for ^conn_num -> $conn_index {
        for @req -> $r {
            my $conn = $ua.get-connection($r);

            ok ($ua.store_connection(:name($conn_index.Str), :conn($conn)) >= 0),
                'connection <' ~ $conn_index ~ '> is stored';

            ok $ua.check_connection(:name($conn_index.Str)),
                'connection <' ~ $conn_index ~ '> is checked';

            my %c = $ua.fetch_connection(:name($conn_index.Str));

            ok %c, 'connection <' ~ $conn_index ~ '> is fetched';

            if %c {
                my %cc = name => $conn_index.Str, conn => $conn;

                is-deeply %cc, %c, 'connection <' ~ $conn_index ~ '> is fetched';
                ok $ua.close_connection(:name($conn_index.Str)),
                    'connection <' ~ $conn_index ~ '> is closed';
            }
            else {
                skip 'no connection fetched', 2;
            }
        }
    }

    is $ua.connections.elems, 0,
        'found no stored connections';
}, 'store, check, fetch and close connection methods';

subtest {
    for ^conn_num -> $conn_index {
        my Str $conname = 'connection' ~ $conn_index;
        for @req -> $r {
            my $conn = $ua.get-connection($r);

            ok ($ua.store_connection(:name($conname), :conn($conn)) >= 0),
                'connection <' ~ $conname ~ '> is stored';
        }
    }

    for ^conn_num -> $conn_index {
        my Str $conname = 'connection' ~ $conn_index;
        for @req -> $r {

            my Bool $validconn = $ua.check_connection(:name($conname));

            ok $validconn, 'connection <' ~ $conname ~ '> is checked';

            if $validconn {
                $r.header.field(Connection => 'Keep-Alive');

                is $ua.request($r, :conn_name($conname)).code, 200,
                    'connection <' ~ $conname ~ '> is reused';

                ok $ua.close_connection(:name($conname), :skipclean(True)),
                    'connection <' ~ $conname ~ '> is closed';
            }
            else {
                skip 'no connection <' ~ $conname.Str ~ '> is stored', 2;
            }
        }
    }

    is $ua.cleanup_connections, 0,
        'connections cleanup';

    nok $ua.connections.elems,
        'no stored connections';
}, 'connection reuse and cleanup';
