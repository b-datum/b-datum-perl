package BDatum::Simple::API::Node;

use Moose;


has 'partner_key' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has 'node_key' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

sub send {

}

sub download {

}

sub delete {

}

sub list {

}

sub info {

}


1;
