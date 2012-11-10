use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);

unless ( $ENV{'BDATUM_PARTNER_KEY'} and $ENV{'BDATUM_NODE_KEY'} ) {
    plan skip_all => 'Testing this module for real costs money.';
}

use_ok('BDatum::Simple::API::Node');

my $node = BDatum::Simple::API::Node->new(
    partner_key => $ENV{'BDATUM_PARTNER_KEY'},
    node_key    => $ENV{'BDATUM_NODE_KEY'}
);

my $res = $node->list();

ok( $res->{objects}, 'tem objetos' );
is( $res->{objects}{'frutas.txt'}{type}, 'file', 'frutas.txt presente' );

$res = $node->list( path => '/perl' );

ok( $res->{objects}, 'tem objetos' );
is( $res->{objects}{'frutas.txt'}{type}, 'file', 'frutas.txt presente' );

done_testing();
