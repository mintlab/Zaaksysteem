package Zaaksysteem::DB::Component::ZaaktypeKenmerken;

use strict;
use warnings;

use Zaaksysteem::Constants qw/ZAAKSYSTEEM_CONSTANTS/;

#use Moose;

use base qw/DBIx::Class/;

sub added_columns {
    return [qw/
        naam
        type
        options
    /];
}

sub options {
    my ($self) = @_;

    if ($self->bibliotheek_kenmerken_id) {
        return $self->bibliotheek_kenmerken_id->options;
    }
}

sub naam {
    my $self    = shift;

    if ($self->bibliotheek_kenmerken_id) {
        return $self->bibliotheek_kenmerken_id->naam;
    }
}

sub type {
    my $self    = shift;

    if ($self->bibliotheek_kenmerken_id) {
        return $self->bibliotheek_kenmerken_id->value_type;
    }
}

sub label {
    my $self    = shift;

    ### Make sure we write
    return $self->next::method(@_) if @_;

    ### Show label when exists
    return $self->next::method
        if $self->next::method;

    if ($self->bibliotheek_kenmerken_id) {
        return $self->bibliotheek_kenmerken_id->label;
    }
}

sub magic_string {
    my $self    = shift;

    if ($self->bibliotheek_kenmerken_id) {
        return $self->bibliotheek_kenmerken_id->magic_string;
    }
}

sub description {
    my $self    = shift;

    if ($self->bibliotheek_kenmerken_id) {
        return $self->bibliotheek_kenmerken_id->description;
    }
}

sub speciaal_kenmerk {
    my $self    = shift;

    if ($self->bibliotheek_kenmerken_id) {
        return $self->bibliotheek_kenmerken_id->speciaal_kenmerk;
    }
}

sub help {
    my $self    = shift;

    ### Make sure we write
    return $self->next::method(@_) if @_;

    ### Show label when exists
    return $self->next::method
        if $self->next::method;

    if ($self->bibliotheek_kenmerken_id) {
        return $self->bibliotheek_kenmerken_id->help;
    }
}

sub kenmerken_categorie {
    my $self    = shift;

    if ($self->bibliotheek_kenmerken_id) {
        return $self->bibliotheek_kenmerken_id->document_categorie;
    }

    return;
}

sub rtkey {
    my $self    = shift;

    return unless (
        $self->bibliotheek_kenmerken_id &&
        $self->bibliotheek_kenmerken_id->id
    );

    return 'kenmerk_id_' . $self->bibliotheek_kenmerken_id->id;
}

sub verplicht {
    my $self    = shift;

    return 1 if $self->value_mandatory;

    return;
}


sub default_value {
    my $self = shift;

    # If there is an update to the column, we'll let the original accessor
    # deal with it.
    return $self->value_default(@_) if @_;

    # Fetch the column value.
    my $value_default = $self->value_default;

    # If there's something in the description field, then just return that.
    return $value_default if defined $value_default && length $value_default;

    # Otherwise, get the default value from the bibliotheek_kenmerken table
    my $bib_row = $self->bibliotheek_kenmerken_id();

    if (defined $bib_row) {
       return $bib_row->value_default;
    }
}


1;
