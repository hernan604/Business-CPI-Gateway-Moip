package Business::CPI::Gateway::Moip;
use Moo;
use MIME::Base64;
use Carp 'croak';
use bareword::filehandles;
use indirect;
use multidimensional;
use HTTP::Tiny;
use Data::Dumper;
extends 'Business::CPI::Gateway::Base';

our $VERSION     = '0.01';

=head1 NAME

Business::CPI::Gateway::Moip - Inteface para pagamentos Moip

=head1 SYNOPSIS

use Business::CPI::Buyer::Moip;
use Business::CPI::Cart::Moip;

my $cpi = Business::CPI::Gateway::Moip->new(
    currency        => 'BRL',
    sandbox         => 1,
    token_acesso    => 'YC110LQX7UQXEMQPLYOPZ1LV9EWA8VKD',
    chave_acesso    => 'K03JZXJLOKJNX0CNL0NPGGTHTMGBFFSKNX6IUUWV',
    receiver_email  => 'teste@casajoka.com.br',
    receiver_label  => 'Casa Joka',
    id_proprio      => 'ID_INTERNO_'.int rand(int rand(99999999)),
);

my $cart = $cpi->new_cart({
    buyer => {
        name               => 'Mr. Buyer',
        email              => 'sender@andrewalker.net',
        address_street     => 'Rua Itagyba Santiago',
        address_number     => '360',
        address_district   => 'Vila Mascote',
        address_complement => 'Ap 35',
        address_city       => 'São Paulo',
        address_state      => 'SP',
        address_country    => 'BRA',
        address_zip_code   => '04363-040',
        phone              => '11-9911-0022',
        id_carteira        => 'O11O22X33X',
    }
    },{
    buyer   => Business::CPI::Buyer::Moip->new(),
    cart    => Business::CPI::Cart::Moip->new(),
});

$cart->due_date('21/12/2012');
$cart->logo_url('http://www.nixus.com.br/img/logo_nixus.png');
$cart->parcelas([
    {
        parcelas_min => 2,
        parcelas_max => 6,
        juros        => 2.99,
    },
    {
        parcelas_min => 7,
        parcelas_max => 12,
        juros        => 10.99,
    },
]);

my $item = $cart->add_item({
    id          => 2,
    quantity    => 1,
    price       => 222,
    description => 'produto2',
});

my $item = $cart->add_item({
    id          => 1,
    quantity    => 2,
    price       => 111,
    description => 'produto1',
});

my $res = $cpi->make_xml_transaction( $cart );
warn p $res;
    \{
        code    "SUCCESS",
        id      201301231157322850000001500872,
        token   "C2R0A1V3K0P132J3Q1C1S5M7R3N2P2N8B5L0Q0M0J05070U1W5K0P018D7T2"
    }

=head1 MOIP DOCUMENTATION REFERENCE

http://labs.moip.com.br
http://labs.moip.com.br/referencia/minuto/
http://labs.moip.com.br/referencia/pagamento_parcelado/

=head1 DESCRIPTION

Business::CPI::Gateway::Moip allows you to make moip transactions using Business::CPI standards.
Currently, Moip uses XML format for transactions.
This module will allow you to easily create a cart with items and buyer infos and payment infos. And, after setting up all this information, you will be able to:
    ->make_xml_transaction
and register your transaction within moip servers to obtain a moip transaction tokenid.

** make_xml_transaction will return a TOKEN and code SUCCESS upon success. You will need this info so your user can checkout afterwards.

=head1 MOIP TRANSACTION FLOW

Here, ill try to describe how the moip transaction flow works:

1. You post the paymentXML to the moip servers
2. Moip returns a transaction token id upon success

Then, you have 2 options for checkout:
- option1 (send the user to moip site to finish transaction):
- 3. You redirect your client to moip servers passing the transaction token id

- option2 (use the moip transaction id and some javascript for checkout):
- 3. You use some javascript with the transaction token id

4. Your client pays

=head1 CRUDE EXAMPLE

Ive prepared this example just in case you want to test the moip payment sistem without using any other module.
The following snippet uses only HTTP::Tiny to register the moip transaction.

    my $conteudo = <<'XML';
<EnviarInstrucao>
  <InstrucaoUnica>
        <Razao>Pagamento com HTTP Tiny</Razao>
        <Valores>
            <Valor moeda='BRL'>1.50</Valor>
        </Valores>
        <Pagador>
            <IdPagador>cliente_id</IdPagador>
        </Pagador>
  </InstrucaoUnica>
