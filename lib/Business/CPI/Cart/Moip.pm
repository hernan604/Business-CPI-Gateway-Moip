package Business::CPI::Cart::Moip;
use Moo;

extends qw/Business::CPI::Cart/;

has due_date => (
    is => 'rw',
);

has logo_url => (
    is => 'rw',
);


=head2 parcelas

$self->parcelas([
    {
        parcelas_min => 2
        parcelas_max => 6
        juros => 2.99
    },
    {
        parcelas_min => 7
        parcelas_max => 12
        juros => 10.99
    }
]);

=cut

has parcelas => (
    is => 'rw',
);

1;
