package Business::CPI::Buyer::Moip;
use Moose;

extends qw/Business::CPI::Buyer/;

has phone => (
    is => 'rw',
    isa => 'Any',
);

has id_carteira => (
    is => 'rw',
    isa => 'Any',
);

1;
