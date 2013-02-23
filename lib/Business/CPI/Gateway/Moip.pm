package Business::CPI::Gateway::Moip;
use Moo;
use MIME::Base64;
use Carp 'croak';
use bareword::filehandles;
use indirect;
use multidimensional;
use HTTP::Tiny;
use Data::Dumper;
use XML::LibXML;
use Data::Printer;
use Locale::Country;

extends 'Business::CPI::Gateway::Base';

our $VERSION     = '0.03';

=pod

=encoding utf-8

=head1 NAME

Business::CPI::Gateway::Moip - Inteface para pagamentos Moip

=head1 SYNOPSIS

    use Data::Printer;
    use Business::CPI::Buyer::Moip;
    use Business::CPI::Cart::Moip;
    use Business::CPI::Gateway::Moip;

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
            address_country    => 'Brazil',
            address_zip_code   => '04363-040',
            phone              => '11-9911-0022',
            id_pagador         => 'O11O22X33X',
        },
        mensagens => [
            'Produto adquirido no site X',
            'Total pago + frete - Preço: R$ 144,10',
            'Mensagem linha3',
        ],
        boleto => {
            expiracao       => {
                dias => 7,
                tipo => 'corridos', #ou uteis
            },
            data_vencimento => '2012/12/30T24:00:00.0-03:00',
            instrucao1      => 'Primeira linha de instrução de pagamento do boleto bancário',#OPT
            instrucao2      => 'Segunda linha de instrução de pagamento do boleto bancário', #OPT
            instrucao3      => 'Terceira linha de instrução de pagamento do boleto bancário',#OPT
            logo_url        => 'http://www.nixus.com.br/img/logo_nixus.png',                 #OPT
        },
        formas_pagamento => [
            'BoletoBancario',
            'CartaoDeCredito',
            'DebitoBancario',
            'CartaoDeDebito',
            'FinanciamentoBancario',
            'CarteiraMoIP',
        ],
        url_retorno => 'http://www.url_retorno.com.br',
        url_notificacao => 'http://www.url_notificacao.com.br',
        entrega => {
            destino => 'MesmoCobranca',
            calculo_frete => [
                {
                    tipo => 'proprio', #ou correios
                    valor_fixo => 2.30, #ou valor_percentual
                    prazo => {
                        tipo  => 'corridos', #ou uteis
                        valor => 2,
                    }
                },
                {
                    tipo             => 'correios',
                    valor_percentual => 12.30,
                    prazo => {
                        tipo    => 'corridos',#ou uteis
                        valor   => 2,
                    },
                    correios => {
                        peso_total          => 12.00,
                        forma_entrega       => 'Sedex10', #ou sedex sedexacobrar sedexhoje
                        mao_propria         => 'PagadorEscolhe', #ou SIM ou NAO
                        valor_declarado     => 'PagadorEscolhe', #ou SIM ou NAO
                        aviso_recebimento   => 'PagadorEscolhe', # ou SIM ou NAO
                        cep_origem          => '01230-000',
                    },
                },
                {
                    tipo => 'correios',
                    valor_percentual => 12.30,
                    prazo => {
                        tipo    => 'corridos',#ou uteis
                        valor   => 2,
                    },
                    correios => {
                        peso_total          => 12.00,
                        forma_entrega       => 'Sedex10', #ou sedex sedexacobrar sedexhoje
                        mao_propria         => 'PagadorEscolhe', #ou SIM ou NAO
                        valor_declarado     => 'PagadorEscolhe', #ou SIM ou NAO
                        aviso_recebimento   => 'PagadorEscolhe', # ou SIM ou NAO
                        cep_origem          => '01230-000',
                    },
                },
            ]
        }
    },
    );

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

    Return on success:
        $res = {
            code    "SUCCESS",
            id      201301231157322850000001500872,
            token   "C2R0A1V3K0P132J3Q1C1S5M7R3N2P2N8B5L0Q0M0J05070U1W5K0P018D7T2"
        }

    Return on error:
        $res = {
            code    "ERROR",
            raw_error   "<ns1:EnviarInstrucaoUnicaResponse xmlns:ns1="http://www.moip.com.br/ws/alpha/"><Resposta><ID>201301231158069350000001500908</ID><Status>Falha</Status><Erro Codigo="2">O valor do pagamento deverá ser enviado obrigator
        iamente</Erro></Resposta></ns1:EnviarInstrucaoUnicaResponse>"
        }

