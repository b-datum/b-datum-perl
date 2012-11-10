
use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);

use_ok('BDatum::Simple::API::Node');

my $node = BDatum::Simple::API::Node->new(
    partner_key => 123,
    node_key    => 2345,
);

is($node->_normalize_key('1234'), '1234');
is($node->_normalize_key('abc///////def'), 'abc/def', '//+ -> /');
is($node->_normalize_key('abc\def'), 'abc/def', '\ -> /');
eval { ok($node->_normalize_key('x' x 1000)) };
like ( $@, qr|length|, 'key length > 980');

done_testing();
