package Zaaksysteem::Zaken::Roles::BetrokkenenSetup;

use Moose::Role;
use Data::Dumper;

with 'Zaaksysteem::Zaken::Betrokkenen';

around '_create_zaak' => sub {
    my $orig            = shift;
    my $self            = shift;
    my ($opts)          = @_;

    my %update = ();
    for my $betrokkene_target (qw/aanvrager behandelaar coordinator/) {
        my $betrokkene_target_p = $betrokkene_target . 's'; # PLURAL
        next unless $opts->{$betrokkene_target_p};

        unless (
            $opts->{$betrokkene_target_p} &&
            UNIVERSAL::isa($opts->{$betrokkene_target_p}, 'ARRAY')
        ) {
            $self->log->error(
                'Geen aanvragers meegegeven of aanvragers != ARRAY'
            );

            return;
        }

        for my $betrokkene (@{ $opts->{ $betrokkene_target_p } }) {
            my $rv = $self->betrokkene_set($opts, $betrokkene_target, $betrokkene);

            if ($rv) {
                $update{$betrokkene_target} = {
                    id              => $rv,
                    verificatie     => $betrokkene->{verificatie}
                }

            }
        }
    }

    my $zaak = $self->$orig(@_);

    while (my ($betrokkene_target, $betrokkene_info) = each %update) {
        my $betrokkene = $self->result_source->schema->resultset('ZaakBetrokkenen')->find(
            $betrokkene_info->{id}
        );

        $betrokkene->zaak_id($zaak->id);
        $betrokkene->verificatie($betrokkene_info->{verificatie});
        $betrokkene->update;
    }

    unless ($zaak->aanvrager) {
        die('Geen aanvrager voor zaak, is toch echt verplicht');
    }

    $self->_betrokkene_setup_add_relaties(
        $zaak, $opts
    );

    return $zaak;
};

sub _betrokkene_setup_add_relaties {
    my ($self, $zaak, $opts) = @_;

    if ($opts->{betrokkene_relaties}) {
        for my $relatie (
            @{ $opts->{betrokkene_relaties} }
        ) {
            $zaak->betrokkene_relateren(
                $relatie
            );
        }
    }

    if ($opts->{ontvanger}) {
        $zaak->betrokkene_relateren(
            {
                betrokkene_identifier   => $opts->{ontvanger},
                rol                     => 'Ontvanger',
                magic_string_prefix     => 'ontvanger',
            }
        );
    }

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