=head1 EXAMPLE USING Business:CPI

The following example will use Business::CPI directly

    use Business::CPI;
    use Data::Printer;

    my $moip = Business::CPI->new(
        gateway        => "Moip",
        sandbox         => 1,
        token_acesso    => 'YC110LQX7UQXEMQPLYOPZ1LV9EWA8VKD',
        chave_acesso    => 'K03JZXJLOKJNX0CNL0NPGGTHTMGBFFSKNX6IUUWV',
        receiver_email  => 'teste@casajoka.com.br',
        receiver_label  => 'Casa Joka',
        id_proprio      => 'ID_INTERNO_'.int rand(int rand(99999999)),
    );

    my $cart = $moip->new_cart({
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
            id_pagador         => 'O11O22X33X',
        }
    });

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

    my $res = $moip->make_xml_transaction( $cart );
    warn p $res;

=head1 MOIP DOCUMENTATION REFERENCE

http://labs.moip.com.br

http://labs.moip.com.br/referencia/minuto/

http://labs.moip.com.br/referencia/pagamento_parcelado/

=head1 SANDBOX

Register yourself in the Moip sandbox: http://labs.moip.com.br/

=head1 DESCRIPTION

Business::CPI::Gateway::Moip allows you to make moip transactions using Business::CPI standards.

Currently, Moip uses XML format for transactions.

This module will allow you to easily create a cart with items and buyer infos and payment infos. And, after setting up all this information, you will be able to:

    ->make_xml_transaction

and register your transaction within moip servers to obtain a moip transaction tokenid.

** make_xml_transaction will return a TOKEN and code SUCCESS upon success. You will need this info so your user can checkout afterwards.

* see the tests for examples

=head1 MOIP TRANSACTION FLOW

Here, ill try to describe how the moip transaction flow works:

    1. You post the paymentXML to the moip servers
    2. Moip returns a transaction token id upon success

Then, you have 2 options for checkout:

    - option1 (send the user to moip site to finish transaction):
    - 3. You redirect your client to moip servers passing the transaction token id

    - option2 (use the moip transaction id and some javascript for checkout):
    3. You use some javascript with the transaction token id

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
    default => sub { return 0 },
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

has receiver_label => ( #to print the store name on the paypment form
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

=head1 METHODS
=cut

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
    #warn $xml;
    $self->log->debug("moip-xml: " . $xml);
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
    #TODO:
    #http://labs.moip.com.br/parametro/Recebedor/
    #é so implementar no CPI::Cart::Moip e incluir aqui no xml abaixo com as devidas validacoes

    $self->log->debug("\$cart: " . Dumper( $cart));
    $self->log->debug("\$cart->buyer: " . Dumper( $cart->buyer));

    my $xml2 = XML::LibXML::Document->new('1.0','utf-8');
    my $enviar_instrucao = $xml2->createElement('EnviarInstrucao');
    $xml2->addChild( $enviar_instrucao );

    my $instrucao_unica = $xml2->createElement('InstrucaoUnica');
    $instrucao_unica->setAttribute( 'TipoValidacao', 'Transparente' );
    $enviar_instrucao->addChild( $instrucao_unica );

    $self->add_url_retorno2       ( $xml2 , $cart , $instrucao_unica );
    $self->add_url_notificacao2   ( $xml2 , $cart , $instrucao_unica );
    $self->add_formas_pagamento2  ( $xml2 , $cart , $instrucao_unica );
    $self->add_mensagens2         ( $xml2 , $cart , $instrucao_unica );
    $self->add_razao2             ( $xml2 , $cart , $instrucao_unica );
    $self->add_valores2           ( $xml2 , $cart , $instrucao_unica );
    $self->add_id_proprio2        ( $xml2 , $cart , $instrucao_unica );
    $self->add_pagador2           ( $xml2 , $cart , $instrucao_unica );
    $self->add_boleto2            ( $xml2 , $cart , $instrucao_unica );
    $self->add_parcelas2          ( $xml2 , $cart , $instrucao_unica );
    $self->add_comissoes2         ( $xml2 , $cart , $instrucao_unica );
    $self->add_entrega2           ( $xml2 , $cart , $instrucao_unica );

warn p $xml2->toString();
    return $xml2->toString();
}

