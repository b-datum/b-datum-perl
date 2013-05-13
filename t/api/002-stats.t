use strict;
use warnings;
use Test::More;

use JSON::XS;

use FindBin qw($Bin);
my $conf = "$Bin/../../etc/config.json";
plan skip_all => "no config found! $conf" unless -e $conf;
$conf = eval { decode_json do{local $/; open my $f, '<',$conf; <$f>} };

use_ok('BDatum::Simple::API::Stats');

my $api = eval{BDatum::Simple::API::Stats->new()};
ok($@, 'error without params');


$api = eval{BDatum::Simple::API::Stats->new(email => 'fo', password=>'foo')};
ok($@, 'error with wrong login');

$api = BDatum::Simple::API::Stats->new(
    %$conf,

    days => 1
);


my $stats = $api->stats;

is(ref $stats->{upload_stats}, 'ARRAY', 'has upload_stats');
is(ref $stats->{frequent_files}, 'ARRAY', 'has frequent_files');
is(ref $stats->{file_count_history}, 'ARRAY', 'has file_count_history');
is(ref $stats->{download_stats}, 'ARRAY', 'has download_stats');
is(ref $stats->{avg_file_size}, 'ARRAY', 'has avg_file_size');

done_testing();
