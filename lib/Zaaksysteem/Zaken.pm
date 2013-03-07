package Zaaksysteem::Zaken;

use strict;
use warnings;

use Params::Profile;
use Data::Dumper;
use Zaaksysteem::Constants;

use Moose;
use namespace::autoclean;

use Scalar::Util qw(blessed);

### Roles
use constant ZAAK_TABEL => 'Zaak';



has [qw/config prod log dbic z_betrokkene rt/] => (
    'is'    => 'rw',
);



sub find {
    my $self    = shift;

    $self->dbic->resultset(ZAAK_TABEL)->find(@_);
}

sub search {
    my $self    = shift;

    $self->dbic->resultset(ZAAK_TABEL)->search_extended(@_);
}

sub create {
    my $self    = shift;

    $self->dbic->resultset(ZAAK_TABEL)->create_zaak(@_);
}

#
# this provides the logic for the filter boxes on the top of any Zaken overview.
# it needs an existing resultset, and narrows that down based on user input
#
Params::Profile->register_profile(
	method  => 'filter',
	profile => {
		required        => [ qw/
			resultset
		/],
		optional        => [ qw/
			dropdown
			textfilter
		/],
		constraint_methods    => {
			resultset    => sub { 
				my ($profile, $value) = @_; 
				return $value->isa('Zaaksysteem::Zaken::ResultSetZaak') 
			},
			dropdown         => qr/^\w*$/,
#			textfilter       => qr/^\w*$/,
		},
	}
);

sub filter {
	my ($self, $options) = @_;
	
	my $dv = Params::Profile->check(params => $options);

	unless($dv->success) {
		die "Zaken::filter() validation error: ". Dumper $dv->msgs;
	}
	
	my $additional_filtering = [];

    my $filter = $options->{'dropdown'} || '';
    my $additional_filter;
	if($filter) {
		if($filter eq 'urgent') {
			$additional_filter->{'urgentie'} = 'high';
		} else {
			$additional_filter->{'me.status'} = $filter;
		}
		push @$additional_filtering, $additional_filter;
	}
	
	my $textfilter_where;
	my $textfilter = $options->{'textfilter'};
	if($textfilter) {
		my $textfilters = [];

		push @$textfilters, { 'me.onderwerp' => { 'ilike' => '%'. $textfilter. '%' }};

# todo match on zaaktype_node_id.titel
# todo string match on ID
		if($textfilter =~ m|^\d+$|) {
		   	push @$textfilters,\[ 'TEXT(me.id) LIKE ?', [ plain_value => '%' . $textfilter . '%' ] ],
		}

		my $betrokkenen = $self->dbic->resultset('ZaakBetrokkenen')->search({
			'naam' => {'ilike' => '%'. $textfilter. '%' },
		});
		
		my $zaaktypen = $self->dbic->resultset('ZaaktypeNode')->search({
			'titel' => {'ilike' => '%'. $textfilter. '%' },
		});
		
		push @$textfilters, { 'zaaktype_node_id' => { -in => $zaaktypen->get_column('id')->as_query }};

		push @$textfilters, { 'aanvrager' => { -in => $betrokkenen->get_column('id')->as_query }};

		push @$additional_filtering, ['-or' => $textfilters ];
	}
$self->log->debug('add filtering: ' . Dumper $additional_filtering);
	if(@$additional_filtering) {
		return $options->{'resultset'}->search('-and' => $additional_filtering);
	}
	return $options->{'resultset'};
}





#
# central query to retrieve all openstaande_zaken
#
Params::Profile->register_profile(
    method  => 'openstaande_zaken',
    profile => {
        required        => [ qw/
            page
            rows
            uidnumber
        /],
        optional        => [ qw/
            sort_direction
            sort_field
        /],
        constraint_methods    => {
            page    => qr/^\d+$/,
            rows    => qr/^\d+$/,
        },
    }
);

sub openstaande_zaken {
	my ($self, $options) = @_;

	my $dv = Params::Profile->check(params => $options);
	unless($dv->success) {
		die "Zaken::openstaande_zaken() validation error: ". Dumper $dv->msgs;
	}
	

	my $where = { 'me.status' => 'open' };
	
	$where->{'me.behandelaar_gm_id'} = $options->{'uidnumber'};
	$where->{'me.deleted'} = undef;

    my $extra_params = {
        page    => $options->{'page'},
        rows    => $options->{'rows'},
    };

    $extra_params->{order_by} = {
        '-' . ($options->{sort_direction} || 'asc') => $options->{sort_field}
    } if $options->{sort_field};

    return $self->dbic->resultset('Zaak')->search_extended(
        $where,
        $extra_params
    );
}

#
# central query to retrieve all openstaande_zaken
#
Params::Profile->register_profile(
    method  => 'adres_zaken',
    profile => {
        required        => [ qw/
            page
            rows
            nummeraanduiding
        /],
        optional        => [ qw/
            sort_direction
            sort_field
            status
        /],
        constraint_methods    => {
            page    => qr/^\d+$/,
            rows    => qr/^\d+$/,
        },
    }
);