sub add_url_retorno2 {
    my ( $self, $xml , $cart, $parent_node ) = @_;
    if ( defined $cart->url_retorno ) {
        my $url_retorno = $xml->createElement( 'URLRetorno' );
        $url_retorno->appendText( $cart->url_retorno );
        $parent_node->addChild( $url_retorno );
    }
}

sub add_url_notificacao2 {
    my ( $self, $xml , $cart, $parent_node ) = @_;
    if ( defined $cart->url_notificacao ) {
        my $node = $xml->createElement( 'URLNotificacao' );
        $node->appendText( $cart->url_notificacao );
        $parent_node->addChild( $node );
    }
}

sub add_formas_pagamento2 {
    my ( $self, $xml , $cart, $parent_node ) = @_;
    if ( defined $cart->formas_pagamento and ref $cart->formas_pagamento eq ref [] ) {
        my $node = $xml->createElement('FormasPagamento');
        foreach my $forma ( @{ $cart->formas_pagamento } ) {
            my $node_forma = $xml->createElement('FormaPagamento');
            $node_forma->appendText( $forma );
            $node->appendChild( $node_forma );
        }
        $parent_node->appendChild( $node );
    }
}

sub add_entrega2 {
    my ( $self, $xml, $cart, $parent_node ) = @_;
    if ( defined $cart->entrega ) {
        my $node_entrega = $xml->createElement('Entrega');
        $parent_node->addChild( $node_entrega );
        if ( exists $cart->entrega->{destino} ) {
            my $node = $xml->createElement('Destino');
            $node->appendText($cart->entrega->{destino});
            $node_entrega->addChild($node);
        }
        foreach my $e ( @{ $cart->entrega->{ calculo_frete } } ) {
            my $node_frete = $xml->createElement('CalculoFrete');

            if ( exists $e->{ tipo } ) {
                my $node = $xml->createElement('Tipo');
                if ( $e->{ tipo } =~ m/proprio/ig ) {
                    $node->appendText('Proprio');
                }
                elsif ( $e->{ tipo } =~ m/correio/ig ) {
                    $node->appendText('Correios');
                }
                $node_frete->addChild( $node );
            }
            if ( exists $e->{ valor_fixo } ) {
                my $node = $xml->createElement('ValorFixo');
                $node->appendText($e->{ valor_fixo });
                $node_frete->addChild($node);
            }
            if ( exists $e->{ valor_percentual } ) {
                my $node = $xml->createElement('ValorPercentual');
                $node->appendText( $e->{ valor_percentual } );
                $node_frete->addChild($node);
            }
            if ( exists $e->{ prazo } and
                 exists $e->{ prazo }->{ valor } and
                 exists $e->{ prazo }->{ tipo }
            ) {
                if ( $e->{ prazo }->{ tipo } =~ m/corridos/ig ) {
                    my $node_prazo = $xml->createElement('Prazo');
                    $node_prazo->setAttribute( 'Tipo', 'Corridos' );
                    $node_prazo->appendText( $e->{ prazo }->{ valor } );
                    $node_frete->addChild( $node_prazo );
                }
                if ($e->{ prazo }->{ tipo } =~ m/uteis/ig ) {
                    my $node_prazo = $xml->createElement('Prazo');
                    $node_prazo->setAttribute( 'Tipo', 'Uteis' );
                    $node_prazo->appendText( $e->{ prazo }->{ valor } );
                    $node_frete->addChild( $node_prazo );
                }
            }
            if ( exists $e->{ correios } ) {
                my $node_correios = $xml->createElement('Correios');
                $node_frete->addChild( $node_correios );
                if ( exists $e->{correios}->{peso_total} ) {
                    my $node = $xml->createElement('PesoTotal');
                    $node->appendText($e->{correios}->{peso_total});
                    $node_correios->addChild($node);
                }
                if ( exists $e->{correios}->{forma_entrega} ) {
                    my $node = $xml->createElement('FormaEntrega');
                    $node->appendText($e->{correios}->{forma_entrega});
                    $node_correios->addChild($node);
                }
                if ( exists $e->{correios}->{mao_propria} ) {
                    my $node = $xml->createElement('MaoPropria');
                    $node->appendText($e->{correios}->{mao_propria});
                    $node_correios->addChild($node);
                }
                if ( exists $e->{correios}->{valor_delarado} ) {
                    my $node = $xml->createElement('ValorDeclarado');
                    $node->appendText($e->{correios}->{valor_declarado});
                    $node_correios->addChild($node);
                }
                if ( exists $e->{correios}->{aviso_recebimento} ) {
                    my $node = $xml->createElement('AvisoRecebimento');
                    $node->appendText($e->{correios}->{aviso_recebimento});
                    $node_correios->addChild($node);
                }
                if ( exists $e->{correios}->{cep_origem} ) {
                    my $node = $xml->createElement('CepOrigem');
                    $node->appendText($e->{correios}->{cep_origem});
                    $node_correios->addChild($node);
                }
            }
        }
    }
}

