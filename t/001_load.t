# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More;
use Data::Printer;
use Business::CPI::Buyer::Moip;
use Business::CPI::Cart::Moip;

BEGIN { use_ok( 'Business::CPI::Gateway::Moip' ); }

ok(my $cpi = Business::CPI::Gateway::Moip->new(
    currency        => 'BRL',
    sandbox         => 1,
    token_acesso    => 'YC110LQX7UQXEMQPLYOPZ1LV9EWA8VKD',
    chave_acesso    => 'K03JZXJLOKJNX0CNL0NPGGTHTMGBFFSKNX6IUUWV',
    email_acesso    => 'hernannixus@hotmail.com',
    receiver_email  => 'teste@xxxxx.com.br',
    receiver_label  => 'Lojas X',
    id_proprio      => 'ID_INTERNO_'.int rand(int rand(99999999)),

), 'build $cpi');

isa_ok($cpi, 'Business::CPI::Gateway::Moip');

ok(my $cart = $cpi->new_cart({
    valor_total => 1.2,
    id_transacao => 'id-transacao-xxx'. int rand(999999),
    description => 'Compra Produto XYZ, titulo compra',
    frete => 1, #booleano. Indica se o MOIP vai usar o peso_compra para adicionar o valor do frete no seu carrinho. Ou seja, vc nao passa o valor do carrinho, o moip calcula e soma ao valor total do carrinho
    peso_compra => 70.1,
    buyer => {
        name               => 'Mr. Buyer',
        email              => 'sender@andrewalker.net',
        document_id        => '914.123.444-72', # CPF ou CNPJ apenas quando usar <form> p/ pagar
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
), 'build $cart');

isa_ok($cart, 'Business::CPI::Cart');

ok(my $item = $cart->add_item({
    id          => 2,
    quantity    => 1,
    price       => 222,
    description => 'produto2',
}), 'build $item');

ok(my $item = $cart->add_item({
    id          => 1,
    quantity    => 2,
    price       => 111,
    description => 'produto1',
}), 'build $item');

my $res = $cpi->make_xml_transaction( $cart );
warn p $res;


my $form = $cpi->get_form_to_pay( $cart );
my $form_html = $form->as_HTML();

is( $form_html =~ m/pagador_telefone" type="hidden" value="11-9911-0022"/, 1, 'trouxe valor esperado' );
#TODO no teste acima, transformar de volta em HTML::Element e verificar campo a campo.. pois fiz um exemplo rapido verificando via string... mas não é bom pois pode não manter a mesma ordem nos atributos

ok( $res->{code} eq 'SUCCESS', 'pagamento feito com sucesso');
done_testing();
