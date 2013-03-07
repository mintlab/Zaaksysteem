package Zaaksysteem::Model::Zaaktype::General;

use strict;
use warnings;

use Date::Calendar;
use Date::Calendar::Profiles qw/$Profiles/;
use DateTime;
use Data::Dumper;


use POSIX qw/ceil/;

use Zaaksysteem::Constants qw/
    ZAAKTYPE_KENMERKEN_ZTC_DEFINITIE
    ZAAKSYSTEEM_NAMING

    ZAAKSYSTEEM_GM_AUTHENTICATEDBY_BEHANDELAAR

    ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_HIGH
    ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_MEDIUM
/;


sub create_zaak {
    my $self                            = shift;
    my $zaak_nr                         = shift;
    my ($definitie, $args)              = @_;

    my $zaak    = $self->c->model('Zaak')->get($zaak_nr);

    $zaak->in_update(1);
    $self->_load_datums($zaak, @_);
    $self->_calculate_dates($zaak, @_);
    $self->_load_route($zaak, @_);
    $self->_load_ztc($zaak, @_);
    $self->_load_verificatie($zaak,@_);

#    $self->_load_acties($zaak, @_);

    return $zaak;
}

sub _load_acties {
    my ($self, $zaak, $definitie, $args) = @_;

}

sub _load_verificatie {
    my ($self, $zaak, $definitie, $args) = @_;

    if ($self->c->user_exists) {
        $zaak->kenmerk->aanvrager_verificatie(ZAAKSYSTEEM_GM_AUTHENTICATEDBY_BEHANDELAAR);
    } else {
        if ($self->c->stash->{webform_authenticatie_valid}) {
            $zaak->kenmerk->aanvrager_verificatie(
                ucfirst($self->c->stash->{webform_authenticatie_valid})
            );
        } else {
            $zaak->kenmerk->aanvrager_verificatie('Geen');
        }
    }
}

sub _load_datums {
    my ($self, $zaak, $definitie, $args) = @_;

    my $now = $args->{start_time} || time;

    ### DATE's
    {
        ### Datum van registratie
        $zaak->kenmerk->registratiedatum($now);

        ### Streefbare afhandeling
        $zaak->kenmerk->streefafhandeldatum(
            $self->_load_zaaktype_timing(
                $now,
                $definitie->definitie->servicenorm,
                $definitie->definitie->servicenorm_type
            )
        );

        ### Servicegerichte afhandeling
        $zaak->kenmerk->servicenorm(
                $definitie->definitie->servicenorm
        );

        $zaak->kenmerk->servicenorm_type(
                $definitie->definitie->servicenorm_type
        );

        ### Vernietigingsdatum
        #my $afhandeldatum = $zaak->kenmerk->streefafhandeldatum;
        #$afhandeldatum->add('years' => 3);

        #
        #$zaak->kenmerk->vernietigingsdatum(
        #    $afhandeldatum->epoch
        #);


    }
}

sub _calculate_dates {
    my ($self, $zaak, $definitie, $args) = @_;

    my $now = $zaak->kenmerk->registratiedatum->epoch;

    ### Calculate Urentie data
    {
        my $time_diff       = ($zaak->kenmerk->streefafhandeldatum->epoch - $now);

        my $urgent_high     = ceil(
            ($zaak->kenmerk->streefafhandeldatum->epoch - ($time_diff * ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_HIGH))
        );

        my $urgent_medium   = ceil(
            ($zaak->kenmerk->streefafhandeldatum->epoch - ($time_diff * ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_MEDIUM))
        );

        $zaak->kenmerk->urgentiedatum_medium(
            $urgent_medium
        );
        $zaak->kenmerk->urgentiedatum_high(
            $urgent_high
        );

    }
}

sub _load_zaaktype_timing {
    my ($self, $now, $addtime, $addtime_type) = @_;
    my ($newdate);

    my $dt = DateTime->from_epoch(epoch => $now);

    # TEST:
    # perl -MDate::Calendar -e 'use Date::Calendar::Profiles qw/$Profiles/; use Date::Calc::Object; $calendar = Date::Calendar->new($Profiles->{"NL"});$date  = Date::Calc->gmtime(time); my $calcdate    = $calendar->add_delta_workdays(Date::Calc->gmtime(time), 6); print $calcdate->day'
    if ($addtime_type eq ZAAKSYSTEEM_NAMING->{TERMS_TYPE_WERKDAGEN}) {
        my $calendar    = Date::Calendar->new($Profiles->{"NL"});
        my $startdate   = Date::Calc->localtime($now);
        my $calcdate    = $calendar->add_delta_workdays(
            $startdate,
            ($addtime)
        );
        $newdate        = ($calcdate->mktime+86400);	# + 1, it would calculate from
    } elsif ($addtime_type eq ZAAKSYSTEEM_NAMING->{TERMS_TYPE_KALENDERDAGEN}) {
        $dt->add(days   => $addtime);
        $newdate    = $dt->epoch;
    } elsif ($addtime_type eq ZAAKSYSTEEM_NAMING->{TERMS_TYPE_WEKEN}) {
        $dt->add(weeks   => $addtime);
        $newdate    = $dt->epoch;
    } elsif ($addtime_type eq ZAAKSYSTEEM_NAMING->{TERMS_TYPE_EINDDATUM}) {
        my ($day, $month, $year) = $addtime =~ /^(\d{2})-(\d{2})-(\d{4})$/;
        $dt = DateTime->new(
            year    => $year,
            month   => $month,
            day     => $day
        );

        $newdate    = $dt->epoch;
    }
warn "######################################newdata: " . Dumper $newdate;
    return $newdate;
}

sub _load_route {
    my ($self, $zaak, $definitie, $args) = @_;

    ### Engage routing
    my %route_args = (
        status => 1,
    );

    $route_args{ou_id} = $args->{ou_id}
        if $args->{ou_id};
    $route_args{role_id} = $args->{role_id}
        if $args->{role_id};

    $zaak->zaakstatus->set_route(%route_args);

    return 1;
}

sub _load_ztc {
    my ($self, $zaak, $definitie, $args) = @_;

    ### STATUS
    {
        $zaak->kenmerk->status(1);
    }

    ### Sort convenient methods
    {
        my $rt_fields = ZAAKTYPE_KENMERKEN_ZTC_DEFINITIE;

        # RT ONLY
        $zaak->kenmerk->zaaktype_id($definitie->id);
        $zaak->kenmerk->zaaktype_nid($definitie->nid);
        $zaak->kenmerk->zaaktype_code($definitie->code);
        $zaak->kenmerk->zaaktype_naam($definitie->titel);

        $zaak->kenmerk->categorie_naam(
            ($definitie->categorie->can('categorie') ? 
                $definitie->categorie->categorie :
                $definitie->categorie->naam
            )
        );
        $zaak->kenmerk->categorie_id($definitie->categorie->id);

        for my $field (@{ $rt_fields }) {
            next if ($field->{in_rt_only});

            my $key = $field->{naam};

            if ($field->{in_node}) {
                $zaak->kenmerk->$key($definitie->$key);
            } else {
                $zaak->kenmerk->$key($definitie->definitie->$key)
                    if $definitie->definitie->$key;
            }
        }
    }

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