sub add_razao2 {
    my ( $self, $xml, $cart, $parent_node ) = @_;
    my $node = $xml->createElement( 'Razao' );
    $node->appendText( "Pagamento para loja ".$self->receiver_label );
    $parent_node->addChild( $node );
}


sub add_comissoes2 {
    my ( $self, $xml, $cart, $parent_node ) = @_;
    if ( defined $cart->comissoes || defined $cart->pagador_taxa ) {
        my $node_comissoes = $xml->createElement('Comissoes');
        $parent_node->addChild( $node_comissoes );
        if ( defined $cart->comissoes ) {
            foreach my $comissao ( @{ $cart->comissoes } ) {
                my $node_comissionamento = $xml->createElement('Comissionamento');
                $node_comissoes->addChild( $node_comissionamento );
                if ( exists $comissao->{razao} ) {
                    my $node = $xml->createElement('Razao');
                    $node->appendText($comissao->{razao});
                    $node_comissionamento->addChild($node);
                }
                if ( exists $comissao->{login_moip} ) {
                    my $node_comissionado = $xml->createElement( 'Comissionado' );
                    my $node_login_moip = $xml->createElement( 'LoginMoIP' );
                    $node_login_moip->appendText($comissao->{login_moip});
                    $node_comissionado->addChild( $node_login_moip );
                    $node_comissionamento->addChild( $node_comissionado );
                }
                if ( exists $comissao->{valor_percentual} ) {
                    my $node = $xml->createElement('ValorPercentual');
                    $node->appendText($comissao->{valor_percentual});
                    $node_comissionamento->addChild( $node );
                }
                if ( exists $comissao->{valor_fixo} ) {
                    my $node = $xml->createElement('ValorFixo');
                    $node->appendText($comissao->{valor_fixo});
                    $node_comissionamento->addChild( $node );
                }
            }
        }
        if ( defined $cart->pagador_taxa ) {
            my $node_pagador_taxa = $xml->createElement('PagadorTaxa');
            my $node_login_moip = $xml->createElement('LoginMoIP');
            $node_login_moip->appendText( $cart->pagador_taxa );
            $node_pagador_taxa->addChild( $node_login_moip );
            $node_comissoes->addChild( $node_pagador_taxa );
        }
    }
}

