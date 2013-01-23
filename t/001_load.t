# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More;
use Data::Printer;
use Business::CPI::Buyer::Moip;
use Business::CPI::Cart::Moip;

BEGIN { use_ok( 'Business::CPI::Gateway::Moip' ); }

ok(my $cpi = Business::CPI::Gateway::Moip->new(
    currency => 'BRL',
    sandbox      => 1,
    token_acesso => 'YC110LQX7UQXEMQPLYOPZ1LV9EWA8VKD',
    chave_acesso => 'K03JZXJLOKJNX0CNL0NPGGTHTMGBFFSKNX6IUUWV',

), 'build $cpi');
warn p $cpi;
warn "^^ CPI ^^";
$cpi->receiver_email('teste@casajoka.com.br');
$cpi->receiver_label('Casa Joka');
$cpi->id_proprio('ID_INTERNO_DA_LOJA_'.int rand(int rand(99999999)));
$cpi->sandbox(1);

isa_ok($cpi, 'Business::CPI::Gateway::Moip');

ok(my $cart = $cpi->new_cart({
    buyer => {
        name               => 'Mr. Buyer',
        email              => 'sender@andrewalker.net',
        address_street     => 'Street 1',
        address_number     => '25b',
        address_district   => 'My neighbourhood',
        address_complement => 'Apartment 05',
        address_city       => 'Happytown',
        address_state      => 'SP',
        address_country    => 'BRA',
        phone              => '11-9911-0022',
        id_carteira        => 'O11O22X33X',
        address_zip_code   => '04363-040',
    }
},{
    buyer   => Business::CPI::Buyer::Moip->new(),
    cart    => Business::CPI::Cart::Moip->new(),
}), 'build $cart');

isa_ok($cart, 'Business::CPI::Cart');

$cart->due_date('21/12/2012');
$cart->logo_url('http://www.nixus.com.br/img/logo_nixus.png');

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

my $res = $cpi->xml_transaction( $cart );
warn p $res;

done_testing();
