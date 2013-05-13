use strict;
use warnings;
use Test::More;
use File::Copy;
use File::Basename;
use File::Temp qw/ tempfile tempdir /;


use FindBin qw($Bin);

unless ( $ENV{'BDATUM_PARTNER_KEY'} and $ENV{'BDATUM_NODE_KEY'} ) {
    plan skip_all => 'Testing this module for real costs money.';
}
use_ok('BDatum::Simple::API::Node');

my $node = BDatum::Simple::API::Node->new(
    partner_key => $ENV{'BDATUM_PARTNER_KEY'},
    node_key    => $ENV{'BDATUM_NODE_KEY'}
);

my (undef, $filename) = tempfile(SUFFIX => '.txt');
do { open my $f, '>', '/tmp/current.name'; print $f $filename;};
copy($Bin . '/../etc/origem.txt', $filename);

my $basename = basename $filename;

my $res = $node->send(
    file => $filename,
    path => '/xx/'
);

is( $res->{path}, '/xx/' . $basename, 'sent to correct path');
is( $res->{etag}, 'df6c5e71993e312fbfbefa7d81af1977', 'etag ok' );
ok( $res->{version}, 'version ok' );
is( $res->{content_type}, 'text/plain; charset=UTF-8', 'content_type ok' );

eval { $node->send( file => $filename ) };
like( $@, qr|You're trying to send the file without defining the path|, 'error when sending without path' );

$node->base_path( dirname($filename) );

$res = $node->send( file => $filename );

is( $res->{path}, '/' . $basename, 'sent to correct path');

is( $res->{etag}, 'df6c5e71993e312fbfbefa7d81af1977', 'etag ok' );
ok( $res->{version}, 'version ok' );
is( $res->{content_type}, 'text/plain; charset=UTF-8', 'content_type ok' );

done_testing();
