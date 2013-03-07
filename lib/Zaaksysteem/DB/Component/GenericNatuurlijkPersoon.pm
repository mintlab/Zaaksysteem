package Zaaksysteem::DB::Component::GenericNatuurlijkPersoon;

use strict;
use warnings;
use Data::Dumper;

use base qw/DBIx::Class/;

sub in_onderzoek {
    my $self    = shift;

    my @checks = grep( { $_ =~ /^onderzoek_.*?_ingang/ } $self->columns);

    my @failures;
    for my $check (@checks) {
        my $categorie   = $check;
        $categorie      =~ s/onderzoek_(.*?)_ingang/$1/;

        my $ingang      = 'onderzoek_' . $categorie . '_ingang';
        my $einde       = 'onderzoek_' . $categorie . '_einde';
        my $inonderzoek = 'onderzoek_' . $categorie;

        if ($self->$inonderzoek && $self->$ingang && !$self->$einde) {
            push(@failures, $categorie);
        }
    }

    return \@failures if scalar(@failures);
    return;
}

sub is_overleden {
    my $self    = shift;

    return 1 if $self->datum_overlijden;
    return;
}

1;
