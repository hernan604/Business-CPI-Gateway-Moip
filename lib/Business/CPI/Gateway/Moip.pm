package Business::CPI::Gateway::Moip;
use Moose;
use Data::Printer;
use MIME::Base64;
use Carp 'croak';

our $VERSION     = '0.01';

extends 'Business::CPI::Gateway::Base';

has sandbox => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

has '+checkout_url' => (
   #lazy => 1,
);

has '+currency' => (
    default => sub { 'BRL' },
);

has token_acesso => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has chave_acesso => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

sub BUILD {
    my ( $self ) = @_;
    if ( $self->sandbox ) {
        $self->checkout_url('https://desenvolvedor.moip.com.br/sandbox/ws/alpha/EnviarInstrucao/Unica');
    } else {
        $self->checkout_url('https://www.moip.com.br/ws/alpha/EnviarInstrucao/Unica');
    }
};


# executa transacao. validar antes.
sub notify {
    my ( $self, $cart ) = @_;
#   $self->validate($obj);
    my $xml = $self->payment_to_xml( $cart );
    warn "Iniciando transação";
}

sub payment_to_xml {
    my ( $self, $cart ) = @_;

    # Loop nos itens do carrinho e dados do comprador e parcelamento e boleto.. depois só pingar no moip e buscar o token

    my $xml;
    warn $self->receiver_email;
    foreach my $item ( @{$cart->_items} ) {
        warn p $item;
    }

#       $xml = "<EnviarInstrucao>
#     <InstrucaoUnica TipoValidacao=\"Transparente\">
#           <Razao>Pagamento para loja ".$self->receiver_email."</Razao>
#           <Valores>
#               <Valor moeda=\"BRL\">".(($templ_vars->{order}->{use_credit}) ? $templ_vars->{order}->{with_credit} : $templ_vars->{order}->{total})."</Valor>
#           </Valores>
#           <IdProprio>".$templ_vars->{order}->{ord_number}."</IdProprio>
#           <Pagador>
#               <Nome>".$templ_vars->{user}->{first_name}." ".$templ_vars->{user}->{last_name}."</Nome>
#               <Email>".$templ_vars->{user}->{email}."</Email>";
#       $xml .= "
#               <IdPagador>".$pcontent->{id_carteira}."</IdPagador>";
#       $xml .= "
#               <EnderecoCobranca>
#                   <Logradouro>".$templ_vars->{order}->{shipping_address}."</Logradouro>
#                   <Numero>".$templ_vars->{order}->{shipping_address_number}."</Numero>
#                   <Complemento>".$templ_vars->{order}->{shipping_address_comp}."</Complemento>
#                   <Bairro>".$templ_vars->{order}->{shipping_district}."</Bairro>
#                   <Cidade>".$templ_vars->{order}->{shipping_city}."</Cidade>
#                   <Estado>".$templ_vars->{order}->{shipping_state}."</Estado>
#                   <Pais>BRA</Pais>
#                   <CEP>".$templ_vars->{order}->{shipping_zip}."</CEP>
#                   <TelefoneFixo>(".$templ_vars->{user}->{tel_1_ddd}.")".$templ_vars->{user}->{tel_1_number}."</TelefoneFixo>
#               </EnderecoCobranca>
#           </Pagador>";

#       $xml .= "
#       <Boleto>
#           <DataVencimento>".$content->{vencimento}."T12:00:00.000-03:00</DataVencimento>
#           <Instrucao1></Instrucao1>
#           <Instrucao2></Instrucao2>
#           <Instrucao3></Instrucao3>
#           <URLLogo>".$ENV{URL_IMAGE}."/layout/img/logos/logo.png</URLLogo>
#       </Boleto>";

#       $xml .= "
#           <Parcelamentos>
#               <Parcelamento>
#                   <Recebimento>".((defined $pcontent->{parcelamento} && $pcontent->{parcelamento} == 1) ? "Parcelado" : "AVista")."</Recebimento>
#                   <MinimoParcelas>".$templ_vars->{checkout_payment}->{CC}->{parcels}."</MinimoParcelas>
#                   <MaximoParcelas>12</MaximoParcelas>
#                   <Juros>".(($templ_vars->{checkout_payment}->{CC}->{noincre} == 1) ? "0" : "1.99")."</Juros>
#               </Parcelamento>
#           </Parcelamentos>
#     </InstrucaoUnica>
#   </EnviarInstrucao>";

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

