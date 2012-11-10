use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);

unless ( $ENV{'BDATUM_PATNER_KEY'} and $ENV{'BDATUM_NODE_KEY'} ) {
    plan skip_all => 'Testing this module for real costs money.';
}

use_ok('BDatum::Simple::API::Node');

my $node = BDatum::Simple::API::Node->new(
    partner_key => $ENV{'BDATUM_PATNER_KEY'},
    node_key    => $ENV{'BDATUM_NODE_KEY'}
);

my $res = $node->send(
    file => $Bin . '/../etc/frutas.txt',
    path => '/perl/'
);

is( $res->{name}, 'frutas.txt', 'name ok' );
ok( $res->{etag},    'etag ok' );
ok( $res->{version}, 'version ok' );

ok( $res->{content_type}, 'content_type ok' );

eval { $node->send( file => $Bin . '/../etc/frutas.txt' ) };
like( $@, qr|sem definir o path|, 'error is ok!' );

$node->base_path( $Bin . '/../etc' );

$res = $node->send( file => $Bin . '/../etc/frutas.txt' );
is( $res->{name}, 'frutas.txt', 'name ok' );
ok( $res->{etag},    'etag ok' );
ok( $res->{version}, 'version ok' );

ok( $res->{content_type}, 'content_type ok' );

done_testing();
