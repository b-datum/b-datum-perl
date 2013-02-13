package BDatum::Simple::API::Node;
use DateTime;
use utf8;
use strict;
use Moose;
use Carp;
use File::Spec;
use File::Basename;
use MIME::Base64;
use File::MimeInfo::Magic;
use Digest::MD5;
use Furl;
use JSON::XS;
use Encode qw(encode);

has [ 'partner_key', 'node_key' ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'base_url' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://api.b-datum.com/storage',
);

has 'base_path' => (
    is  => 'rw',
    isa => 'Str',
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


has 'info_overhead' => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 200 }    # 200 bytes
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

sub send {
    my ( $self, %params ) = @_;

    croak "$params{file} must exist and have more than zero byte" unless -e $params{file};

    my $key;
    if ( !defined $params{path} ) {
        croak "You're trying to send the file without defining the path"
          unless ( defined $self->base_path );

        $key = File::Spec->abs2rel( $params{file}, $self->base_path );
        croak
"You are sending the file to the correct path? $key does not seem to be valid."
          if $key =~ /\.\./;
    }
    else {
        $key = File::Spec->catfile( File::Spec->canonpath( $params{path} ),
            basename( $params{file} ) );
    }

    $key = $self->_normalize_key($key);
    open( my $fh, '<:raw', $params{file} );
    my $md5 = Digest::MD5->new->addfile(*$fh)->hexdigest;
    seek( $fh, 0, 0 );

    # antes depois de XX bytes, nao precisa verificar o head..
    # mais eficiente enviar do que baixar head [http overhead] + enviar
    if ( -s $params{file} > $self->info_overhead ) {
        my $info = $self->info( key => $key );

        $info->{path} = $key;
        # nao precisa enviar o arquivo
        return $info if ( exists $info->{etag} && $info->{etag} eq $md5 );
    }

    my $res = $self->_http_req(
        method  => 'PUT',
        url     => $self->base_url . '?path='.$key,
        headers => [
            $self->_get_headers,
            'content-type' => mimetype( $params{file} ),
            'etag'         => $md5
        ],
        body => $fh
    );
    close $fh;

    if ( $res->{status} != 201 && $res->{status} != 204 ) {
        return $self->_return_error({
            error =>
                "$res->{status} ins't expected code (201 or 204)! " .
                    exists $res->{headers}{'x-b-datum-error'}
                    ? $res->{headers}{'x-b-datum-error'}
                    : 'no more information.',
            res   => $res
        });
    }

    if ( $res->{status} == 204 ) {
        return $self->info( key => $key );
    }

    return $self->_make_return_by_response($res, $key);
}

sub download {
    my ( $self, %params ) = @_;

    my $key = $self->_normalize_key( $params{key} );
    return $self->_return_error({ error => "404" }) unless $key;

    croak "$key looks like a path! remove / in the end to continue." if $key =~ /\/$/;

    my $path_key = "?path=$key";

    my $version = exists $params{version} && $params{version} =~ /^\d+$/
        ? '&version=' . $params{version}
        : '';

    my $res = $self->_http_req(
        method  => 'GET',
        url     => join( '/', $self->base_url, $path_key . $version ),
        headers => [ $self->_get_headers ]
    );


    if ( exists $res->{headers}{'x-b-datum-error'} ) {
        return $self->_return_error({
            error => $res->{headers}{'x-b-datum-error'},
            res => $res
        });
    }

    if ( $res->{status} == 404 ) {
        return $self->_return_error({ error => "404", res => $res });
    } elsif ( $res->{status} != 200 ) {
        return $self->_return_error({
            error => "Status code $res->{status} is not the expected code (200 OK)",
            res   => $res
        });
    }

    if ( $params{file} ) {
        open( my $fh, '>:raw', $params{file} )
          or croak "Cannot open file $params{file} $!";
        print $fh $res->{content};
        close($fh);
        delete $res->{content};
    }

    return $self->_make_return_by_response($res, $key);
}

