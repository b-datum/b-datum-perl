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

my $res = $node->info( key => '/xx/origem.txt' );

like( $res->{name}, qr/origem\.txt/, 'header: name' );
is( $res->{etag}, 'df6c5e71993e312fbfbefa7d81af1977', 'header: tag' );
is( $res->{size}, '43',                               'header: size' );
is( $res->{content_type}, 'text/plain', 'header: content_type' );

is( $res->{version}, 1, 'header: version');

my $resb = $node->info( key => '/xx/origem.txt', version => 1);

is_deeply($res, $resb, 'chamda sem versao eh identica a versao 1 [no teste, isso eh correto]');


$res = $node->info( key => '/frutas404.txt' );
like( $res->{error}, qr/not found/i, '404 erro' );

$res = $node->info( key => '/xx/origem.txt', version => 2);
like( $res->{error}, qr/not found/i, '404 erro para versao nao existente' );



SKIP: {
    skip 'esta listando o contedo da pasta quando envia um HEAD em diretorio, isso eh ok?', 1;
    $res = $node->info( key => '/' );
    is( $res->{error}, 404, '404 erro' );
};

done_testing();
