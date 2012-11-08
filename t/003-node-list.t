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

my $res = $node->list();

ok($res->{objects}, 'tem objetos');
is($res->{objects}{'frutas.txt'}{type}, 'file', 'frutas.txt presente');

$res = $node->list( path => '/perl');

ok($res->{objects}, 'tem objetos');
is($res->{objects}{'frutas.txt'}{type}, 'file', 'frutas.txt presente');

done_testing();
