my $app = sub {
    return [
        "200",
        [ "Content-Type" => "text/plain" ],
        [ "Hello, Perl on Unit!" ],
    ];
};
