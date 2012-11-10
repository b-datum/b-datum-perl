use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);

BEGIN {
    use_ok('BDatum::Simple::API::Node');
}

unless ( $ENV{'BDATUM_PATNER_KEY'} and $ENV{'BDATUM_NODE_KEY'} ) {
    plan skip_all => 'Testing this module for real costs money.';
}

my $node = BDatum::Simple::API::Node->new(
    partner_key => $ENV{'BDATUM_PATNER_KEY'},
    node_key    => $ENV{'BDATUM_NODE_KEY'}
);

my $res = $node->list();

ok( $res->{objects}, 'tem objetos' );
is( $res->{objects}{'frutas.txt'}{type}, 'file', 'frutas.txt presente' );

$res = $node->list( path => '/perl' );

ok( $res->{objects}, 'tem objetos' );
is( $res->{objects}{'frutas.txt'}{type}, 'file', 'frutas.txt presente' );

done_testing();
