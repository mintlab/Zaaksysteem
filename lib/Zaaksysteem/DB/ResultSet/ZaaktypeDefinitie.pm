package Zaaksysteem::DB::ResultSet::ZaaktypeDefinitie;

use strict;
use warnings;

use Moose;

extends 'DBIx::Class::ResultSet', 'Zaaksysteem::Zaaktypen::BaseResultSet';

# COMPLETE: 100%
use constant    PROFILE => {
    required        => [qw/
        openbaarheid
        handelingsinitiator
        grondslag
        iv3_categorie
        afhandeltermijn
        servicenorm
        besluittype
        selectielijst
    /],
    optional        => [qw/
        afhandeltermijn_type
        servicenorm_type
        procesbeschrijving
        pdc_voorwaarden
        pdc_description
        pdc_meenemen
        pdc_tarief
        webform_authenticatie
        webform_toegang
    /],
    msgs                => sub {
        my $dfv     = shift;
        my $rv      = {};

        for my $missing ($dfv->missing) {
            $rv->{$missing}  = 'Veld is verplicht.';
        }
        for my $missing ($dfv->invalid) {
            $rv->{$missing}  = 'Veld is niet correct ingevuld.';
        }

        return $rv;
    }
};

sub _validate_session {
    my $self            = shift;
    my $profile         = PROFILE;
    my $rv              = {};

    $self->__validate_session(@_, $profile, 1);
}

1;