sub list {
    my ( $self, %params ) = @_;
    my $key = $self->_normalize_key( $params{path} );

    if ($key) {
        $key = $self->_normalize_key( $key );
        # certeza que termina com barra no final, por ser list
        $key .= '/' unless $key =~ /\/$/;
    }else{
        $key = '/';
    }

    my $path_var = '?path=' . $key;

    $params{on} = exists $params{on}
        ? $params{on} =~ /^\d+$/
            ? DateTime->from_epoch( epoch => $params{on} )->datetime
            : ref $params{on} eq 'DateTime'
                ? $params{on}->datetime
                : $params{on}
        : '';
    $path_var .= '&ts=' . $params{on} if $params{on};

    my $res = $self->_http_req(
        method  => 'GET',
        url     => join( '', $self->base_url, $path_var ),
        headers => [ $self->_get_headers ]
    );

    if ($res->{status} == 404) {
        return { error => "404", res => $res };
    }
    elsif (exists $res->{error}) {
        return $res;
    }

    my $obj = eval { decode_json $res->{content} };
    return { error => "$@", res => $res } if $@;
    return $obj;
}

sub delete {
    my ( $self, %params ) = @_;
    return $self->_process_method ('DELETE', [204,410], '', \%params);
}

sub info {
    my ( $self, %params ) = @_;
    return $self->_process_method ('HEAD', 200, '', \%params );
}

sub _process_method {
    my ( $self, $method, $expect_code, $extra_url, $params ) = @_;
    my $x=$params->{key};
    my $key = $self->_normalize_key( $params->{key} );

    my $version = exists $params->{version} && $params->{version} =~ /^\d+$/
        ? '&version=' . $params->{version}
        : '';

    return { error => "404" } unless $key;

    my $res = $self->_http_req(
        method => $method,
        url => $self->base_url . $extra_url . '?path='.$key.$version,
        headers => [ $self->_get_headers ]
    );

    if ( exists $res->{headers}{'x-b-datum-error'} ) {
        return $self->_return_error({
            error => $res->{headers}{'x-b-datum-error'},
            res => $res
        });
    }

    $expect_code = $expect_code
        ? ref $expect_code eq 'ARRAY'
            ? join (',', @$expect_code)
            : $expect_code
        : '';
    if ($res->{status} == 404) {
        return $self->_return_error({
            error => "$key Not Found",
            res   => $res
        });
    } elsif ( $expect_code and $expect_code !~ /$res->{status}/) {
        return $self->_return_error({
            error => "Status code $res->{status} não é o esperado, $expect_code!",
            res => $res
        });
    }


    return $self->_make_return_by_response($res, $key);
}


sub _return_error {
    my ( $self, $res ) = @_;

    die($res->{error}) if exists $res->{error} && $self->raise_error;

    return $res;
}

sub _make_return_by_response {
    my ( $self, $res, $path ) = @_;

    die($res->{headers}{'x-b-datum-error'})
        if exists $res->{headers}{'x-b-datum-error'} && $self->raise_error;

    return {
        name         => $res->{headers}{'content-disposition'},
        content_type => $res->{headers}{'content-type'},
        version      => $res->{headers}{'x-meta-b-datum-version'},
        etag         => $res->{headers}{'etag'},

        (
            exists $res->{headers}{'content-length'}
            ? ( size => $res->{headers}{'content-length'} )
            : ()
        ),
        (
            exists $res->{headers}{'x-b-datum-size'}
            ? ( size => $res->{headers}{'x-b-datum-size'} )
            : ()
        ),
        (
            exists $res->{headers}{'x-meta-b-datum-delete'}
            ? ( deleted => $res->{headers}{'x-meta-b-datum-delete'} )
            : ()
        ),
        ( exists $res->{content} ? ( content => $res->{content} ) : () ),

        (
            exists $res->{headers}{'x-b-datum-error'}
             ? ( error => $res->{headers}{'x-b-datum-error'} )
             : ()
        ),
        ( $path ? ( path => $path ) : () ),

        # TODO: why ?
        # headers => $res->{headers}
    };
}

sub _normalize_key {
    my ( $self, $key ) = @_;
    return '' unless $key;
    $key =~ s/\\/\//g;     # invertendo barras padrão do SO Windows.
    $key =~ s/\/+/\//g;    # troca varias barras por uma
    $key =~ s/^\///;       # tira barras do começo

    $key = "/$key";
    return $self->_validate_key($key);
}

sub _validate_key () {
    my ( $self, $key ) = @_;
    croak 'The key must be ^[A-Za-z0-9.-_/]*$ --' . $key
      unless $key =~ /^[A-Za-z0-9\/\.\-_]*$/;
    croak 'The length of key cannot be > 980'
      if length($key) > 980;
    return $key;
}

sub _get_headers {
    my ($self) = @_;
    return ( 'Authorization', 'Basic ' . $self->_get_token . '==' );
}

sub _get_token {
    my ($self) = @_;
    return MIME::Base64::encode_base64url(
        $self->node_key . ':' . $self->partner_key );
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