sub add_parcelas2 {
    my ( $self, $xml, $cart, $parent_node ) = @_;
    if ( defined $cart->parcelas and scalar @{ $cart->parcelas } > 0 ) {
        my $node_parcelamentos = $xml->createElement('Parcelamentos');
        $parent_node->addChild( $node_parcelamentos );
        foreach my $parcela ( @{ $cart->parcelas } ) {
            if ( defined $parcela->{parcelas_max} and defined $parcela->{parcelas_min} ) {
                my $node_parcelamento = $xml->createElement('Parcelamento');
                $node_parcelamentos->addChild( $node_parcelamento );

                if ( defined $parcela->{parcelas_min}  ) {
                    my $node_parcela_min = $xml->createElement( 'MinimoParcelas' );
                    $node_parcela_min->appendText( $parcela->{parcelas_min} );
                    $node_parcelamento->addChild( $node_parcela_min );
                }
                if ( defined $parcela->{parcelas_max} ) {
                    my $node_parcela_max = $xml->createElement( 'MaximoParcelas' );
                    $node_parcela_max->appendText( $parcela->{parcelas_max} );
                    $node_parcelamento->addChild( $node_parcela_max );
                }
                my $node_juros = $xml->createElement('Juros');
                $node_parcelamento->addChild( $node_juros );
                $node_juros->appendText( 0 );
                if ( exists $parcela->{juros} ) {
                    $node_juros->appendText( $parcela->{ juros } );
                }
            }
        }
    }
}


sub add_id_proprio2 {
    my ( $self, $xml, $cart, $parent_node ) = @_;
    if ( $self->id_proprio ) {
        my $node = $xml->createElement( 'IdProprio' );
        $node->appendText( $self->id_proprio ); #TODO pode ser movido pro $cart
        $parent_node->addChild( $node );
    }
}

sub add_valores2 {
    my ( $self, $xml, $cart, $parent_node ) = @_;
    my $node = $xml->createElement( 'Valores' );
    foreach my $item ( @{$cart->_items} ) {
        my $node_valor = $xml->createElement('Valor');
        $node_valor->setAttribute( 'moeda', $self->currency ); # TODO: currency pode ficar no cart. mover pra $cart
        $node_valor->appendText( $item->price );
        $node->addChild( $node_valor );
    }
    $parent_node->addChild( $node );
}

sub add_mensagens2 {
    my ( $self, $xml, $cart, $parent_node ) = @_;
    if ( defined $cart->mensagens and scalar @{ $cart->mensagens } > 0 ) {
        my $node = $xml->createElement( 'Mensagens' );
        foreach my $msg ( @{ $cart->mensagens } ) {
            my $node_msg = $xml->createElement( 'Mensagem' );
            $node_msg->appendText( $msg );
            $node->addChild( $node_msg );
        }
        $parent_node->addChild( $node );
    }
}

sub add_pagador2 {
    my ( $self, $xml, $cart, $parent_node ) = @_;
    # dados do pagador
    if ( $cart->buyer ) {
        my $node_pagador = $xml->createElement('Pagador');
        $parent_node->addChild( $node_pagador );
        if ( $cart->buyer->name ) {
            my $node = $xml->createElement('Nome');
            $node->appendText( $cart->buyer->name );
            $node_pagador->addChild( $node );
        }
        if ( $cart->buyer->email ) {
            my $node = $xml->createElement('Email');
            $node->appendText( $cart->buyer->email );
            $node_pagador->addChild( $node );
        }
        if ( $cart->buyer->id_pagador ) {
            my $node = $xml->createElement('IdPagador');
            $node->appendText($cart->buyer->id_pagador);
            $node_pagador->addChild( $node );
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
            my $node_cobranca = $xml->createElement('EnderecoCobranca');
            $node_pagador->addChild( $node_cobranca );
            if ( defined $cart->buyer->address_street ) {
                my $node = $xml->createElement('Logradouro');
                $node->appendText($cart->buyer->address_street);
                $node_cobranca->addChild($node);

            }
            if ( defined $cart->buyer->address_number ) {
                my $node = $xml->createElement('Numero');
                $node->appendText($cart->buyer->address_number);
                $node_cobranca->addChild($node);

            }
            if ( defined $cart->buyer->address_complement ) {
                my $node = $xml->createElement('Complemento');
                $node->appendText($cart->buyer->address_complement);
                $node_cobranca->addChild($node);

            }
            if ( defined $cart->buyer->address_district ) {
                my $node = $xml->createElement('Bairro');
                $node->appendText($cart->buyer->address_district);
                $node_cobranca->addChild($node);

            }
            if ( defined $cart->buyer->address_city ) {
                my $node = $xml->createElement('Cidade');
                $node->appendText($cart->buyer->address_city);
                $node_cobranca->addChild($node);

            }
            if ( defined $cart->buyer->address_state ) {
                my $node = $xml->createElement('Estado');
                $node->appendText($cart->buyer->address_state);
                $node_cobranca->addChild($node);

            }
            if ( defined $cart->buyer->address_country ) {
                my $sigla = uc(
                    Locale::Country::country_code2code(
                        $cart->buyer->address_country, 'alpha-2', 'alpha-3'
                    )
                );
                my $node = $xml->createElement('Pais');
                $node->appendText($sigla);
                $node_cobranca->addChild($node);
            }
            if ( defined $cart->buyer->address_zip_code ) {
                my $node = $xml->createElement('CEP');
                $node->appendText($cart->buyer->address_zip_code);
                $node_cobranca->addChild($node);
            }
            if ( defined $cart->buyer->phone ) {
                my $node = $xml->createElement('TelefoneFixo');
                $node->appendText($cart->buyer->phone);
                $node_cobranca->addChild($node);
            }
        }
    }
}

