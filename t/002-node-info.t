use strict;
use warnings;
use Test::More;
use File::Basename;
my $filename = do { local $/; open my $f, '<', '/tmp/current.name'; <$f>};
my $basename = basename $filename;

use FindBin qw($Bin);

unless ( $ENV{'BDATUM_PARTNER_KEY'} and $ENV{'BDATUM_NODE_KEY'} ) {
    plan skip_all => 'Testing this module for real costs money.';
}

use_ok('BDatum::Simple::API::Storage');
diag("waiting the queue process");
sleep 1;

my $node = BDatum::Simple::API::Storage->new(
    partner_key => $ENV{'BDATUM_PARTNER_KEY'},
    node_key    => $ENV{'BDATUM_NODE_KEY'}
);



my $res = $node->info( key => '/xx/' . $basename );

#like( $res->{name}, qr/origem\.txt/, 'header: name' );
is( $res->{etag}, 'df6c5e71993e312fbfbefa7d81af1977', 'header: tag' );

is( $res->{size}, '43',                               'header: size' );

is( $res->{content_type}, 'text/plain; charset=UTF-8', 'header: content_type' );

is( $res->{version}, 1, 'header: version');

my $resb = $node->info( key => '/xx/' . $basename, version => 1);

is_deeply($res, $resb, 'chamda sem versao eh identica a versao 1 [no teste, isso eh correto]');


$res = $node->info( key => '/frutas404.txt' );
like( $res->{error}, qr/not found/i, '404 erro' );

$res = $node->info( key => '/xx/' . $basename, version => 2);
like( $res->{error}, qr/not found/i, '404 erro para versao nao existente' );


done_testing();
