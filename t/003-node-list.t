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

use_ok('BDatum::Simple::API::Node');

my $node = BDatum::Simple::API::Node->new(
    partner_key => $ENV{'BDATUM_PARTNER_KEY'},
    node_key    => $ENV{'BDATUM_NODE_KEY'}
);

my $res = $node->list( path => '/xx' );

if (is( ref $res->{objects},'ARRAY', 'tem objetos de array' )){
    my $found = 0;
    foreach my $file (@{$res->{objects}}){
        next unless $file->{path} eq '/xx/' . $basename;
        is ($file->{size}, 43, 'size ok');
        is ($file->{version}, 1, 'version ok');
        #is ($file->{end_ts}, 'infinity', 'end_ts ok');
        $found++;
    }
    is($found, 1, 'arquivo encontrado!');
}

my @empty;
push @empty, $node->list( path => '/xx', on => 1095379199 ); # 2004
push @empty, $node->list( path => '/xx', on => '2010-01-01' );
push @empty, $node->list( path => '/xx', on => '2010-01-01 01:01:01');
push @empty, $node->list( path => '/xx', on => DateTime->new(year=>2001) );

for (1..@empty-1){
    is_deeply($empty[0], $empty[$_], 'lista vazio para datas futuras e antigas');
}


done_testing();
