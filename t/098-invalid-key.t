
use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);

use_ok('BDatum::Simple::API::Storage');

my $node = BDatum::Simple::API::Storage->new(
    partner_key => 123,
    node_key    => 2345,
);

is($node->_normalize_key('1234'), '/1234', 'start with /');
is($node->_normalize_key('abc///////def'), '/abc/def', 'duas barras //+ viram uma barra /');
is($node->_normalize_key('abc\def'), '/abc/def', 'barras \ viram /');
eval { ok($node->_normalize_key('x' x 1000)) };
like ( $@, qr|length|, 'key length > 980 = error');

done_testing();
