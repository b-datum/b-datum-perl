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

my $res = $node->delete( key => '/xx/origem.txt' );
is($res->{size}, undef, 'undef size');

$res = $node->delete( key => '/xx/origem.txt' );
is($res->{size}, 0, '0 size');

$res = $node->info( key => '/xx/origem.txt');
like($res->{error}, qr/Not Found/i, 'not found file');

done_testing();