</EnviarInstrucao>
XML
    my $res = HTTP::Tiny->new( verify_SSL => $self->verify_ssl )->request(
        'POST',
        $self->api_url,
        {
            headers => {
                'Authorization' => 'Basic ' . MIME::Base64::encode($self->token_acesso.":".$self->chave_acesso,''),
                'Content-Type' => 'application/x-www-form-urlencoded',
            },
            content => $conteudo,
        }
    );
    warn p $res;

=cut


=head1 ATTRIBUTES

=head2 sandbox

Indicates whether or not this module will use the sandbox url or production url.

=cut

has sandbox => (
    is => 'rw',
    default => 0,
);

=head2 api_url

Holds the api_url. You DONT need to pass it, it will figure out its own url based on $self->sandbox

=cut

has 'api_url' => (
    is => 'rw',
);

=head2 token_acesso

Moip token

=cut

has token_acesso => (
    is => 'rw',
    required => 1,
);

=head2 chave_acesso

Moip access-key

=cut

has chave_acesso => (
    is => 'rw',
    required => 1,
);

=head2 id_proprio

Your own internal transaction id.
ie. e39jd2390jd92d030000001

=cut

has id_proprio => (
    is => 'rw',
);

=head2 receiver_label

Name that will receive this payment
ie. My Store Name

=cut

has receiver_label => ( #to print the sotre name on the paypment form
    is => 'rw',
);

=head2 receiver_email

Email that will receive this payment
ie. sales@mystore.com

=cut

has receiver_email => ( #to print the sotre name on the paypment form
    is => 'rw',
);

=head2 ua

Uses HTTP::Tiny as useragent

=cut

has ua => (
    is => 'rw',
    default => sub { HTTP::Tiny->new() },
);

sub BUILD {
    my $self = shift;
    if ( $self->sandbox ) {
        $self->api_url('https://desenvolvedor.moip.com.br/sandbox/ws/alpha/EnviarInstrucao/Unica');
    } else {
        $self->api_url('https://www.moip.com.br/ws/alpha/EnviarInstrucao/Unica');
    }
};

=head2 make_xml_transaction

Registers the transaction on the Moip servers.
Receives an $cart, generates the XML and register the transaction on the Moip Server.
Returns the moip transaction token upon success.
Returns the full raw_error when fails.

Return on success:
    {
        code    "SUCCESS",
        id      201301231157322850000001500872,
        token   "C2R0A1V3K0P132J3Q1C1S5M7R3N2P2N8B5L0Q0M0J05070U1W5K0P018D7T2"
    }

Return on error:
    {
        code    "ERROR",
        raw_error   "<ns1:EnviarInstrucaoUnicaResponse xmlns:ns1="http://www.moip.com.br/ws/alpha/"><Resposta><ID>201301231158069350000001500908</ID><Status>Falha</Status><Erro Codigo="2">O valor do pagamento deverá ser enviado obrigator
    iamente</Erro></Resposta></ns1:EnviarInstrucaoUnicaResponse>"
    }

=cut

sub make_xml_transaction {
    my ( $self, $cart ) = @_;
    my $xml = $self->payment_to_xml( $cart );
    my $res = $self->ua->request(
        'POST',
        $self->api_url,
        {
            headers => {
                'Authorization' =>
                    'Basic ' .
                    MIME::Base64::encode($self->token_acesso.":".$self->chave_acesso,''),
                'Content-Type' => 'application/x-www-form-urlencoded',
            },
            content => $xml,
        }
    );
    my $final_res = {};
    if ( $res->{content} =~ m|\<Status\>Sucesso\</Status\>|mig ) {
        $final_res->{ code } = 'SUCCESS';
        #pega token:
        my ( $token ) = $res->{content} =~ m|\<Token\>([^<]+)\</Token\>|mig;
        $final_res->{ token } = $token if defined $token;
        #pega id:
        my ( $id ) = $res->{content} =~ m|\<ID\>([^<]+)\</ID\>|mig;
        $final_res->{ id } = $id if defined $id;
    } else {
        $final_res->{ code } = 'ERROR';
        $final_res->{ raw_error } = $res->{ content };
    }
    return $final_res;
}

=head2 notify

Not implemented yet for Moip

=cut

sub notify {
    my ( $self, $req ) = @_;
}

=head2 payment_to_xml

Generates an XML with the information in $cart and other attributes ie. receiver_label, id_proprio, buyer email, etc
returns the Moip XML format

=cut

