package BDatum::Simple::API::Node;
use DateTime;
use utf8;
use strict;
use Moose;
use BDatum::Simple::API::Stats;
use BDatum::Simple::API::Auth;
use Carp;
use File::Spec;
use File::Basename;

extends 'BDatum::Simple::FURL';

use JSON::XS;
use Encode qw(encode);

has 'id' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

has [qw/key name operating_system status/] => (
    is       => 'rw',
    isa      => 'Maybe[Str]',
    required => 0
);

# TODO ? user / organization

has 'raise_error' => (
    is  => 'rw',
    isa => 'Bool',
    default => '0',
);


has auth => (
    is       => 'rw',
    isa      => 'BDatum::Simple::API::Auth',
    required => 1,
    weak_ref => 1
);

has _stats => (
    is       => 'rw',
    isa      => 'BDatum::Simple::API::Stats',
    lazy     => 1,
    builder => '_builder_stats'
);


sub _builder_stats {
    my ($self) = @_;

    BDatum::Simple::API::Stats->new(
        raise_error  => $self->raise_error,
        auth         => $self->auth
    );
}


sub stats {
    my ( $self ) = @_;

    return $self->_stats->node_stats($self->id);
}

sub refresh {
    my ( $self ) = @_;

    my $res = $self->_http_req(
        method  => 'GET',
        url     => $self->_uri_for(['node', $self->id])
    );
    if ( $res->{status} != 200 ) {
        return $self->_return_error({
            error => "$res->{status} ins't expected code 200",
            res   => $res
        });
    }

    my $obj = $self->_parse_response($res);
    return $obj if exists $obj->{error};

    $self->$_($obj->{$_}) for qw/key name operating_system status/;

    return $self;
}


sub _uri_for {
    my ( $self, $parts, $params ) = @_;

    my $url = join '/', $self->base_url, @$parts;
    $params->{api_key} = $self->auth->api_key;

    my $u = URI->new($url, "http");
    $u->query_form_hash( $params );

    return $u->as_string;
}


sub _parse_response {
    my ( $self, $res, $error_ok ) = @_;

    my $obj = eval{ decode_json $res->{content} };
    return $self->_return_error( {error => "$@", res => $res } ) if $@;

    return $self->_return_error( { res => $obj } ) if !defined $error_ok && $obj->{error};

    return $obj;
}

sub _return_error {
    my ( $self, $res ) = @_;

    my $error_msg = $res->{error};

    my $can_parse = eval{ decode_json $res->{res}{content} };
    $error_msg = $can_parse->{error} if ($can_parse && $can_parse->{error});

    die($error_msg) if $error_msg && $self->raise_error;

    return {
        error   => $error_msg,
        content => $can_parse
    };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

BDatum::Simple::API::Node

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    use BDatum::Simple::API::Node;

    my $node = BDatum::Simple::API::Node->new(
        id => 123,
        auth => (obj of BDatum::Simple::API::Auth),

        # you can pass any of these:
        # key name operating_system status
        # but it's only makes senses if you have it.
    );

    my $info = $node->stats();
    # returns samething as BDatum::Simple::API::Stats->node_status($node_id)

    # to get the server value for any of theses fields:
    # key, name, operating_system, status
    # you can call ->refresh

    # download attributes from server
    $node->refesh;

    # get the status
    $node->status;
    $node->name;


=head1 DESCRIPTION

    "node" of api.b-datum.com

=head1 AUTHOR

Renato Cron <renato@aware.com.br>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Aware TI <http://www.aware.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

