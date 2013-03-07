package Zaaksysteem::DB::Component::ZaaktypeChecklist;

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

sub mogelijkheden {
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

    ### Make sure we write
    return $self->next::method(@_) if @_;

    ### Show label when exists
    return $self->next::method
        if $self->next::method;

    if ($self->bibliotheek_kenmerken_id) {
        return $self->bibliotheek_kenmerken_id->description;
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

sub document_categorie {
    my $self    = shift;

    ### Make sure we write
    return $self->next::method(@_) if @_;

    ### Show label when exists
    return $self->next::method
        if $self->next::method;

    if ($self->bibliotheek_kenmerken_id) {
        return $self->bibliotheek_kenmerken_id->document_categorie;
    }
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

1;
