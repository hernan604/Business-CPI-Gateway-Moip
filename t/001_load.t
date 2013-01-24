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
    receiver_email  => 'teste@casajoka.com.br',
    receiver_label  => 'Casa Joka',
    id_proprio      => 'ID_INTERNO_'.int rand(int rand(99999999)),

), 'build $cpi');

isa_ok($cpi, 'Business::CPI::Gateway::Moip');

ok(my $cart = $cpi->new_cart({
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
    },
    mensagens => [
        'Produto adquirido no site X',
        'Total pago + frete - Preço: R$ 144,10',
        'Mensagem linha3',
    ]
},
#   {
#       buyer   => Business::CPI::Buyer::Moip->new(),
#       cart    => Business::CPI::Cart::Moip->new(),
#   }
), 'build $cart');

isa_ok($cart, 'Business::CPI::Cart');

$cart->boleto({
    expiracao       => {
        dias => 7,
        tipo => 'corridos', #ou uteis
    },
    data_vencimento => '2012/12/30T24:00:00.0-03:00',
    instrucao1      => 'Primeira linha de instrução de pagamento do boleto bancário',
    instrucao2      => 'Segunda linha de instrução de pagamento do boleto bancário',
    instrucao3      => 'Terceira linha de instrução de pagamento do boleto bancário',
    logo_url        => 'http://www.nixus.com.br/img/logo_nixus.png',
});

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

ok( $res->{code} eq 'SUCCESS', 'vai que eh tua, pagamento feito com sucesso');
done_testing();
