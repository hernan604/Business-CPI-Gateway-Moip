package Business::CPI::Buyer::Moip;
use Moo;

extends qw/Business::CPI::Buyer/;

has phone => (
    is => 'rw',
);

has id_carteira => (
    is => 'rw',
);

has address_country    => (
    is => 'ro',
);

1;
