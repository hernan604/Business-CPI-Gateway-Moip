package Business::CPI::Cart::Moip;
use Moo;

extends qw/Business::CPI::Cart/;

=head1 NAME

Business::CPI::Cart::Moip

=head1 DESCRIPTION

extends Business::CPI::Cart
and adds some extra attributes specific to moip

=head2 due_date
The payment due date (vencimento) ie. 12/12/2012
=cut

has due_date => (
    is => 'rw',
);

=head2 logo_url
Logo url to make prettier invoices
=cut

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
