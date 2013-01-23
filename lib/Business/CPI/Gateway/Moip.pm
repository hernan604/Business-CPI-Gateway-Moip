package Business::CPI::Gateway::Moip;
use Moo;
use Data::Printer;
use MIME::Base64;
use Carp 'croak';
use bareword::filehandles;
use indirect;
use multidimensional;
use HTTP::Tiny;

our $VERSION     = '0.01';

extends 'Business::CPI::Gateway::Base';

has sandbox => (
    is => 'rw',
    default => 0,
);

has 'api_url' => (
    is => 'rw',
);

has token_acesso => (
    is => 'rw',
    required => 1,
);

has chave_acesso => (
    is => 'rw',
    required => 1,
);

has id_proprio => (
    is => 'rw',
);

has receiver_label => ( #to print the sotre name on the paypment form
    is => 'rw',
);

has receiver_email => ( #to print the sotre name on the paypment form
    is => 'rw',
);

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

sub is_valid {
    my ( $self, $req ) = @_;
    #croak 'Invalid' unless $args;
    return 1;
}

sub xml_transaction {
    my ( $self, $cart ) = @_;
    my $xml = $self->payment_to_xml( $cart );
warn p $xml;
#   warn p $self->chave_acesso;
#   warn p $self->token_acesso;
#   warn p $self->api_url;
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
    return $res;
}

# executa transacao. validar antes.
sub notify {
    my ( $self, $req ) = @_;
    #warn p $req;
   #next unless $self->is_valid($req);

   # APOS PAGAR, tem que retornar um objeto neste estilo:
   #my $r = {
   #    payment_id             => $vars{invoice},
   #    status                 => $self->_interpret_status($vars{payment_status}),
   #    gateway_transaction_id => $vars{txn_id},
   #    exchange_rate          => $vars{exchange_rate},
   #    net_amount             => ($vars{settle_amount} || $vars{mc_gross}) - ($vars{mc_fee} || 0),
   #    amount                 => $vars{mc_gross},
   #    fee                    => $vars{mc_fee},
   #    date                   => $vars{payment_date},
   #    payer => {
   #        name  => $vars{first_name} . ' ' . $vars{last_name},
   #        email => $vars{payer_email},
   #    }
   #};

    warn "Iniciando transação";
}

sub payment_to_xml {
    my ( $self, $cart ) = @_;

    # Loop nos itens do carrinho e dados do comprador e parcelamento e boleto.. depois só pingar no moip e buscar o token
    warn p $cart;
    warn p $cart->buyer;
    warn $self->receiver_email;

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

        $xml .= "
            <Parcelamentos>
              <Parcelamento>
                <Recebimento>"; $xml .= ( defined $cart->parcelas_max && defined $cart->parcelas_min ) ? "Parcelado" : "AVista";
                $xml .= "</Recebimento>";
                if ( defined $cart->parcelas_min  ) {
                    $xml .= "\n<MinimoParcelas>".$cart->parcelas_min."</MinimoParcelas>";
                }
                if ( defined $cart->parcelas_max ) {
                    $xml .= "\n<MaximoParcelas>".$cart->parcelas_max."</MaximoParcelas>";
                }
                $xml .= "\n<Juros>"; $xml .= ( defined $cart->juros )?$cart->juros:'0'; $xml .= "</Juros>";
        $xml .= "
              </Parcelamento>
            </Parcelamentos>
          </InstrucaoUnica>
        </EnviarInstrucao>";

    return $xml;
}


=head1 NAME

Business::CPI::Gateway::Moip - Inteface para pagamentos moip

=head1 SYNOPSIS

  use Business::CPI::Gateway::Moip;
  blah blah blah


=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.

=head1 EXEMPLO CRU

sub teste_pagamento {
    my ( $self ) = @_;
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
}

=head1 USAGE



=head1 BUGS



=head1 SUPPORT



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

