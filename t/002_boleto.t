# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More;
use Data::Printer;
use Business::CPI::Buyer::Moip;
use Business::CPI::Cart::Moip;

BEGIN { use_ok( 'Business::CPI::Gateway::Moip' ); }

ok(my $cpi = Business::CPI::Gateway::Moip->new(
    currency        => 'BRL',
    transparent     => 1,
    sandbox         => 1,
    token           => 'YC110LQX7UQXEMQPLYOPZ1LV9EWA8VKD',
    key             => 'K03JZXJLOKJNX0CNL0NPGGTHTMGBFFSKNX6IUUWV',
    receiver_email  => 'teste@xxxxx.com.br',
    receiver_label  => 'Lojas X',

), 'build $cpi');

isa_ok($cpi, 'Business::CPI::Gateway::Moip');

ok(my $cart = $cpi->new_cart({
    payment_id => 'ID_INTERNO_'.int rand(int rand(99999999)),
    buyer => {
        email              => 'teste@teste.com.br',
        name               => 'Mr. Buyer',
        address_street     => 'Rua Mariucha',
        address_number     => '360',
        address_district   => 'Vila Mascote',
        address_complement => 'Ap 35',
        address_city       => 'São Paulo',
        address_state      => 'SP',
        address_country    => 'Brazil',
        address_zip_code   => '04363-040',
        phone              => '11-9911-0022',
    },
    bank_slip => {
        deadline_days 		=> 7,
        instruction_line_1 	=> 'Instrucao linha 1',
        instruction_line_2  => 'Instrucao linha 1',
        logo_url            => 'http://www.nixus.com.br/img/logo_nixus.png',
    },
    return_url          => 'http://www.url_retorno.com.br',
    notification_url    => 'http://www.url_notificacao.com.br',
    shipping => {
        days    => 7,
        cost    => '10.0',
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

my $res = $cpi->get_checkout_code( $cart );

warn p $res;

ok( length($res) == 60, 'pagamento feito com sucesso');

done_testing();
