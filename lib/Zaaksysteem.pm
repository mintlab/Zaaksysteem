package Zaaksysteem;

use Moose;

use Data::Dumper;
use Sys::Hostname;
use IO::Socket;

use Catalyst qw/
    ConfigLoader
    Static::Simple

    Authentication
    Authorization::Roles

    Session
    Session::Store::File
    Session::State::Cookie

    Params::Profile


    Unicode::Encoding
    I18N
    ClamAV
/;

extends qw/Catalyst Zaaksysteem::General/;

our $VERSION = '2.4.3';

{
    $VERSION .= '.$Revision: 2676 $';
    $VERSION =~ s/\$Revision: (\d+)\s?\$/$1/g;
}

#extends 'Catalyst';
#with 'CatalystX::LeakChecker';
#with 'CatalystX::LeakChecker';


# Configure the application.
#
# Note that settings in zaaksysteem.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.


__PACKAGE__->config(
    'Plugin::ConfigLoader' => {
        file => (-f '/etc/zaaksysteem/zaaksysteem.conf'
            ? '/etc/zaaksysteem/zaaksysteem.conf'
            : 'zaaksysteem.conf'
        ),
    },
    'name'              => 'Zaaksysteem',
    'View::TT'          => {
        tpl       => 'zaak_v1',
        locale    => 'nl_NL',
    },
    'View::JSON' => {
        allow_callback  => 0,    # defaults to 0
        expose_stash    => [ qw(json) ], # defaults to everything
    },
    'View::Email'          => {
        stash_key => 'email',
        template_prefix => 'tpl/zaak_v1/nl_NL',
        default => {
            content_type => 'text/plain',
            charset => 'utf-8',
            from    => 'info@zaaksysteem.nl',
            view        => 'TT',
        },
        sender => {
            'mailer'    => 'Sendmail'
        }
    },
    'default_view'      => 'TT',
);

__PACKAGE__->mk_classdata($_) for qw/
    _additional_static
/;


### Define state of machine, dev?
{

    if (hostname() =~ /^app/) {
        __PACKAGE__->config(
            'otap'  => 'prod'
        );
    } elsif (hostname() =~ /^demo/) {
        __PACKAGE__->config(
            'otap'  => 'demo'
        );
    } elsif (hostname() =~ /^accept/) {
        __PACKAGE__->config(
            'otap'  => 'accept'
        );
    } elsif (hostname() =~ /^test/) {
        __PACKAGE__->config(
            'otap'  => 'test'
        );
    } else {
        __PACKAGE__->config(
            'otap'  => 'dev'
        );

        $ENV{EZRA_DEV} = 1;
    }

    if (__PACKAGE__->config->{otap} ne 'dev') {
        __PACKAGE__->config(
            'Plugin::Session' => {
                storage => '/tmp/ezra_'
                    . __PACKAGE__->config->{otap}
            }
        );


        if (__PACKAGE__->config->{otap} ne 'prod') {
            __PACKAGE__->config->{'Model::Plugins::Digid'}
                ->{app_url} = 'https://' . __PACKAGE__->config->{otap}
                    . '.zaaksysteem.nl/auth/digid';
        }
    } else {
        __PACKAGE__->config(
            'Plugin::Session' => {
                storage => '/tmp/ezra_dev_' . $ENV{USER}
            }
        );

    }

}

# Start the application
__PACKAGE__->setup();

