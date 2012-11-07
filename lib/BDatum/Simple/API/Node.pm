package BDatum::Simple::API::Node;
use utf8;
use Moose;
use Carp;
use File::Spec;
use File::Basename;
use MIME::Base64;

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
        headers => [$self->_get_headers],
        body    => $fh
    );

    use DDP; p $res;
}

sub download {

}

sub delete {

}

sub list {

}

sub info {

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
            $args{body},

        );
    }elsif ($method =~ /^delete/o){
        $res = $self->furl->delete(
            $args{url},
            $args{headers}
        );
    }else{
        die('not supported method');
    }

    my $test = $res->content;

    my $ret  = eval{decode_json $test};

    return { error => "$test $@", status_code => $res->status } if $@;

    return $ret;
}

1;
