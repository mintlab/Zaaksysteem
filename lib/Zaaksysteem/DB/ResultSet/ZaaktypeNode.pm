package Zaaksysteem::DB::ResultSet::ZaaktypeNode;

use strict;
use warnings;

use Moose;

extends 'DBIx::Class::ResultSet', 'Zaaksysteem::Zaaktypen::BaseResultSet';
__PACKAGE__->load_components(qw{Helper::ResultSet::SetOperations});

# COMPLETE: 100%
use constant    PROFILE => {
    required        => [qw/
        zaaktype_categorie_id
        code
        trigger
        titel
    /],
    optional        => [qw/
        adres_relatie
        zaaktype_id
        zaaktype_rt_queue
        webform_toegang
        webform_authenticatie
        aanvrager_hergebruik
        automatisch_aanvragen
        automatisch_behandelen
        toewijzing_zaakintake
        zaaktype_definitie_id
    /],
    constraint_methods  => {
        code        => qr/^\d+$/,
        titel       => qr/^[\w\d _]+$/,
    },
    msgs                => sub {
        my $dfv     = shift;
        my $rv      = {};

        for my $missing ($dfv->missing) {
            $rv->{$missing}  = 'Veld is verplicht.';
        }
        for my $missing ($dfv->invalid) {
            if ($missing eq 'titel') {
                $rv->{$missing}  = 'Veld is niet correct ingevuld of naam bestaat al.';
                next;
            }
            $rv->{$missing}  = 'Veld is niet correct ingevuld.';
        }

        return $rv;
    }
};

sub _validate_session {
    my $self            = shift;
    my $profile         = PROFILE;
    my $rv              = {};

    my $dv = $self->__validate_session(@_, $profile, 1);

    if (
        $dv->valid('titel') &&
        $self->result_source->schema->resultset('Zaaktype')->search(
            {
                'LOWER(zaaktype_node_id.titel)' => lc($_[0]->{titel}),
                'me.deleted'                    => undef,
                'zaaktype_node_id.id'           => { '!=' => $_[0]->{id} },
            },
            {
                join    => ['zaaktype_node_id']
            }
        )->count
    ) {
        $dv->{invalid}->{titel} = $_[0]->{titel};
        $dv->{valid}->{titel}   = undef;
    }

    return $dv;
}

1;
