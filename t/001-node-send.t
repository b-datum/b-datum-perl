use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);

BEGIN {
    use_ok('BDatum::Simple::API::Node');
}

my $node = BDatum::Simple::API::Node->new(
    partner_key => 'ys9hzza605zZVKNJvdiB',
    node_key    => 'ALThcI8EWJOPHeoP01mz'
);

my $res = $node->send(
    file => $Bin . '/../etc/frutas.txt',
    path => '/'
);
is($res->{name}, 'frutas.txt', 'name ok');
ok($res->{etag}, 'etag ok');
ok($res->{version}, 'version ok');
ok($res->{size}, 'size ok');

eval{$node->send(
    file => $Bin . '/../etc/frutas.txt'
)};
like($@, qr|sem definir o path|, 'error is ok!');

$node->base_path($Bin . '/../etc');

my $res = $node->send(
    file => $Bin . '/../etc/frutas.txt'
);
is($res->{name}, 'frutas.txt', 'name ok');
ok($res->{etag}, 'etag ok');
ok($res->{version}, 'version ok');
ok($res->{size}, 'size ok');


done_testing();
