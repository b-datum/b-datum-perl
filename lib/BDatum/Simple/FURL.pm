package BDatum::Simple::FURL;
use DateTime;
use utf8;
use strict;
use Moose;
use Carp;

use Furl;


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

1;

__END__

=pod

=encoding utf-8

=head1 NAME

BDatum::Simple::FURL

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    use BDatum::Simple::FURL;

    my $furl = BDatum::Simple::FURL->new();

    $furl->_http_req(
        method => 'get',
        url    => 'http://dom.zo/foo'
    )


=head1 DESCRIPTION

    uses furl with SSL files

=head1 AUTHOR

Renato Cron <renato@aware.com.br>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Aware TI <http://www.aware.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

