package Zaaksysteem::Zaken::ComponentZaak;

use strict;
use warnings;

use Moose;

use Data::Dumper;

use Date::Calendar;
use Date::Calendar::Profiles qw/$Profiles/;
use DateTime;

use Zaaksysteem::Constants qw/
    ZAAKSYSTEEM_NAMING
    ZAAKSYSTEEM_STANDAARD_KENMERKEN
    ZAAKSYSTEEM_STANDAARD_KOLOMMEN

    ZAAK_WIJZIG_VERNIETIGINGSDATUM_PROFILE
/;

extends 'DBIx::Class';

with
    'Zaaksysteem::Zaken::Roles::MetaObjecten',
    'Zaaksysteem::Zaken::Roles::BetrokkenenObjecten',
    'Zaaksysteem::Zaken::Roles::FaseObjecten',
    'Zaaksysteem::Zaken::Roles::DocumentenObjecten',
    'Zaaksysteem::Zaken::Roles::DeelzaakObjecten',
    'Zaaksysteem::Zaken::Roles::KenmerkenObjecten',
    'Zaaksysteem::Zaken::Roles::RouteObjecten',
    'Zaaksysteem::Zaken::Roles::ChecklistObjecten';

use constant RELATED_OBJECTEN => {
    'fasen'     => 'Fasen',
    'voortgang' => 'Voortgang',
    'sjablonen' => 'Sjablonen',
    'locaties'  => 'Locaties',
    'acties'    => 'Acties'
};



sub nr  {
    my $self    = shift;

    $self->id( @_ );
}

sub set_resultaat {
    my $self            = shift;

    my $oudresultaat    = $self->resultaat;
    my $result          = $self->resultaat(@_);

    if (@_) {
        $self->set_vernietigingsdatum;
    }

    $self->logging->add({
        component   => 'zaak',
        onderwerp   => 'Resultaat gewijzigd van "'
            . $oudresultaat . '" naar "'
            . $self->resultaat . '"'
    });

    $self->update;
}


sub zaaktype_definitie {
    my $self    = shift;

    return $self->zaaktype_node_id->zaaktype_definitie_id;
}


sub systeemkenmerk {
    my $self    = shift;
    my $label   = shift;

    if (my ($kenmerk_id) = $label =~ /^kenmerk[\-_]id[\-_](\d+)$/) {
        my $kenmerk = $self->zaak_kenmerken->search(
            {
                bibliotheek_kenmerken_id    => $kenmerk_id
            }
        )->first;

        return unless $kenmerk;

        my $value = $kenmerk->value;

        ### Make sure we handle arrays correctly:
        my $replace_value;
        if (UNIVERSAL::isa($value, 'ARRAY')) {
            $replace_value = join(", \n", @{ $value });
        } else {
            $replace_value = $value
        }

        ### Make sure valuta get's showed correctly
        if ($kenmerk->bibliotheek_kenmerken_id->value_type =~ /valuta/) {
            $replace_value = sprintf('%01.2f', $replace_value);
            $replace_value =~ s/\./,/g;
        }

        ### Make sure we show bag items the 'correct' way
        if ($kenmerk->bibliotheek_kenmerken_id->value_type =~ /^bag/) {
            $replace_value = $self->c->model('Gegevens::Bag')
                ->bag_human_view_by_id($replace_value);
        }

        return $replace_value;
    }
    die "gimme label" unless $label;
    if (exists ZAAKSYSTEEM_STANDAARD_KOLOMMEN->{$label}) {
        return ZAAKSYSTEEM_STANDAARD_KOLOMMEN->{$label}->($self) || '';
    }

    unless (exists ZAAKSYSTEEM_STANDAARD_KENMERKEN->{$label}) {
        warn "need zaaksysteem_Standaard_kenmerken config ($label)";
        return '';
    }

    return ZAAKSYSTEEM_STANDAARD_KENMERKEN->{$label}->($self) || '';
}


sub status_perc {
    my $self            = shift;

    my $numstatussen    = $self->zaaktype_node_id->zaaktype_statussen->count;

    return 0 unless $numstatussen;

    return sprintf("%.0f", ($self->milestone / $numstatussen) * 100);
}


sub open_zaak {
    my $self    = shift;

    $self->status('open');

    my $current_user = $self->result_source
        ->schema
        ->resultset('Zaak')
        ->current_user;

    $self->logging->add({
        component   => 'zaak',
        onderwerp   => 'Zaak geaccepteerd door "'
            . $current_user->naam . '"'
    });

    unless ($self->behandelaar) {
        $self->set_behandelaar($current_user->betrokkene_identifier);
    }

    unless ($self->coordinator) {
        $self->set_coordinator($current_user->betrokkene_identifier);
    }

    $self->update;
}

sub set_verlenging {
    my $self    = shift;
    my $dt      = shift;

    $self->streefafhandeldatum($dt);
    $self->set_vernietigingsdatum;
    $self->update;
}


sub _bootstrap {
    my ($self, $opts)   = @_;

    $self->_bootstrap_datums($opts);
    $self->_bootstrap_route($opts);

    $self->update;
}