# Configure the customers
{
    __PACKAGE__->mk_classdata('customer');

    if (
        __PACKAGE__->config->{customers} &&
        UNIVERSAL::isa(__PACKAGE__->config->{customers}, 'HASH')
    ) {
        __PACKAGE__->customer({});
        for my $host (keys %{ __PACKAGE__->config->{customers} }) {
            __PACKAGE__->customer->{$host} = {
                'dbh'           => undef,
                'dbgh'          => undef,
                'ldaph'         => undef,
                'start_config'  => __PACKAGE__->config
                    ->{customers}
                    ->{$host},
                'run_config'    => undef,
            };
        }
    } else {
        die('Error: no customers defined in zaaksysteem.conf');
    }

    sub customer_instance {
        my $c           = shift;
        my $hostname    = $c->req->uri->host;

        unless (__PACKAGE__->customer->{ $hostname }) {
            ### Second try (subdomains etc)
            for my $host (keys %{ __PACKAGE__->config->{customers} }) {
                ### XXX TODO
            }

            die(
                'Could not find configuration for hostname: '
                . $c->req->hostname
            );
        }

        my $customerdata    = __PACKAGE__->customer->{ $hostname };

        if ($customerdata->{start_config}->{dropdir}) {
            __PACKAGE__->config->{dropdir} = $customerdata
                ->{start_config}
                ->{dropdir};
        }

        my $tt_template = 'zaak_v1';
        if ($customerdata->{start_config}->{template}) {
            $tt_template = $customerdata->{start_config}->{template};
        }
        if ($customerdata->{start_config}->{customer_id}) {
            __PACKAGE__->config->{gemeente_id} = $customerdata->{start_config}->{customer_id}
        }

        __PACKAGE__->_additional_static([
            __PACKAGE__->config->{root},
            __PACKAGE__->config->{root} . '/tpl/'
                . $tt_template
                . '/' . __PACKAGE__->config->{'View::TT'}->{locale}
        ]);

        __PACKAGE__->config->{static}->{include_path} = __PACKAGE__->_additional_static;

        if ($customerdata->{start_config}->{files}) {
            __PACKAGE__->config->{files}  = $customerdata->{start_config}->{files};
        } else {
            __PACKAGE__->config->{files}  = __PACKAGE__->config->{home}
                . '/'
                . $customerdata->{start_config}->{customer_id}
                . '/files';
        }

        if ($customerdata->{start_config}->{customer_info}) {
            __PACKAGE__->config->{gemeente} =
                $customerdata->{start_config}->{customer_info};
        }

        __PACKAGE__->config->{'SVN_VERSION'} = $VERSION;

        return $customerdata;
    }
}

around 'dispatch' => sub {
    my $orig    = shift;
    my $c       = shift;

    {
        my $realm               = $c->get_auth_realm('default');

        my $customer_instance   = $c->customer_instance;

        $c->config->{customer} = $customer_instance;

        $realm->store->user_basedn($customer_instance->{start_config}->{'LDAP'}->{basedn});
        $realm->store->role_basedn($customer_instance->{start_config}->{'LDAP'}->{basedn});
    }

    return $c->$orig(@_);
};


### Configure additional templates
### XXX REMOVE AFTER 2.0 release
#{
#    __PACKAGE__->_additional_static([
#        __PACKAGE__->config->{root},
#        __PACKAGE__->config->{root} . '/tpl/'
#            . __PACKAGE__->config->{'View::TT'}->{tpl}
#            . '/' . __PACKAGE__->config->{'View::TT'}->{locale}
#    ]);

    #__PACKAGE__->config->{static}->{include_path} = __PACKAGE__->_additional_static;
    #__PACKAGE__->config->{files}  = __PACKAGE__->config->{home} . '/files';
#}





