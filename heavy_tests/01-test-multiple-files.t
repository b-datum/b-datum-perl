use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);

unless ( $ENV{'BDATUM_PARTNER_KEY'} and $ENV{'BDATUM_NODE_KEY'} ) {
    plan skip_all => 'Testing this module for real costs money.';
}

use_ok('BDatum::Simple::API::Storage');

my $node = BDatum::Simple::API::Storage->new(
    partner_key => $ENV{'BDATUM_PARTNER_KEY'},
    node_key    => $ENV{'BDATUM_NODE_KEY'}
);

use String::Random;

my $foo = String::Random->new;
$foo->{'A'} = [ 'A'..'Z', 'a'..'z', '0' .. '9' ];

my $contents;

sub write_random {
    my ($file, $size) = @_;

    my $content = do{$foo->randpattern("A" x $size)};
    open(my $x, '>:raw', '/tmp/'.$file);
    print $x $content;
    close $x;

    push @{$contents->{$file}}, $content;
    return '/tmp/' . $file
}
my $path = '/rand/' . $foo->randpattern("AAAAA");
diag "enviando arquivo novo para $path...";

my $res = $node->send(
    file => write_random('x', 200),
    path => $path
);

is( $res->{path}, $path . '/x', 'sent to correct path');
is( $res->{version}, 1, 'version ok' );
diag "enviando modificado...";

$res = $node->send(
    file => write_random('x', 20),
    path => $path
);

is( $res->{path}, $path . '/x', 'sent to correct path');
is( $res->{version}, 2, 'version ok' );

diag "enviando igual";
$res = $node->send(
    file => '/tmp/x',
    path => $path
);
is( $res->{path}, $path . '/x', 'sent to correct path');
is( $res->{version}, 2, 'version ok' );


diag "enviando varios no mesmo diretorio";

for (1..3){

    $res = $node->send(
        file => write_random('foo'.$_, 1),
        path => $path
    );
    is( $res->{path}, $path . '/foo'.$_, 'sent to correct path');
    is( $res->{version}, 1, 'version ok' );

}
diag "apagando um arquivo e pegando as informacoes";
$node->delete( key => $path . '/foo1' );
is($res->{size}, 0, '0 size');

my $files = $node->list( path => $path );
foreach my $d (@{$files->{objects}}){

    if ($d->{path} =~ qr|/x$|){
        is($d->{size}, 20, 'tamanho do x ok');
        is($d->{version}, 2, 'versao do x ok');
    }elsif ($d->{path} =~ qr|/foo[32]$|){
        is($d->{size}, 1, 'tamanho do foo ok');
        is($d->{version}, 1, 'versao do foo ok');
    }else{
        fail "arquivo ".$d->{path}. " a mais no diretorio \n";
    }
}

diag "baixando arquivos e vendo se estao iguais aos enviados\n";

my $ret = $node->download(
    key     => $path . '/x'
);
is($ret->{content}, $contents->{x}[1], 'sem versao = ultima versao');

$ret = $node->download(
    key     => $path . '/x',
    version => 1
);
is($ret->{content}, $contents->{x}[0], 'v1 = versao 1');

$ret = $node->download(
    key     => $path . '/x',
    version => 2
);
is($ret->{content}, $contents->{x}[1], 'v2 = versao 2');


diag "enviando arquivo de 1MB";
$res = $node->send(
    file => write_random('1mb', 131072),
    path => $path
);

$ret = $node->download(
    key     => $path . '/1mb'
);
is($ret->{content}, $contents->{'1mb'}[0], '1mb sem corromper');



done_testing();

