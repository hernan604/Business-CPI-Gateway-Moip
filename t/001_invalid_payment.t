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
    transparent     => 1,
    token    => 'YC110LQX7UQXEMQPLYOPZ1LV9EWA8VKD',
    key    => 'K03JZXJLOKJNX0CNL0NPGGTHTMGBFFSKNX6IUUWV',
    receiver_email  => 'teste@xxxxx.com.br',
    receiver_label  => 'Lojas X',

), 'build $cpi');

isa_ok($cpi, 'Business::CPI::Gateway::Moip');

ok(my $cart = $cpi->new_cart({
    payment_id      => 'ID_INTERNO_'.int rand(int rand(99999999)),
    buyer => {
        name               => 'Mr. Buyer',
        email              => 'sender@andrewalker.net',
    }
},
), 'build $cart');

isa_ok($cart, 'Business::CPI::Cart');

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

ok(my $item = $cart->add_item({
    id          => 1,
    quantity    => 2,
    price       => 111,
    description => 'produto1',
}), 'build $item');

my $res = $cpi->get_checkout_code( $cart );

ok( !$res, 'transacao deve resultar em erro');
done_testing();