sub add_boleto2 {
    my ( $self, $xml, $cart, $parent_node ) = @_;
    if (
            defined $cart->boleto
        ) {
        my $node_boleto = $xml->createElement('Boleto');
        $parent_node->addChild( $node_boleto );
        if ( exists $cart->boleto->{ data_vencimento } ) {
            my $node = $xml->createElement('DataVencimento');
            $node->appendText($cart->boleto->{ data_vencimento });
            $node_boleto->addChild($node);
        }
        if ( exists $cart->boleto->{ instrucao1 } ) {
            my $node = $xml->createElement('Instrucao1');
            $node->appendText($cart->boleto->{ instrucao1 });
            $node_boleto->addChild($node);
        }
        if ( exists $cart->boleto->{ instrucao2 } ) {
            my $node = $xml->createElement('Instrucao2');
            $node->appendText($cart->boleto->{ instrucao2 });
            $node_boleto->addChild($node);
        }
        if ( exists $cart->boleto->{ instrucao3 } ) {
            my $node = $xml->createElement('Instrucao3');
            $node->appendText($cart->boleto->{ instrucao3 });
            $node_boleto->addChild($node);
        }
        if ( exists $cart->boleto->{ logo_url } ) {
            my $node = $xml->createElement('URLLogo');
            $node->appendText($cart->boleto->{ logo_url });
            $node_boleto->addChild($node);
        }
        if ( exists $cart->boleto->{ expiracao } ) {
            my $node = $xml->createElement('DiasExpiracao');
            $node->setAttribute( 'Tipo' , $cart->boleto->{ expiracao }->{ tipo } );
            $node->appendText($cart->boleto->{ expiracao }->{ dias });
            $node_boleto->addChild($node);
        }
    }
}

sub get_hidden_inputs {
    my ($self, $info) = @_;
    warn p $self;
    warn "^^ SELF ^^" ;
    warn "^^ SELF ^^" ;
    warn "^^ SELF ^^" ;
#   return (
#       reference => $info->{payment_id},
#       $self->_get_hidden_inputs_main(),
#       $self->_get_hidden_inputs_for_buyer($info->{buyer}),
#       $self->_get_hidden_inputs_for_items($info->{items}),
#       $self->_get_hidden_inputs_for_cart($info->{cart}),
#   );
}

#   sub _checkout_form_main_map {
#       return {
#           receiver_email => 'receiver_email',
#           currency       => 'currency',
#           form_encoding  => 'encoding',
#       };
#   }

