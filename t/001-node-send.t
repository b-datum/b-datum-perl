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
    file => $Bin . '/../etc/origem.txt',
    path => '/xx/'
);
is( $res->{path}, '/xx/origem.txt', 'sent to correct path');
is( $res->{etag}, 'df6c5e71993e312fbfbefa7d81af1977', 'etag ok' );
ok( $res->{version}, 'version ok' );
is( $res->{content_type}, 'text/plain', 'content_type ok' );

eval { $node->send( file => $Bin . '/../etc/origem.txt' ) };
like( $@, qr|You're trying to send the file without defining the path|, 'error when sending without path' );

$node->base_path( $Bin . '/../etc' );

$res = $node->send( file => $Bin . '/../etc/origem.txt' );

is( $res->{path}, '/origem.txt', 'sent to correct path');

is( $res->{etag}, 'df6c5e71993e312fbfbefa7d81af1977', 'etag ok' );
ok( $res->{version}, 'version ok' );
is( $res->{content_type}, 'text/plain', 'content_type ok' );

done_testing();