sub adres_zaken {
    my ($self, $options) = @_;
    my $where = {};

    my $dv = Params::Profile->check(params => $options);
    unless($dv->success) {
        die "Zaken::openstaande_zaken() validation error: ". Dumper $dv->msgs;
    }

    #my $where = { 'me.status' => 'open' };
    $where->{'me.status'} = $options->{status} if $options->{status};

    my $locaties = $self->dbic->resultset('ZaakBag')->search({
        'bag_nummeraanduiding_id' => $options->{nummeraanduiding}->identificatie,
    });

    $where->{'locatie_zaak'} = {-in => $locaties->get_column('id')->as_query};
    $where->{'me.deleted'} = undef;

    $self->log->debug('adres zaken: ' . Dumper $where);

    my $extra_params = {
        page    => $options->{'page'},
        rows    => $options->{'rows'},
    };

    $extra_params->{order_by} = {
        '-' . ($options->{sort_direction} || 'asc') => $options->{sort_field}
    } if $options->{sort_field};

    return $self->dbic->resultset('Zaak')->search_extended(
        $where,
        $extra_params
    );
}

#
# central query to retrieve all openstaande_zaken
#
Params::Profile->register_profile(
    method  => 'zaken_pip',
    profile => {
        required        => [ qw/
            page
            rows
            betrokkene_type
            gegevens_magazijn_id
            type_zaken
        /],
        optional        => [ qw/
            sort_direction
            sort_field
        /],
        constraint_methods    => {
            page    => qr/^\d+$/,
            rows    => qr/^\d+$/,
        },
    }
);

sub zaken_pip {
    my ($self, $options)    = @_;
    my $where               = {};

    my $dv = Params::Profile->check(params => $options);
    unless($dv->success) {
        die "Zaken::openstaande_zaken() validation error: ". Dumper $dv->msgs;
    }

    $where->{'me.status'}        = $options->{type_zaken};
    if ($where->{'me.status'} eq 'open') {
        $where->{'me.status'} = [ 'open','new' ];
    }

    my $betrokkene_where    = {
        'betrokkene_type'       => $options->{betrokkene_type},
        'gegevens_magazijn_id'  => $options->{gegevens_magazijn_id}
    };

    my $betrokkenen     = $self->dbic->resultset('ZaakBetrokkenen')->search(
        $betrokkene_where
    );
    
    if (
        defined($options->{nummeraanduiding}) &&
        ref($options->{nummeraanduiding})
    ) {
        my $locaties        = $self->dbic->resultset('ZaakBag')->search({
            'bag_nummeraanduiding_id' => $options->{nummeraanduiding}->identificatie,
        });
        $where->{'locatie_zaak'}    = {-in => $locaties->get_column('id')->as_query};
    }


    $where->{'aanvrager'}       = {-in => $betrokkenen->get_column('id')->as_query};
    $where->{'me.deleted'}      = undef;

    $self->log->debug($options->{type_zaken} . ' zaken: ' . Dumper $where);

    my $extra_params = {
        page    => $options->{'page'},
        rows    => $options->{'rows'},
    };

    $extra_params->{order_by} = {
        '-' . ($options->{sort_direction} || 'asc') => $options->{sort_field}
    } if $options->{sort_field};

    return $self->dbic->resultset('Zaak')->search_extended(
        $where,
        $extra_params
    );
}

#
# central query to retrieve all openstaande_zaken
#
Params::Profile->register_profile(
	method  => 'intake_zaken',
	profile => {
		required        => [ qw/
			page
			rows
			user_ou_id
			user_roles_ids
			user_roles
			uidnumber
		/],
        optional        => [ qw/
            sort_direction
            sort_field
        /],
		constraint_methods    => {
			page           => qr/^\d+$/,
			rows           => qr/^\d+$/,
			user_ou_id     => qr/^\d+$/,
		},
	}
);

sub intake_zaken {
	my ($self, $options) = @_;

	my $dv = Params::Profile->check(params => $options);
	unless($dv->success) {
		die "Zaken::intake_zaken() validation error: ". Dumper $dv->msgs;
	}
	
	
#	( CF.{behandelaar} LIKE "medewerker-20000-%" AND Status="new" ) OR (( CF.{route_ou_role} LIKE "10013-20007" ) AND CF.{behandelaar} IS "NULL" )

	my @seeers = ();

# zaken die van mij zijn maar nog niet geopend
	my $mine = { 'me.status' => 'new' };
	
	$mine->{'me.behandelaar_gm_id'} = $options->{'uidnumber'};
	push @seeers, $mine;


# zaken die aan mijn afdeling zijn toegewezen maar nog niet aan een specifieke behandelaar zijn toegekend
    my $ou_id = $options->{'user_ou_id'};
	my @roles = ();
    for my $id (@{$options->{'user_roles_ids'}}) {
        push @roles, { 'route_role' => $id};
    }

    push @seeers, {
		'-and' => [
            { '-and' => [
                    { '-or'       => \@roles },
                    { '-or'       => [
                            { 'route_ou'  => $ou_id },
                            { 'route_ou'  => undef },
                        ],
                    }
                ],
            },
			{ 'behandelaar' => undef },
		],
	};


# See if we got a divver, special, [s]he can see all zaken without a complete role.
    my @divroles = grep { $_ eq LDAP_DIV_MEDEWERKER } @{$options->{'user_roles'}};

	if(@divroles) {
		push @seeers, {'me.route_role' => undef};
	}


	my $where = {'-or' => \@seeers };
	$where->{'me.deleted'} = undef;

    ### XXX Omdat zaak_intake alleen voor status new zaken geld
    $where->{'me.status'} = 'new';

    my $extra_params = {
        page    => $options->{'page'},
        rows    => $options->{'rows'},
    };

    $extra_params->{order_by} = {
        '-' . ($options->{sort_direction} || 'asc') => $options->{sort_field}
    } if $options->{sort_field};

    return $self->dbic->resultset('Zaak')->search_extended(
        $where,
        $extra_params
    );
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

