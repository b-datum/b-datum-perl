use strict;
use warnings;
use Test::More;
use utf8;
use File::Basename;

my $filename = do { local $/; open my $f, '<', '/tmp/current.name' or die ("cant find /tmp/current.name $!"); <$f>};
my $basename = basename $filename;


use FindBin qw($Bin);

unless ( $ENV{'BDATUM_PARTNER_KEY'} and $ENV{'BDATUM_NODE_KEY'} ) {
    plan skip_all => 'Testing this module for real costs money.';
}

use_ok('BDatum::Simple::API::Storage');

my $node = BDatum::Simple::API::Storage->new(
    partner_key => $ENV{'BDATUM_PARTNER_KEY'},
    node_key    => $ENV{'BDATUM_NODE_KEY'}
);

my $res = $node->download(
    key     => '/xx/' . $basename,
    version => 1
);

like( $res->{name}, qr/$basename/, 'name ok' );
#is( $res->{etag}, 'df6c5e71993e312fbfbefa7d81af1977', 'etag ok' );
#is( $res->{version}, 1, 'version ok' );
is( $res->{content_type}, 'text/plain; charset=UTF-8', 'content_type ok' );
my $copy = $res->{content};
like( $res->{content}, qr|banana|, 'content tem uma fruta!' );

$res = $node->download(
    key  => '/xx/'. $basename,
    file => $Bin . '/../etc/tmp_test.txt'
);

ok( !exists $res->{content},          'content vazio!' );
ok( -e $Bin . '/../etc/tmp_test.txt', 'arquivo existe!' );

my $content = do { local $/; open(my $fh, '<:raw', $Bin . '/../etc/tmp_test.txt'); <$fh>};

is($content, $copy, 'download para arquivo e conteudo sao identicos');

unlink( $Bin . '/../etc/tmp_test.txt' );

done_testing();
