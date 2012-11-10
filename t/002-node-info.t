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

my $res = $node->info( key => '/frutas.txt' );

is( $res->{name}, 'frutas.txt',                       'header: name' );
is( $res->{etag}, 'd41d8cd98f00b204e9800998ecf8427e', 'header: tag' );
is( $res->{size}, '3885',                             'header: size' );
is( $res->{content_type}, 'text/html; charset=utf-8', 'header: content_type' );

ok( $res->{version}, 'header: version' );

$res = $node->info( key => '/frutas404.txt' );
is( $res->{error}, 404, '404 erro' );

$res = $node->info( key => '/' );
is( $res->{error}, 404, '404 erro' );

done_testing();