sub payment_to_xml {
    my ( $self, $cart ) = @_;

    $self->log->debug("\$cart: " . Dumper( $cart));
    $self->log->debug("\$cart->buyer: " . Dumper( $cart->buyer));

    my $xml;

    $xml = "<EnviarInstrucao>
                <InstrucaoUnica TipoValidacao=\"Transparente\">
                    <Razao>Pagamento para loja ".$self->receiver_label." </Razao>
                        <Valores>";
    # valores
    foreach my $item ( @{$cart->_items} ) {
        $xml .=             "\n<Valor moeda=\"BRL\">".$item->price."</Valor>";
    }
    $xml .=             "\n</Valores>";

    # id proprio
    if ( $self->id_proprio ) {
        $xml .=     "\n<IdProprio>". $self->id_proprio ."</IdProprio>";
    }

    # dados do pagador
    if ( $cart->buyer ) {
        $xml .= "\n<Pagador>";
        if ( $cart->buyer->name ) {
                $xml .= "\n<Nome>".$cart->buyer->name."</Nome>";
        }
        if ( $cart->buyer->email ) {
                $xml .= "\n<Email>".$cart->buyer->email."</Email>";
        }
        if ( $cart->buyer->id_carteira ) {
                $xml .= "\n<IdPagador>".$cart->buyer->id_carteira."</IdPagador>";
        }
        if (
            defined $cart->buyer->address_district  ||
            defined $cart->buyer->address_number    ||
            defined $cart->buyer->address_country   ||
            defined $cart->buyer->address_district  ||
            defined $cart->buyer->address_state     ||
            defined $cart->buyer->address_street    ||
            defined $cart->buyer->address_zip_code
        ) {
            $xml .= "\n<EnderecoCobranca>";
            if ( defined $cart->buyer->address_street ) {
                $xml .= "\n<Logradouro>".$cart->buyer->address_street."</Logradouro>";
            }
            if ( defined $cart->buyer->address_number ) {
                $xml .= "\n<Numero>".$cart->buyer->address_number."</Numero>";
            }
            if ( defined $cart->buyer->address_complement ) {
                $xml .= "\n<Complemento>".$cart->buyer->address_complement."</Complemento>";
            }
            if ( defined $cart->buyer->address_district ) {
                $xml .= "\n<Bairro>".$cart->buyer->address_district."</Bairro>";
            }
            if ( defined $cart->buyer->address_city ) {
                $xml .= "\n<Cidade>".$cart->buyer->address_city."</Cidade>";
            }
            if ( defined $cart->buyer->address_state ) {
                $xml .= "\n<Estado>".$cart->buyer->address_state."</Estado>";
            }
            if ( defined $cart->buyer->address_country ) {
                $xml .= "\n<Pais>".$cart->buyer->address_country."</Pais>";
            }
            if ( defined $cart->buyer->address_zip_code ) {
                $xml .= "\n<CEP>".$cart->buyer->address_zip_code."</CEP>";
            }
            if ( defined $cart->buyer->phone ) {
                $xml .= "\n<TelefoneFixo>".$cart->buyer->phone."</TelefoneFixo>";
            }
            $xml .= "\n</EnderecoCobranca>";
        }
        $xml .= "</Pagador>";
    }

    if (
            defined $cart->due_date
        ) {
        $xml .= "\n<Boleto>
            <DataVencimento>".$cart->due_date."</DataVencimento>
            <Instrucao1></Instrucao1>
            <Instrucao2></Instrucao2>
            <Instrucao3></Instrucao3>";
        if ( defined $cart->logo_url ) {
            $xml .= "\n<URLLogo>".$cart->logo_url."/layout/img/logos/logo.png</URLLogo>";
        }
        $xml .= "\n</Boleto>";
    }

    if ( defined $cart->parcelas and scalar @{ $cart->parcelas } > 0 ) {
        $xml .= "\n<Parcelamentos>";
        foreach my $parcela ( @{ $cart->parcelas } ) {
            if ( defined $parcela->{parcelas_max} and defined $parcela->{parcelas_min} ) {
                $xml .= "\n<Parcelamento>";
                        if ( defined $parcela->{parcelas_min}  ) {
                            $xml .= "\n<MinimoParcelas>".$parcela->{parcelas_min}."</MinimoParcelas>";
                        }
                        if ( defined $parcela->{parcelas_max} ) {
                            $xml .= "\n<MaximoParcelas>".$parcela->{parcelas_max}."</MaximoParcelas>";
                        }
                        $xml .= "\n<Juros>"; $xml .= ( defined $parcela->{juros} )?$parcela->{juros}:'0'; $xml .= "</Juros>";
                $xml .= "\n</Parcelamento>";
            }
        }
        $xml .= "\n</Parcelamentos>";
    }
    $xml .= "\n</InstrucaoUnica>
        </EnviarInstrucao>";

    return $xml;
}

=head1 AUTHOR

    Hernan Lopes
    CPAN ID: HERNAN
    -
    hernan@cpan.org
    http://www.movimentoperl.com.br

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

