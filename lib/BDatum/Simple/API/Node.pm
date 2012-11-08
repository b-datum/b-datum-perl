package BDatum::Simple::API::Node;
use utf8;
use strict;
use Moose;
use Carp;
use File::Spec;
use File::Basename;
use MIME::Base64;
use File::MimeInfo::Magic;

use Furl;

use JSON::XS;
use Encode qw(encode);

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


has 'base_path' => (
    is => 'rw',
    isa => 'Str',
);


has furl => (
    is => 'rw',
    lazy => 1,
    isa => 'Furl',
    default => sub {
        return Furl->new(
            agent => 'B-Datum partner',
            timeout => 10000
        );
    },
);



sub send {
    my ($self, %params) = @_;

    croak "$params{file} precisa existir" unless -e $params{file};

    my $key;
    if (!defined $params{path}){
        croak "Você esta tentando enviar o arquivo sem definir o path" unless (defined $self->base_path);

        $key = File::Spec->abs2rel( $params{file}, $self->base_path ) ;
        croak "Você está enviando o arquivo no caminho correto? $key nao parece ser valido." if $key =~ /\.\./;
    }else{
        $key = File::Spec->catfile(
                File::Spec->canonpath($params{path}),
                basename($params{file})
        );
    }

    $key =~ s/^\\/\//g; # troca barra de windows por barras de linux
    $key =~ s/\/+/\//g; # troca varias barras por uma
    $key =~ s/^\///; # tira barras do começo

    open(my $fh, '<:raw', $params{file});

    my $res = $self->_http_req(
        method  => 'PUT',
        url     => 'https://api.b-datum.com/storage/' . $key,
        headers => [$self->_get_headers, 'content-type' => mimetype($params{file})],
        body    => $fh
    );

    close $fh;

    return {
        error => "$res->{status} não esperado!",
        res => $res
    } if $res->{status} != 200 && $res->{status} != 204;
    return $res if exists $res->{error};

    if ($res->{status} == 204){
        return $self->info(key => $key);
    }

    return {
        name         => $res->{headers}{'content-disposition'},
        content_type => $res->{headers}{'content-type'},
        size         => $res->{headers}{'content-length'},
        version      => $res->{headers}{'x-meta-b-datum-version'},
        etag         => $res->{headers}{'etag'},
        headers      => $res->{headers}
    };
}

sub download {

}

sub delete {

}

sub list {
    my ($self, %params) = @_;

  #  my $ret  = eval{decode_json $test};
  #  return { error => "$test $@", status_code => $res->status } if $@;

}

sub info {
    my ($self, %params) = @_;

    my $key = $params{key};

    $key =~ s/^\\/\//g; # troca barra de windows por barras de linux
    $key =~ s/\/+/\//g; # troca varias barras por uma
    $key =~ s/^\///; # tira barras do começo

    my $res = $self->_http_req(
        method  => 'HEAD',
        url     => 'https://api.b-datum.com/storage/' . $key,
        headers => [$self->_get_headers]
    );

    return { error => "404" } if $res->{status} == 404;
    return $res if exists $res->{error};

    return {
        name         => $res->{headers}{'content-disposition'},
        content_type => $res->{headers}{'content-type'},
        size         => $res->{headers}{'content-length'},
        version      => $res->{headers}{'x-meta-b-datum-version'},
        etag         => $res->{headers}{'etag'},
        headers      => $res->{headers}
    };
}

sub _get_headers {
    my ($self) = @_;
    return ('Authorization', 'Basic ' . $self->_get_token . '==');
}

sub _get_token {
    my ($self) = @_;
    return MIME::Base64::encode_base64url( $self->node_key . ':' . $self->partner_key );
}

=pod

    funcoes ~feias~ vão para o final do codigo

=cut
sub _http_req {
    my ( $self, %args ) = @_;

    my $method = lc $args{method};
    my $res;

    if ($method =~ /^get/o){
        $res = $self->furl->get(
            $args{url},
            $args{headers}
        );
    }elsif ($method =~ /^head/o){
        $res = $self->furl->get(
            $args{url},
            $args{headers}
        );
    }elsif ($method =~ /^post/o){
        $res = $self->furl->post(
            $args{url},
            $args{headers},
            $args{body}
        );
    }elsif ($method =~ /^put/o){

        $res = $self->furl->put(
            $args{url},
            $args{headers},
            $args{body}
        );

    }elsif ($method =~ /^delete/o){
        $res = $self->furl->delete(
            $args{url},
            $args{headers}
        );
    }else{
        Carp::confess "not supported method";
    }

    return {
        content => $res->content,
        headers => {$res->headers->flatten},
        status  => $res->status
    };
}

1;
