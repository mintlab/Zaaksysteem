package Zaaksysteem::Zaken::Roles::DeelzaakObjecten;

use Moose::Role;
use Data::Dumper;


sub heeft_incomplete_deelzaken {
    my $self    = shift;
}

sub set_relatie {
    my $self    = shift;
    my $opts    = shift;


    die('Missing arguments') unless (
        $opts->{relatie} &&
        $opts->{relatie_zaak}
    );

    my  $relatie_zaak   = $opts->{relatie_zaak};

    if (!ref($opts->{relatie_zaak})) {
        die('Geen zaak_id of geen nummer') unless (
            $opts->{relatie_zaak} &&
            $opts->{relatie_zaak} =~ /^\d+$/
        );

        $relatie_zaak   = $self->result_source
            ->schema
            ->resultset('Zaak')
            ->find($opts->{relatie_zaak})
            or die('Zaak kan niet gevonden worden');
    }

    if ($opts->{relatie} && $opts->{relatie} eq 'gerelateerd') {
        $self->relates_to($relatie_zaak->id);
    }

    if ($opts->{relatie} && $opts->{relatie} eq 'vervolgzaak') {
        $self->vervolg_van($relatie_zaak->id);
    }

    if ($opts->{relatie} && $opts->{relatie} eq 'deelzaak') {
        $self->pid($relatie_zaak->id);
    }


    if ($opts->{'actie_kopieren_kenmerken'}) {
        my $kenmerken       = $relatie_zaak->zaak_kenmerken->search_all_kenmerken;

        # Self = the newly created zaak. Kenmerken from the relatie_zaak need to be copied

        if (scalar(keys %{ $kenmerken })) {
            while (my ($kenmerk_id, $kenmerk_value) = each %{ $kenmerken }) {
                $self->zaak_kenmerken->create_kenmerk({
                    zaak_id                     => $self->id,
                    bibliotheek_kenmerken_id    => $kenmerk_id,
                    values                      => $kenmerk_value,
                });
            }
        }
    }

    $self->update;
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

