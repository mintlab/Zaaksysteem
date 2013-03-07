package Zaaksysteem::Model::Zaaktype::Object;

use strict;
use warnings;

use Moose;

use constant    ZTNO_MAP    => {
    'code'              => { naam => 'code'},
    'titel'             => { naam => 'titel'},
    'trigger'           => { naam => 'trigger'},
    'toelichting'       => { naam => 'toelichting'},
    'versie'            => { naam => 'version'},
    'version'           => { naam => 'version'},
    'actief'            => { naam => 'active'},
    'webform_toegang'   => { naam => 'webform_toegang'},
    'automatisch_behandelen'    => { naam => 'automatisch_behandelen'},
    'webform_authenticatie'     => { naam => 'webform_authenticatie'},
    'toewijzing_zaakintake'     => { naam => 'toewijzing_zaakintake'},
    'bedrijfid_wijzigen'        => { naam => 'bedrijfid_wijzigen' },
    'adres_relatie'     => { naam => 'adres_relatie' },
    'rt_queue_naam'     => { naam => 'zaaktype_rt_queue' },
    'hergebruik'        => { naam => 'aanvrager_hergebruik' },
    'online_betaling'   => { naam => 'online_betaling' },
    'adres_aanvrager'   => { naam => 'adres_aanvrager' },
};


### BASICS

has 'c' => (
    'is'        => 'rw',
    'weak_ref'  =>  1,
);

has ['extraopts']  => (
    'is'        => 'rw',
);

has ['nid', 'ztno', 'id']     => (
    'is'        => 'rw',
);

has 'code'          => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return $self->ztno->code;
    }
);

has 'ztc'     => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return $self->ztno->zaaktype_attributens;
    }
);

has 'kenmerken'     => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return $self->ztno->zaaktype_kenmerkens;
    }
);

has 'documenten'     => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return $self->ztno->zaaktype_ztc_documentens;
    }
);

has 'resultaten'     => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return $self->ztno->zaaktype_resultatens;
    }
);

has 'authorisatie'   => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return $self->ztno->zaaktype_id->zaaktype_authorisations;
    }
);

has 'notificatie'   => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return $self->ztno->zaaktype_notificaties;
    }
);

has 'categorie'   => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        if ($self->ztno->zaaktype_id->bibliotheek_categorie_id) {
            return $self->ztno->zaaktype_id->bibliotheek_categorie_id;
        }
        return $self->ztno->zaaktype_id->zaaktype_categorie_id;
    }
);

has 'status'   => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return $self->ztno->zaaktype_statuses->search(
            {},
            {
                order_by    => 'status'
            }
        );
    }
);

has 'sjablonen'   => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return $self->ztno->zaaktype_sjablonens;
    }
);

has 'checklist'   => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return $self->c->model('DB::ChecklistVraag')->search(
            'zaaktype_node_id'   => $self->ztno->id
        );
    }
);

has 'definitie'   => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        return $self->ztno->zaaktype_definitie_id;
    }
);

has 'is_current_versie'   => (
    'is'        => 'rw',
    'lazy'      => 1,
    'default'   => sub {
        my $self    = shift;

        if (
            $self->ztno->zaaktype_id &&
            $self->ztno->zaaktype_id->zaaktype_node_id &&
            $self->ztno->zaaktype_id->zaaktype_node_id->id == $self->ztno->id
        ) {
            return 1;
        }

        return;
    }
);

sub BUILD {
    my $self    = shift;
    my $ztno;

    if (!$self->c) {
        die('ZTNO: Zaaktype Object created without catalyst context object');
    }

    if ( !$self->nid || $self->nid !~ /^\d+$/ ) {
        $self->c->log->error(
            'ZTNO: Zaaktype object created without ZT node id'
        );

        return;
    }

    if (!($ztno = $self->c->model('DB::ZaaktypeNode')->find($self->nid))) {
        $self->c->log->warn(
            'ZTNO: ZT node id not found: ' . $self->nid
        );

        return;
    }

    # Zaaktype node object
    $self->ztno($ztno);

    # Zaaktype id
    $self->id($ztno->zaaktype_id->id);


    my $ztno_map = ZTNO_MAP;
    while (my ($key, $value) = each(%{ $ztno_map })) {
        my $dbnaam = $value->{naam};
        $self->meta->add_attribute(
            $key,
            'is'        => 'rw',
            'lazy'      => 1,
            'default'   => sub {
                my $self    = shift;

                return $self->ztno->$dbnaam;
            }
        );
    }
}

sub setup_datums {
    my ($self, $zaak) = @_;

    $self->c->model('Zaaktype')->_calculate_dates($zaak);
}



1;

=head1 PROJECT FOUNDER

Mintlab B.V. <info@mintlab.nl>

=head1 CONTRIBUTORS

Arne de Boer

Nicolette Koedam

Marjolein Bryant

Peter Moen

Michiel Ootjers

Jonas Paarlberg

Jan-Willem Buitenhuis

Martin Kip

Gemeente Bussum

=head1 COPYRIGHT

Copyright (c) 2009, the above named PROJECT FOUNDER and CONTRIBUTORS.

=head1 LICENSE

The contents of this file and the complete zaaksysteem.nl distribution
are subject to the EUPL, Version 1.1 or - as soon they will be approved by the
European Commission - subsequent versions of the EUPL (the "Licence"); you may
not use this file except in compliance with the License. You may obtain a copy
of the License at
L<http://joinup.ec.europa.eu/software/page/eupl>

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

=cut

