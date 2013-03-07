package Zaaksysteem::Model::Bibliotheek::Kenmerken;

use strict;
use warnings;
use Zaaksysteem::Constants qw/
    ZAAKSYSTEEM_CONSTANTS
    PARAMS_PROFILE_DEFAULT_MSGS
/;

use parent 'Catalyst::Model';

use Data::Dumper;

use constant KENMERKEN              => 'kenmerken';
use constant MAGIC_STRING_DEFAULT   => 'doc_variable';
use constant KENMERKEN_DB           => 'DB::BibliotheekKenmerken';
use constant KENMERKEN_OPTIONS_DB   => 'DB::BibliotheekKenmerkenValues';

use constant KENMERKEN_DB_MAP       => {


};

use Moose;

has 'c' => (
    is  => 'rw',
);

sub generate_magic_string {
    my ($self, $suggestion) = @_;
    my $suggestion_ok       = 0;
    my $suggestion_counter  = 0;

    $suggestion             = lc($suggestion);

    ### Replace suggestion
    $suggestion             =~ s/ /_/g;
    $suggestion             =~  s/[^\w0-9_]//g;

    if (!$suggestion) {
        $suggestion = MAGIC_STRING_DEFAULT . ++$suggestion_counter;
    }

    ### Search database for given suggestion
    while (!$suggestion_ok) {
        my $rv = $self->c->model(KENMERKEN_DB)->search({
            magic_string    => $suggestion,
        });

        $self->c->log->debug('Search suggestion');

        if (!$rv->count) {
            $suggestion_ok  = 1;
        } else {
            $self->c->log->debug('Suggestion taken, new one');
            if ($suggestion_counter > 0) {
                $suggestion =~ s/$suggestion_counter$//;
            }
            $suggestion     .= ++$suggestion_counter;
        }
    }

    return $suggestion;
}

{
    Zaaksysteem->register_profile(
        method  => 'bewerken',
        profile => {
            required => [ qw/
                kenmerk_naam
                kenmerk_type
                bibliotheek_categorie_id
            /],
            optional => [ qw/
                id
                kenmerk_help
                kenmerk_value_default
                kenmerk_magic_string
                kenmerk_options
                kenmerk_document_categorie
                kenmerk_type_multiple
            /],
            missing_optional_valid => 1,
            dependencies        => {
                'kenmerk_type'   => sub {
                    my ($dfv, $value) = @_;

                    if (
                        $value &&
                        exists(ZAAKSYSTEEM_CONSTANTS->{veld_opties}->{
                                $value
                        }->{multiple}) &&
                        ZAAKSYSTEEM_CONSTANTS->{veld_opties}->{
                            $value
                        }->{multiple}
                    ) {
                        return [ 'kenmerk_options' ];
                    }

                    return [];
                },
            },
            constraint_methods  => {
                kenmerk_magic_string    => qr/^[\w0-9_]+$/,
                kenmerk_naam            => qr/^.{2,64}$/,
            },
            field_filters       => {
                kenmerk_options => sub {
                    my ($field) = @_;

                    return $field unless $field;

                    return [ split("\n", $field) ];
                },
                kenmerk_type_multiple => sub {
                    my ($field) = @_;
                    
                    return $field ? 1 : 0;
                },
            },
            msgs                => PARAMS_PROFILE_DEFAULT_MSGS,
        }
    );

    sub bewerken {
        my ($self, $params) = @_;

        my $dv = $self->c->check(
            params  => $params,
        );
        return unless $dv->success;

        ### Magic string check
        return if (
            !$params->{id} &&
            (
                !$params->{kenmerk_magic_string} ||
                $params->{kenmerk_magic_string} ne
                $self->generate_magic_string(
                    $params->{kenmerk_magic_string}
                )
            )
        );

        $self->c->log->debug('Trying to create kenmerk');

        my $valid_options = $dv->valid;

        ### Rewrite some values
        my %options = map {
            my $key = $_;
            $key =~ s/^kenmerk_//;
            $key => $valid_options->{ $_ }
        } keys %{ $valid_options };

        $options{value_type} = $options{type};
        delete($options{type});

        ### Delete options from options
        my $kenmerk_options;
        if (
            $options{options} &&
            exists(ZAAKSYSTEEM_CONSTANTS->{veld_opties}->{
                    $options{value_type}
            }->{multiple})
        ) {
            $kenmerk_options = $options{options};
        }
        delete($options{options});

        ### Ram er maar in
        delete($options{id}) unless $options{id};

        my $kenmerk = $self->c->model(KENMERKEN_DB)->update_or_create(\%options);

        return unless $kenmerk;

        if ($kenmerk_options) {
            if ($options{id}) {
                # Delete old options
                $kenmerk->bibliotheek_kenmerken_values->delete;
            }
            for my $kenmerk_option (@{ $kenmerk_options }) {
                $kenmerk_option = $kenmerk_option->[0];
                $kenmerk_option =~ s/\r|\n//;
                $self->c->model(KENMERKEN_OPTIONS_DB)->create({
                    bibliotheek_kenmerken_id    => $kenmerk->id,
                    value                       => $kenmerk_option,
                });
            }
        }

        return $kenmerk;
    }
}

sub get {
    my ($self, %opt) = @_;
    my %rv;

    return unless defined($opt{id}) && $opt{id};


    my $kenmerk         = $self->c->model(KENMERKEN_DB)->find($opt{id})
                            or return;

    my @rv_map;
    {
        my $edit_profile    = $self->c->get_profile(
            'method'=> 'bewerken',
            'caller' => __PACKAGE__
        ) or return;

        @rv_map = @{ $edit_profile->{optional} };

        if ($edit_profile->{required}) {
            push(@rv_map, @{ $edit_profile->{required} });
        }
    }

    if (
        exists(ZAAKSYSTEEM_CONSTANTS->{veld_opties}->{
            $kenmerk->value_type
        }->{multiple}) &&
        ZAAKSYSTEEM_CONSTANTS->{veld_opties}->{
            $kenmerk->value_type
        }->{multiple}
    ) {
        my $values = $kenmerk->bibliotheek_kenmerken_values->search(
            {},
            {
                    order_by    => { -asc   => 'id' },
            }
        );
        $rv{kenmerk_options} = [];
        while (my $value = $values->next) {
            push(@{ $rv{kenmerk_options} }, $value->value);
        }
    }

    for my $key (@rv_map) {
        if ($key eq 'kenmerk_options') { next; }
        my $dbkey   = $key;

        $dbkey =~ s/^kenmerk_//g;
        if ($dbkey eq 'type') { $dbkey = 'value_type'; }
        $rv{$key} = $kenmerk->$dbkey;
    }

    return \%rv;
}

sub kenmerk_exists {
    my ($self, %opts)   = @_;

    return unless $opts{kenmerk_naam};

    return $self->c->model(KENMERKEN_DB)->search({
        'naam'  => $opts{kenmerk_naam}
    })->count;
}




sub ACCEPT_CONTEXT {
    my ($self, $c) = @_;

    $self->{c} = $c;

    return $self;
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

