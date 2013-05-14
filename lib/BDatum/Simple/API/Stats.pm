package BDatum::Simple::API::Stats;
use DateTime;
use utf8;
use strict;
use Moose;
extends 'BDatum::Simple::FURL';
use BDatum::Simple::API::Auth;

use Carp;
use File::Spec;
use URI;
use URI::QueryParam;
use File::Basename;


use JSON::XS;
use Encode qw(encode);

has [ 'email', 'password' ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 0
);

has 'days' => (
    is       => 'rw',
    isa      => 'Int',
    required => 0,
    default  => sub{ 10 }
);


has 'auth' => (
    is      => 'rw',
    isa     => 'BDatum::Simple::API::Auth',
    required => 0,
);

has 'raise_error' => (
    is  => 'rw',
    isa => 'Bool',
    default => '0',
);

sub BUILD {
    my $self = shift;

    die 'auth attribute is required unless your pass email and password'
        if ( !$self->auth && (!$self->email || !$self->password));

    if ( !$self->auth ) {
        $self->auth(BDatum::Simple::API::Auth->new(
            email       => $self->email,
            password    => $self->password,
            raise_error => $self->raise_error
        ));
    }

    if(!$self->auth->api_key){
        my $obj = $self->auth->login;
        die($obj->{error}) if $obj->{error};
    }
}

# this is stats
sub stats {
    my ( $self ) = @_;

    my $res = $self->_http_req(
        method  => 'GET',
        url     => $self->_uri_for(
            ['user', $self->auth->user_id, 'stats'],
            {
                'days' => $self->days
            }
        )
    );

    return $self->_parse_response($res);
}

sub node_stats {
    my ( $self, $node_id ) = @_;

    my $res = $self->_http_req(
        method  => 'GET',
        url     => $self->_uri_for(
            ['node', $node_id, 'stats'],
            {
                'days' => $self->days
            }
        )
    );

    return $self->_parse_response($res);
}

sub organization_stats {
    my ( $self, $node_id ) = @_;

    return $self->_return_error( error => 'no organization_id found!' )
        unless $self->auth->organization_id;

    my $res = $self->_http_req(
        method  => 'GET',
        url     => $self->_uri_for(
            ['organization', $self->auth->organization_id, 'stats'],
            {
                'days' => $self->days
            }
        )
    );

    return $self->_parse_response($res);
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

BDatum::Simple::API::Stats

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    use BDatum::Simple::API::Stats;

    my $stats_api = BDatum::Simple::API::Stats->new(
        email    => 'your@email.com',
        password => 'foopass',

        # OR
        # auth => (obj of BDatum::Simple::API::Auth),

        days => 10,

    );

    my $stats = $stats_api->stats();
    # hash that contains:
        {
            "stored_data": "22927301306",
            "file_count": "321662",
            "frequent_files": [
                {
                    "count": "214934",
                    "name": "bin, exe, ani"
                },...
            ],
            "download_stats": [
                {
                    "timesample": "1367877600",
                    "value": "154004950"
                },...
            ],
            "file_count_history": [
                {
                    "timesample": "1363618800",
                    "sample_count": "17"
                },...
            ],
            "nodes_count": "33",
            "avg_file_size": [
                {
                    "timesample": "1367668800",
                    "value": 258919
                },...
            ],
            "upload_stats": [
                {
                    "timesample": "1367668800",
                    "value": "22525941"
                },....
            ]
        }


    you may also

    $stats_api->organization_stats

    or

    $stats_api->node_stats( $node_id )

=head1 DESCRIPTION

    Get stats about a b-datum user

=head1 AUTHOR

Renato Cron <renato@aware.com.br>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Aware TI <http://www.aware.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

