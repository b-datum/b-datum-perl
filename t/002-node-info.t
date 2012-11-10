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
is( $res->{etag}, 'df6c5e71993e312fbfbefa7d81af1977', 'header: tag' );
is( $res->{size}, '43',                               'header: size' );
is( $res->{content_type}, 'text/plain', 'header: content_type' );

ok( $res->{version}, 'header: version' );

$res = $node->info( key => '/frutas404.txt' );
is( $res->{error}, 404, '404 erro' );

$res = $node->info( key => '/' );
is( $res->{error}, 404, '404 erro' );

done_testing();
