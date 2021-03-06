use strict;
use warnings;
use Test::More;

use JSON::XS;

use FindBin qw($Bin);
my $conf = "$Bin/../../etc/config.json";
plan skip_all => "no config found! $conf" unless -e $conf;
$conf = eval { decode_json do{local $/; open my $f, '<',$conf; <$f>} };

use_ok('BDatum::Simple::API::Auth');

my $api = BDatum::Simple::API::Auth->new(
    %$conf
);

my $res = $api->login();
is( length $res->{api_key}, 40, 'api_key looks good');
ok( $api->user_id, 'have user_id');
is( $api->api_key, $res->{api_key}, 'api key ok');


my @nodes = $api->list_nodes( as_object => 1 );

is(ref $nodes[0], 'BDatum::Simple::API::Node', 'as_object worked!');

my $nodes_ref = $api->list_nodes;

is(ref $nodes_ref->[0], 'HASH', 'hash worked too!');


done_testing();
