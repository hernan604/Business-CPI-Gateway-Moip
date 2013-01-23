package Business::CPI::Cart::Moip;
use Moo;

extends qw/Business::CPI::Cart/;

has due_date => (
    is => 'rw',
);

has logo_url => (
    is => 'rw',
);

has parcelas_max => (
    is => 'rw',
);

has parcelas_min => (
    is => 'rw',
);

has juros => (
    is => 'rw',
);

1;