sub _load_zaaktype_timing {
    my ($self, $now, $addtime, $addtime_type) = @_;
    my ($newdate);

    my $dt = $now->clone;

    # TEST:
    # perl -MDate::Calendar -e 'use Date::Calendar::Profiles qw/$Profiles/; use Date::Calc::Object; $calendar = Date::Calendar->new($Profiles->{"NL"});$date  = Date::Calc->gmtime(time); my $calcdate    = $calendar->add_delta_workdays(Date::Calc->gmtime(time), 6); print $calcdate->day'
    if ($addtime_type eq ZAAKSYSTEEM_NAMING->{TERMS_TYPE_WERKDAGEN}) {
        my $calendar    = Date::Calendar->new($Profiles->{"NL"});
        my $startdate   = Date::Calc->localtime($now->epoch);
        my $calcdate    = $calendar->add_delta_workdays(
            $startdate,
            ($addtime)
        );
        $newdate        = ($calcdate->mktime+86400);	# + 1, it would calculate from
        $newdate        = DateTime->from_epoch(epoch => $newdate);
    } elsif ($addtime_type eq ZAAKSYSTEEM_NAMING->{TERMS_TYPE_KALENDERDAGEN}) {
        $dt->add(days   => $addtime);
        $newdate    = $dt;
    } elsif ($addtime_type eq ZAAKSYSTEEM_NAMING->{TERMS_TYPE_WEKEN}) {
        $dt->add(weeks   => $addtime);
        $newdate    = $dt;
    } elsif ($addtime_type eq ZAAKSYSTEEM_NAMING->{TERMS_TYPE_EINDDATUM}) {
        my ($day, $month, $year) = $addtime =~ /^(\d{2})-(\d{2})-(\d{4})$/;
        $dt = DateTime->new(
            year    => $year,
            month   => $month,
            day     => $day
        );

        $newdate    = $dt;
    }

    return $newdate;
}


sub _bootstrap_datums {
    my ($self, $opts)   = @_;

    my $now             = DateTime->now;

    ### Registratiedatum not set, default to now
    if ($opts->{registratiedatum}) {
        $self->registratiedatum(
            $opts->{registratiedatum}
        );
        $now    = $opts->{registratiedatum};
    } elsif (!$self->registratiedatum) {
        $self->registratiedatum($now);
    }

    ### Streefbare afhandeling
    if ($opts->{streefafhandeldatum}) {
        $self->streefafhandeldatum(
            $opts->{streefafhandeldatum}
        );
    } else {
        my ($norm, $type)   = (
            $self->zaaktype_node_id->zaaktype_definitie_id->servicenorm,
            $self->zaaktype_node_id->zaaktype_definitie_id->servicenorm_type
        );

        if ($opts->{streefafhandeldatum_data}) {
            $norm   = $opts->{streefafhandeldatum_data}->{termijn};
            $type   = $opts->{streefafhandeldatum_data}->{type};
        }

        $self->streefafhandeldatum(
            $self->_load_zaaktype_timing(
                $now,
                $norm,
                $type,
            )
        );
    }
}

sub insert {
    my $self    = shift;

    $self->_handle_changes({insert => 1});
    $self->next::method(@_);
}

sub update {
    my $self    = shift;
    my $columns = shift;

    $self->set_inflated_columns($columns) if $columns;
    $self->_handle_changes;
    $self->next::method(@_);
}

sub _handle_changes {
    my $self    = shift;
    my $opt     = shift;
    my $changes = {};

    if ($opt && $opt->{insert}) {
        $changes = { $self->get_columns };
        $changes->{_is_insert} = 1;
    } else {
        $changes = { $self->get_dirty_columns };
    }

    $self->{_get_latest_changes} = $changes;

    return 1;
}

after 'insert'  => sub {
    my $self    = shift;

    $self->_handle_logging;
    $self->touch(1);
};

after 'update'  => sub {
    my $self    = shift;

    $self->_handle_logging;
    $self->touch(1);
};

has 'prevent_touch' => (
    is      => 'rw',
);

sub touch {
    my $self            = shift;
    my $skip_modified   = shift;

    return 1;
    return 1 if $skip_modified;

    $self->last_modified(DateTime->now);
    $self->update;
}

sub set_deleted {
    my $self            = shift;

    $self->status('deleted');
    $self->deleted(DateTime->now);
    $self->update;
}


sub _get_latest_changes {
    my $self    = shift;

    return $self->{_get_latest_changes};
}

sub _handle_logging {}

sub duplicate {
    my $self    = shift;
    $self->result_source->schema->resultset('Zaak')->duplicate( $self, @_ );
}

sub wijzig_zaaktype {
    my $self    = shift;
    $self->result_source->schema->resultset('Zaak')->wijzig_zaaktype($self, @_);
}

Params::Profile->register_profile(
    'method'    => 'wijzig_vernietigingsdatum',
    'profile'   => ZAAK_WIJZIG_VERNIETIGINGSDATUM_PROFILE,
);

sub wijzig_vernietigingsdatum {
    my $self        = shift;
    my $opts        = shift;

    my $dv          = Params::Profile->check(params => $opts);

    die('Parameters incorrect:' . Dumper($opts)) unless $dv->success;

    $self->vernietigingsdatum($opts->{vernietigingsdatum});

    if ($self->update) {
        my $logmsg = 'Vernietigingsdatum voor zaak: "' .
            $self->id . '"'
            .' gewijzigd naar: ' .
            $opts->{vernietigingsdatum}->dmy;

        $self->logging->add(
            {
                component   => 'zaak',
                onderwerp   => $logmsg,
            }
        );
    }
}

1; #__PACKAGE__->meta->make_immutable;


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

