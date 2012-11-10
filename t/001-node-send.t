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

my $res = $node->send(
    file => $Bin . '/../etc/frutas.txt',
    path => '/perl/'
);

my $current_version = 0;
is( $res->{name}, 'frutas.txt', 'name ok' );
is( $res->{etag}, 'df6c5e71993e312fbfbefa7d81af1977', 'etag ok' );
ok( $current_version = $res->{version}, 'version ok' );
is( $res->{content_type}, 'text/plain', 'content_type ok' );

eval { $node->send( file => $Bin . '/../etc/frutas.txt' ) };
like( $@, qr|sem definir o path|, 'error is ok!' );

$node->base_path( $Bin . '/../etc' );

$res = $node->send( file => $Bin . '/../etc/frutas.txt' );
is( $res->{name},    'frutas.txt',                       'name ok' );
is( $res->{etag},    'df6c5e71993e312fbfbefa7d81af1977', 'etag ok' );
is( $res->{version}, $current_version + 1,               'version ok' );
is( $res->{content_type}, 'text/plain', 'content_type ok' );

done_testing();
