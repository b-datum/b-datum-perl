package BDatum::Simple::API::Auth;
use DateTime;
use utf8;
use strict;
use Moose;
use Carp;
use File::Spec;
use File::Basename;

use Furl;
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

has '_ca_file' => (
    is  => 'rw',
    isa => 'Str',
    default => sub { $ENV{HTTPS_CA_FILE} || 'etc/sf_bundle.crt' }
);

has '_ca_path' => (
    is  => 'rw',
    isa => 'Str',
    default => sub { $ENV{HTTPS_CA_DIR} || '' }
);

has furl => (
    is      => 'rw',
    lazy    => 1,
    isa     => 'Furl',
    builder => '_builder_furl'
);

sub _builder_furl {
    my ($self) = @_;

    Furl->new(
        agent   => 'b-datum-perl',
        timeout => 10000,
        ssl_opts => {
            SSL_ca_file => $self->_ca_file,
            SSL_ca_path => $self->_ca_path
        },
    );
}

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


sub _http_req {
    my ( $self, %args ) = @_;

    my $method = lc $args{method};
    my $res;

    if ( $method =~ /^(get|head)/o ) {
        $res = $self->furl->$1( $args{url}, $args{headers} );
    }
    elsif ( $method =~ /^post/o ) {
        $res = $self->furl->post( $args{url}, $args{headers}, $args{body} );
    }
    elsif ( $method =~ /^put/o ) {

        $res = $self->furl->put( $args{url}, $args{headers}, $args{body} );

    }
    elsif ( $method =~ /^delete/o ) {
        $res = $self->furl->delete( $args{url}, $args{headers} );
    }
    else {
        Carp::confess "not supported method";
    }

    return {
        content => $res->content,
        headers => { $res->headers->flatten },
        status  => $res->status
    };
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
        partner_key => 'XXXXXXXXXXXX',
        node_key    => 'YYYYYYYYYYYY'
    );

    $node->send(
        file => $Bin . '/../etc/frutas.txt',
        path => '/'
    );

    $node->download(
        key => 'some_file.txt'
    );

    $node->info(
        key => 'some_file.txt'
    );

    $node->delete(
        key => 'some_file.txt'
    );

    $node->list(
        path => '/path/to/somewhere'
    );

=head1 DESCRIPTION

Este modulo foi criado para utilizar a interface REST da b-datum para envio e resgate de backups.

Exemplos e casos de uso em <http://docs.b-datum.com/>

=head1 AUTHOR

Renato Cron <renato@aware.com.br>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Aware TI <http://www.aware.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