### Basic zaak authorisation
sub _can_change_messages {
    my ($c) = @_;

    if (
        $c->stash->{zaak}->is_afgehandeld
    ) {
        $c->flash->{'result'} =
            'U kunt geen wijzigingen aanbrengen aan deze'
            . ' zaak. Deze zaak is afgehandeld';
        return 1;
    }

    if (
        !$c->stash->{zaak}->behandelaar ||
        !$c->user_exists ||
        !$c->user->uidnumber ||
        (
            $c->stash->{zaak}->behandelaar &&
            $c->stash->{zaak}->behandelaar->gegevens_magazijn_id ne
            $c->user->uidnumber &&
            (
                !$c->stash->{zaak}->coordinator ||
                $c->stash->{zaak}->coordinator->gegevens_magazijn_id ne
                $c->user->uidnumber
            )
        )
    ){
        $c->flash->{'result'} =
            'U kunt geen wijzigingen aanbrengen aan deze'
            . ' zaak, u bent geen behandelaar / coordinator.';
    }

    if ($c->stash->{zaak}->status eq 'new') {
        if (
            (
                !$c->stash->{zaak}->behandelaar &&
                !$c->stash->{zaak}->coordinator
            )
        ) {
            $c->flash->{result} = ' Deze zaak is niet in behandeling genomen. Klik <a href="'
            . $c->uri_for('/zaak/' . $c->stash->{zaak}->nr . '/open') .
            '">hier</a> om deze zaak in behandeling te nemen.';
        }

        if (
            $c->user_exists &&
            $c->stash->{zaak}->behandelaar &&
            $c->stash->{zaak}->behandelaar->gegevens_magazijn_id eq
                $c->user->uidnumber
        ) {
            $c->flash->{result} = 'U heeft deze zaak nog niet in behandeling'
            . ' genomen. Klik <a href="'
            . $c->uri_for('/zaak/' . $c->stash->{zaak}->nr . '/open') .
            '">hier</a> om deze zaak in behandeling te nemen.';
        }
    }

    ### Meldingen
    if ($c->stash->{zaak}->status ne 'open') {
        ### TODO ZAAK
#        if ($c->stash->{zaak}->kenmerk->vroegtijdig_info) {
#            $c->flash->{'result'} =
#                '<span class="flash-urgent">Deze zaak is vroegtijdig '
#                .' be-eindigd: ' .  $c->stash->{zaak}->kenmerk->vroegtijdig_info
#                .'</span>';
#        }
        if ($c->stash->{zaak}->status eq 'stalled') {
            $c->flash->{'result'} = '<span class="flash-urgent">'
                .'Deze zaak is opgeschort: '
                . $c->stash->{zaak}->reden_opschorten
                .  '</span>';
            ### TODO ZS2 opgeschort info
        }
    }
}

sub can_change {
    my ($c, $opt) = @_;

    return unless $c->stash->{zaak};

    $c->_can_change_messages;

    if (
        $c->stash->{zaak}->is_afgehandeld &&
        !$opt->{ignore_afgehandeld}
    ) {
        $c->log->debug('can_change false: zaak afgehandeld');
        return;
    }

    ### Zaak beheerders mogen wijzigingen aanbrengen ondanks dat ze geen
    ### behandelaar.
    return 1 if (
        $c->check_any_zaak_permission('zaak_beheer')
    );

    ### Override when we have the correct permissions, and we have a
    ### coordinator and behandelaar
    return 1 if (
        $c->stash->{zaak}->behandelaar &&
        $c->stash->{zaak}->coordinator &&
        $c->check_any_zaak_permission('zaak_beheer','zaak_edit')
    );

    if ($c->stash->{zaak}->status eq 'new') {
        if (
            (
                !$c->stash->{zaak}->behandelaar &&
                !$c->stash->{zaak}->coordinator
            )
        ) {
            return;
        }

        ### Zaak is new, but when we are coordinator, we still can make
        ### changes
        if (
            $c->user_exists &&
            $c->stash->{zaak}->coordinator &&
            $c->stash->{zaak}->coordinator->gegevens_magazijn_id
                eq $c->user->uidnumber
        ) {
            return 1;
        }
    }

    if (
        !$c->stash->{zaak}->behandelaar ||
        !$c->user_exists ||
        !$c->user->uidnumber ||
        (
            $c->stash->{zaak}->behandelaar &&
            $c->stash->{zaak}->behandelaar->gegevens_magazijn_id ne
            $c->user->uidnumber &&
            (
                !$c->stash->{zaak}->coordinator ||
                $c->stash->{zaak}->coordinator->gegevens_magazijn_id ne
                $c->user->uidnumber
            )
        )
    ){
        $c->flash->{'result'} =
            'U kunt geen wijzigingen aanbrengen aan deze'
            . ' zaak, u bent geen behandelaar / coordinator.';
        return;
    }

    return 1;
}

sub return_undef { return }



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

