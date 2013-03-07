package Zaaksysteem::DB::Component::BibliotheekKenmerken;

use strict;
use warnings;

use Zaaksysteem::Constants qw/ZAAKSYSTEEM_CONSTANTS/;

use base qw/DBIx::Class/;

sub options {
    my ($self) = @_;
    my (@kenmerk_options);

    if (
        exists(ZAAKSYSTEEM_CONSTANTS->{veld_opties}->{
            $self->value_type
        }->{multiple}) &&
        ZAAKSYSTEEM_CONSTANTS->{veld_opties}->{
            $self->value_type
        }->{multiple}
    ) {
        my $values = $self->bibliotheek_kenmerken_values->search(
            {},
            {
                order_by    => { -asc   => 'id' }
            }
        );
        while (my $value = $values->next) {
            push(@kenmerk_options, $value->value);
        }
    }

    return \@kenmerk_options;
}

1;
