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

my $res = $node->delete( key => 'frutas.txt' );

is( $res->{name}, 'frutas.txt', 'name ok' );
ok( $res->{etag}, 'etag ok' );
is( $res->{deleted}, 1, 'deleted ok' );
ok( $res->{version},      'version ok' );
ok( $res->{content_type}, 'content_type ok' );

done_testing();
