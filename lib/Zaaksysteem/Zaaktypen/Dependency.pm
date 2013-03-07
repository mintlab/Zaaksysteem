package Zaaksysteem::Zaaktypen::Dependency;

use strict;
use warnings;

use Params::Profile;
use Data::Dumper;

use Moose;
use namespace::autoclean;
use Clone qw(clone);
use Carp qw(cluck);



has [qw/solution keyname ancestry_hash name id bibliotheek_categorie_id/] => (
    'is'    => 'rw',
);




#
# ancestry is the tree location of an item. we need it to manipulate the zaaktype structure
# to inform it of the new id for the dependency.
#
# say we received id = 302 for kenmerk 'aantal kinderen'. in the local zaaksysteem this kenmerk
# is already present, but with id = 511. so every instance where kenmerk 502 was used
# now a reference has to be made to kenmerk 511. ancestry_hash contains the locations where
# these references were made
#
sub add_ancestry {
    my ($self, $ancestry, $key) = @_;

    $self->ancestry_hash({}) unless ref $self->ancestry_hash;
    
    my $clone_ancestry = clone($ancestry);

    push @$clone_ancestry, $key;
    my $joined = join ",", @$clone_ancestry;

    $self->ancestry_hash->{$joined} ||= $clone_ancestry;
    
#    warn Dumper $self->ancestry_hash;
}

sub remove_solution {
    my ($self) = @_;
    
    $self->solution(undef);
}



#
# return references to the tree items that need modification
#
sub sub_items {
    my ($self, $zaaktype) = @_;

    my $ancestry_hash = clone $self->ancestry_hash;
    
    unless($ancestry_hash) {
        warn "no ancestry list found!";
        return [];
    }

    my $sub_items = [];

    foreach my $ancestry (values %$ancestry_hash) {
        die "ancestry list empty" unless @$ancestry;
        # track back to the proper tree leaf    

        my $sub_item = $zaaktype;
        my $key_name = pop @$ancestry;
        foreach my $ancestor (@$ancestry) {
            $sub_item = $sub_item->{$ancestor};
        }
        push @$sub_items, {
            sub_item => $sub_item, 
            key_name => $key_name
        };
    }

    return $sub_items;
}



__PACKAGE__->meta->make_immutable;

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

