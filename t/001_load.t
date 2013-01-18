# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More;

BEGIN { use_ok( 'Business::CPI::Gateway::Moip' ); }

ok(my $cpi = Business::CPI::Gateway::Moip->new(
    receiver_email => 'hernannixus@hotmail.com',
), 'build $cpi');

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
        address_country    => 'BR',
    }
}), 'build $cart');

isa_ok($cart, 'Business::CPI::Cart');

ok(my $item = $cart->add_item({
    id          => 1,
    quantity    => 1,
    price       => 200,
    description => 'my desc',
}), 'build $item');

ok(my $form = $cart->get_form_to_pay(123), 'get form to pay');
isa_ok($form, 'HTML::Element');

use Data::Printer;
warn p $cart->_items;

$cpi->notify( );


done_testing();
