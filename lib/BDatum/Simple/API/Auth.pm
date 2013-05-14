package BDatum::Simple::API::Auth;
use DateTime;
use utf8;
use strict;
use Moose;
extends 'BDatum::Simple::FURL';
use BDatum::Simple::API::Node;
use Carp;
use URI;
use URI::QueryParam;
use File::Spec;
use File::Basename;


use JSON::XS;
use Encode qw(encode);

has [ 'email', 'password' ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'base_url' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://api.b-datum.com/',
);

has ['api_key','user_id','organization_id'] => (
    is      => 'rw',
    isa     => 'Str',
    required => 0,
);


has 'raise_error' => (
    is  => 'rw',
    isa => 'Bool',
    default => '0',
);



sub login {
    my ( $self ) = @_;

    my $res = $self->_http_req(
        method  => 'POST',
        url     => $self->base_url . 'login',
        body    => {
            email    => $self->email,
            password => $self->password
        }
    );

    if ( $res->{status} != 200 ) {
        return $self->_return_error({
            error => "$res->{status} ins't expected code 200",
            res   => $res
        });
    }

    my $obj = $self->_parse_response($res);
    return $obj if exists $obj->{error};

    $self->api_key($obj->{api_key});
    $self->user_id($obj->{id});
    $self->organization_id($obj->{organization_id}) if $obj->{organization_id};

    return $obj;
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

sub list_nodes {
    my ( $self, %conf ) = @_;

    my $res = $self->_http_req(
        method  => 'GET',
        url     => $self->_uri_for(['node'])
    );
    if ( $res->{status} != 200 ) {
        return $self->_return_error({
            error => "$res->{status} ins't expected code 200",
            res   => $res
        });
    }

    my $obj = $self->_parse_response($res);
    return $obj if exists $obj->{error};

    my @nodes = @{$obj->{nodes}};
    if (exists $conf{as_object} && $conf{as_object}){

        foreach (@nodes){
            $_ = BDatum::Simple::API::Node->new(
                %$_,
                auth => $self
            );
        }
    }

    return wantarray ? @nodes : \@nodes;
}

sub _uri_for {
    my ( $self, $parts, $params ) = @_;

    my $url = join '/', $self->base_url, @$parts;
    $params->{api_key} = $self->api_key;

    my $u = URI->new($url, "http");
    $u->query_form_hash( $params );

    return $u->as_string;
}



1;

__END__

=pod

=encoding utf-8

=head1 NAME

BDatum::Simple::API::Auth

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    use BDatum::Simple::API::Auth;

    my $auth = BDatum::Simple::API::Auth->new(
        email    => 'your@email.com',
        password => 'foopass'
    );

    my $info = $auth->login();
    # that contains:
        active         :  1,
        address        :  undef,
        advanced_mode  :  0,
        api_key        :  "some api key here",
        cidr           :  "0.0.0.0/0",
        email          :  "your@email.com",
        first_login    :  1,
        id             :  8,
        name           :  "your name",
        organization_id:  undef, # only if you have
        partner_key    :  "partner_key",
        phone_number   :  undef,
        ts_created     :  "2013-01-30T19:40:22"


    # please only call this after call $auth->login()!

    # get user id
    $auth->user_id();

    # get organization id, if any
    $auth->organization_id();

    # get the api_key
    $auth->api_key();

    # return hash-ref of nodes
    @nodes = $auth->list_nodes();

    # return BDatum::Simple::API::Node objects
    @nodes = $auth->list_nodes( as_object => 1 );


=head1 DESCRIPTION

    Class for classic login on api.b-datum.com

=head1 AUTHOR

Renato Cron <renato@aware.com.br>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Aware TI <http://www.aware.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

