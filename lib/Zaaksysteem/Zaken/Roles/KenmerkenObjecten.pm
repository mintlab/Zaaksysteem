package Zaaksysteem::Zaken::Roles::KenmerkenObjecten;

use Moose::Role;
use Data::Dumper;


# commented out because the only place this is used is in the sub below
# sub is_kenmerken_compleet {
#     my $self    = shift;
# 
#     my $fasen   = $self->zaaktype_node_id
#         ->zaaktype_statussen
#         ->search(
#             status  => $self->volgende_fase->status
#         );
# 
#     my $fase    = $fasen->first or return;
# 
#     my $kenmerken = $fase->zaaktype_kenmerken->search(
#         {
#             'me.value_mandatory'    => 1,
#         },
#         {
#             prefetch                => 'bibliotheek_kenmerken_id'
#         }
#     );
# 
#     my $error   = 0;
# 
#     while (my $kenmerk    = $kenmerken->next) {
#         next unless (
#             $kenmerk->bibliotheek_kenmerken_id &&
#             $kenmerk->bibliotheek_kenmerken_id->value_type ne 'file'
#         );
# 
#         my $antwoorden  = $self->zaak_kenmerken->search(
#             bibliotheek_kenmerken_id  => $kenmerk->bibliotheek_kenmerken_id->id
#         );
# 
#         my $antwoord    = $antwoorden->first;
# 
# 
#         unless ($antwoord) {
#             $error      = 1;
#             next;
#         }
# 
#         if ($antwoord->has_empty_value) {
#             $error      = 1;
#         }
#     }
# 
#     return 1 unless $error;
#     return;
# }

### Commented out because this sub does not take Regels into account (hidden
### kenmerken which are required

#around 'can_volgende_fase' => sub {
#    my $orig    = shift;
#    my $self    = shift;
#
#    return unless $self->$orig(@_);
#
#    if (!$self->is_kenmerken_compleet) {
#        return;
#    }
#
#    return 1;
#};


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

