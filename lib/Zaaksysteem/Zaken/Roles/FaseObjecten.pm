package Zaaksysteem::Zaken::Roles::FaseObjecten;

use Moose::Role;
use Data::Dumper;


sub zaak_cache {
    my $self            = shift;
    my $caching_object  = shift;

    my $calling_sub     = [ caller(1) ]->[3];

    if ($caching_object) {
        $self->{_zaak_cache} = {} unless
            $self->{_zaak_cache};

        return ($self->{_zaak_cache}->{$calling_sub} = $caching_object);
    }

    return unless $self->{_zaak_cache};

    return $self->{_zaak_cache}->{$calling_sub}
        if $self->{_zaak_cache}->{$calling_sub};

    return;
}

sub flush_cache {
    my $self            = shift;

    return unless $self->{_zaak_cache};

    delete($self->{_zaak_cache});
}

sub set_fase {
    my $self        = shift;
    my $milestone   = shift;

    return unless $milestone;

    $self->milestone($milestone);
    $self->flush_cache;
    $self->update;
}


sub set_volgende_fase {
    my $self            = shift;

    my $volgende_fase   = $self->volgende_fase;

    return unless $volgende_fase;

    return unless $self->can_volgende_fase;

    $self->set_fase($volgende_fase->status) or return;

    if ($self->is_afhandel_fase) {
        $self->set_gesloten;
    }

    $self->flush_cache;
    return 1;
}


sub set_vorige_fase {
    my $self            = shift;

    my $vorige_fase     = $self->vorige_fase;

    return unless $vorige_fase;

    return unless $self->can_vorige_fase;

    if ( $self->is_afgehandeld) {
        $self->set_heropen;
    }

    $self->flush_cache;
    $self->set_fase($vorige_fase->status);
}

sub set_heropen {
    my $self            = shift;

    if ($self->status ne 'resolved') {
        return;
    }

    $self->status               ('open');
    $self->afhandeldatum        (undef);
    $self->vernietigingsdatum   (undef);

    $self->logging->add({
        component   => 'zaak',
        onderwerp   => 'Zaak heropend'
    });

    $self->flush_cache;
    $self->update;
}



sub set_gesloten {
    my  $self   = shift;
    my  $time   = shift;

    $time       ||= DateTime->now;

    $self->afhandeldatum        ($time);

    ### Get vernietigingsdatum
    $self->set_vernietigingsdatum;

    $self->status('resolved');
    $self->flush_cache;

    $self->logging->add({
        component   => 'zaak',
        onderwerp   => 'Zaak gesloten op '
            . $time->dmy . ' ' . $time->hms
    });
    $self->update;
}

sub set_vernietigingsdatum {
    my  $self   = shift;

    my  $time   = $self->afhandeldatum;

    ### Afhandeldatum?
    return unless $time;

    $time       = $time->clone();

    ### Geen resultaat: 1 year default
    unless ($self->resultaat) {
        return $self->vernietigingsdatum($time->add('years'  => 1));
    }

    my $resultaten  = $self->zaaktype_node_id
        ->zaaktype_resultaten
        ->search;

    while (my $resultaat = $resultaten->next) {
        unless ( lc($resultaat->resultaat) eq lc($self->resultaat) ) {
            next;
        }

        my $dt      = $time->set_time_zone('Europe/Amsterdam');

        $dt->add('days' => $resultaat->bewaartermijn);

        if ($dt ne $self->vernietigingsdatum) {
            $self->vernietigingsdatum($dt);

            $self->logging->add({
                component   => 'zaak',
                onderwerp   => 'Vernietigingsdatum gewijzigd: '
                    . $time->dmy
            });
        }
    }
}


sub fasen {
    my $self    = shift;

    return $self->zaaktype_node_id->zaaktype_statussen(
        undef,
        {
            order_by    => { -asc   => 'status' }
        }
    );
}


sub huidige_fase {
    my $self    = shift;

    return $self->zaak_cache if $self->zaak_cache;

    return $self->zaak_cache($self->zaaktype_node_id->zaaktype_statussen->search(
        status  => $self->milestone,
    )->first);
}


sub volgende_fase {
    my $self    = shift;

    return $self->zaak_cache if $self->zaak_cache;

    return $self->zaak_cache($self->zaaktype_node_id->zaaktype_statussen->search(
        status  => ($self->milestone + 1)
    )->first);
}


sub vorige_fase {
    my $self    = shift;

    return $self->zaak_cache if $self->zaak_cache;

    return $self->zaak_cache($self->zaaktype_node_id->zaaktype_statussen->search(
        status  => ($self->milestone - 1)
    )->first);
}


sub registratie_fase {
    my $self    = shift;

    return $self->zaak_cache($self->zaaktype_node_id->zaaktype_statussen->search(
        undef,
        {
            order_by    => { -asc => 'status' },
            rows        => 1,
        }
    )->first)
}


sub afhandel_fase {
    my $self    = shift;

    return $self->zaak_cache if $self->zaak_cache;

    return $self->zaak_cache($self->zaaktype_node_id->zaaktype_statussen->search(
        undef,
        {
            order_by    => { -desc => 'status' },
            rows        => 1,
        }
    )->first);
}


sub is_afhandel_fase {
    my $self    = shift;

    if ($self->afhandel_fase->status eq $self->huidige_fase->status) {
        return 1;
    }

    return;
}

sub is_afgehandeld {
    my $self    = shift;

    return 1 if ($self->status eq 'resolved');

    if ($self->afhandel_fase->status eq $self->milestone) {
        return 1;
    }

    return;
}


sub is_open {
    my $self    = shift;

    return 1 if ($self->status =~ /new|open/);
    return;
}



sub is_volgende_afhandel_fase {
    my $self    = shift;

    return unless $self->volgende_fase;

    if ($self->afhandel_fase->status eq $self->volgende_fase->status) {
        return 1;
    }

    return;
}



sub can_volgende_fase {
    my $self    = shift;

    if ($self->is_volgende_afhandel_fase && !$self->resultaat){
        return;
    }

    return 1;
}

sub can_vorige_fase {
    my $self    = shift;

    return 1;
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

