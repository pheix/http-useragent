class HTTP::UserAgent;

use HTTP::Response;
use HTTP::Request;

use HTTP::UserAgent::Common;

class X::HTTP is Exception {
    has $.rc;
}

class X::HTTP::Response is X::HTTP {
    method message {
        "Response error: '$.rc'";
    }
}

class X::HTTP::Server is X::HTTP {
    method message {
        "Server error: '$.rc'";
    }
}

has Int $.timeout is rw = 180;
has $.useragent;

method get(Str $url) {
    my $request = HTTP::Request.new(GET => $url);
    my $conn = IO::Socket::INET.new(:host($request.header('Host')), :port(80), :timeout($.timeout));

    my $s;
    if $conn.send($request.Str ~ "\r\n") {
        $s = $conn.lines.join("\n");
    }

    $conn.close;

    my $response = HTTP::Response.new.parse($s);

    X::HTTP::Response.new(:rc($response.status_line)).throw
        if $response.status_line.substr(0, 1) eq '4';

    X::HTTP::Server.new(:rc($response.status_line)).throw
        if $response.status_line.substr(0, 1) eq '5';

    return $response;
}

# :simple
sub get(Str $url) is export(:simple) {
    my $ua = HTTP::UserAgent.new;
    my $response = $ua.get($url);

    return $response.content;
}

sub head(Str $url) is export(:simple) {
    my $ua = HTTP::UserAgent.new;
    return $ua.get($url).headers.headers<Content-Type Document-Length Modified-Time Expires Server>;
}

sub getprint(Str $url) is export(:simple) {
    my $response = get($url);
    say $response;
    # TODO: return response code
}