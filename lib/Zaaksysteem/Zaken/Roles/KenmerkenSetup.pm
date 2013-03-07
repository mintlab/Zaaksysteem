package Zaaksysteem::Zaken::Roles::KenmerkenSetup;

use Moose::Role;
use Data::Dumper;

around '_create_zaak' => sub {
    my $orig                = shift;
    my $self                = shift;
    my ($opts)              = @_;
    my ($zaak_kenmerken);

    my $zaak = $self->$orig(@_);


    if ($opts->{kenmerken}) {
        $self->log->debug('Voeg registratie kenmerken toe');

        $zaak->zaak_kenmerken->create_kenmerken({
            zaak_id     => $zaak->id, 
            kenmerken   => $opts->{kenmerken}
        });

        $zaak_kenmerken  = $zaak->zaak_kenmerken->search;
    }

    $self->log->debug('Trace default_value kenmerken');

    my $kenmerken_opts = {
        'me.bibliotheek_kenmerken_id'               => { 'is not'   => undef },
        'bibliotheek_kenmerken_id.value_default'    => { 'is not'   => undef },
    };

    if ($zaak_kenmerken) {
        $kenmerken_opts->{'bibliotheek_kenmerken_id'} = { 'not in'   =>
            $zaak_kenmerken->get_column('bibliotheek_kenmerken_id')->as_query
        };
    }

    my $kenmerken   = $zaak->zaaktype_node_id->zaaktype_kenmerken->search(
        $kenmerken_opts,
        {
            prefetch    => 'bibliotheek_kenmerken_id',
            join        => 'bibliotheek_kenmerken_id'
        }
    );

# Default values are set from Controller/Form.pm
#    while (my $kenmerk  = $kenmerken->next) {
#        my $zaak_kenmerk = $zaak->zaak_kenmerken->by_bibliotheek_id(
#            $kenmerk->bibliotheek_kenmerken_id->id
#        );
#
#        $zaak_kenmerk->set_value($kenmerk->bibliotheek_kenmerken_id->value_default);
#    }

    $self->log->debug('Kenmerken toegevoegd');
    return $zaak;
};

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

