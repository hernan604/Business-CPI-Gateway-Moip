package Business::CPI::Buyer::Moip;
use Moo;

extends qw/Business::CPI::Buyer/;

=head1 NAME

Business::CPI::Buyer::Moip

=head1 DESCRIPTION

extends Business::CPI::Buyer
and adds some extra attributes specific to moip

=head1 ATTRIBUTES

=head2 phone
buyer phone number
=cut

has phone => (
    is => 'rw',
);

=head2 id_pagador
de acordo com os docs: http://labs.moip.com.br/referencia/integracao_xml_identificacao/
id_pagador is the user_id on moip??
=cut

has id_pagador => (
    is => 'rw',
);

=head2 address_country
country name abreviated, ie BRA
=cut

has address_country    => (
    is => 'ro',
);

1;