#   sub _checkout_form_buyer_map {
#       return {
#           name               => 'senderName',
#           email              => 'senderEmail',
#           address_complement => 'shippingAddressComplement',
#           address_district   => 'shippingAddressDistrict',
#           address_street     => 'shippingAddressStreet',
#           address_number     => 'shippingAddressNumber',
#           address_city       => 'shippingAddressCity',
#           address_state      => 'shippingAddressState',
#           address_zip_code   => 'shippingAddressPostalCode',
#           address_country    => {
#               name => 'shippingAddressCountry',
#               coerce => sub {
#                   uc(
#                       Locale::Country::country_code2code(
#                           $_[0], 'alpha-2', 'alpha-3'
#                       )
#                   )
#               },
#           },
#       };
#   }


=head2 query_transactions()

TODO: http://labs.moip.com.br/blog/saiba-quais-foram-suas-ultimas-transacoes-no-moip-sem-sair-do-seu-site-com-o-moipstatus/

TODO: https://github.com/moiplabs/moip-php/blob/master/lib/MoipStatus.php

*** Não foi implementado pois o moip possúi api boa para transações mas não tem implementado meios para analisar transações entre período.
O único jeito é fazer login no site via lwp ou similar e pegar as informações direto do markup.. mas ao menos neste momento não há seletores que indicam quais os dados.

=head2 query_transactions example

*** NOT IMPLEMENTED... but this is what it would would like more or less.

Thats how it can be done today... making login and parsing the welcome html screen (no good).
Not good because they dont have it on their api... and its not good to rely on markup to read
this sort of important values.

moipstatus.php, on their github acc: https://github.com/moiplabs/moip-php/blob/master/lib/MoipStatus.php

    use HTTP::Tiny;
    use MIME::Base64;
    use Data::Printer;
    use HTTP::Request::Common qw(POST);
    use Mojo::DOM;
    my $url_login = "https://www.moip.com.br/j_acegi_security_check";
    my $login = 'XXXXXXXXXXX';
    my $pass = "XXXXXXX";
    my $url_transactions = 'https://www.moip.com.br/rest/reports/last-transactions';

    my $form_login = [
        j_password => $pass,
        j_username => $login,
    ];

    my $res = HTTP::Tiny->new( verify_SSL => 0 )->request(
        'POST',
        $url_login,
        {
            headers => {
                'Authorization' => 'Basic ' . MIME::Base64::encode($login.":".$pass,''),
                'Content-Type' => 'application/x-www-form-urlencoded',
            },
            content => POST( $url_login, [], Content => $form_login )->content,
        }
    );
    warn p $res;

    warn "login fail" and die if $res->{ headers }->{ location } =~ m/fail/ig;

    my $res2 = HTTP::Tiny->new( verify_SSL => 0 )->request(
        'GET',
        $res->{headers}->{location}
    );
    # warn p $res2;
    my $dom = Mojo::DOM->new($res2->{content});

    SALDO_STATS: {
        my $saldo       = $dom->at('div.textoCinza11 b.textoAzul11:nth-child(3)');
        my $a_receber   = $dom->at('div.textoCinza11 b.textoAzul11:nth-child(10)');
        my $stats = {
            saldo           => (defined $saldo)     ?   $saldo->text     : undef,
            saldo_a_receber => (defined $a_receber) ?   $a_receber->text : undef,
        };
        warn p $stats;
    }

    LAST_TRANSACTIONS:{
        my $selector = 'div.conteudo>div:eq(1)>div:eq(1)>div:eq(1)>div:eq(0) div.box table[cellpadding=5]>tbody tr';
        my $nenhuma = $dom->at( $selector );
        warn p $nenhuma;
    }


=cut

sub query_transactions {}

=head2 get_transaction_details()

TODO: http://labs.moip.com.br/referencia/consulta-de-instrucao/

=cut

sub get_transaction_details {}

=head1 AUTHOR

    Hernan Lopes
    CPAN ID: HERNAN
    -
    hernan@cpan.org
    http://github.com/hernan604

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SPONSOR

http://www.nixus.com.br

=head1 SEE ALSO

perl(1).

=cut

1;
# The preceding line will help the module return a true value

