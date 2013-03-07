package Zaaksysteem::Controller::Medewerker;

use strict;
use warnings;
use parent 'Catalyst::Controller';




sub prepare_page : Private {
    my ($self, $c) = @_;

    ### Define the basics
    $c->stash->{org_eenheden} = $c->model('Betrokkene')->search(
        {
            type    => 'org_eenheid',
            intern  => 0,
        },
        {}
    );
}


sub behandelaar : Global {
    my ($self, $c, $zaaktype_node_id) = @_;
    my ( $aanvrager_keuze );

    $c->stash->{template}               = 'form/list.tt';
    $c->session->{zaaksysteem}->{mode}  = $c->stash->{layout_type} = 'simple';


    $c->stash->{behandelaar_form}       = $c->session->{behandelaar_form} = 1;

    ### When id given, redirect to first step
    if ($zaaktype_node_id) {
        $c->res->redirect(
            $c->uri_for(
                '/zaak/create',
                {
                    mode                => 'behandelaar',
                    zaaktype            => $zaaktype_node_id,
                    create              => 1,
                    ztc_trigger         => 'intern',
                    betrokkene_type     => 'medewerker',
                    ztc_contactkanaal   => 'post',
                    ztc_aanvrager_id    => 'betrokkene-medewerker-' .  $c->user->uidnumber
                }
            )
        );
        $c->detach;
    }

    ### Let's get a list of zaaktypen
    $c->stash->{zaaktypen}  = $c->model('Zaaktype')->list(
        {
            'zaaktype_trigger'  => 'intern',
        },
    );
}

sub base : Chained('/') : PathPart('medewerker') : CaptureArgs(1) {
    my ($self, $c, $userid)  = @_;

}

sub index : Chained('/') : PathPart('medewerker') : Args(0) {
    my ($self, $c, $userid)     = @_;

    $c->assert_any_user_permission('admin');

    $c->stash->{medewerkers}    = $c->model('Users')->get_all_medewerkers;
    $c->stash->{all_roles}      = $c->model('Users')->get_all_roles;

    $c->stash->{template}       = 'medewerker/index.tt';
}

sub update : Chained('/') : PathPart('medewerker/update_rol') : Args(0) {
    my ($self, $c, $userid)     = @_;

    $c->assert_any_user_permission('admin');

    $c->stash->{medewerkers}    = $c->model('Users')->get_all_medewerkers;

    my $rawroles                   = {
        map {
            my $key = $_;
            $key    =~ s/zsmw_//;
            $key    => $c->req->params->{$_}
        } grep(/^zsmw_/, keys %{ $c->req->params })
    };

    my $roles;
    for my $role (keys %{ $rawroles }) {
        if (UNIVERSAL::isa($rawroles->{$role}, 'ARRAY')) {
            $roles->{$role} = $rawroles->{$role};
        } else {
            $roles->{$role} = [ $rawroles->{$role} ];
        }
    }

    #### Run it
    while (my ($username, $roles) = each %{ $roles }) {
        use Data::Dumper;
        $c->log->debug('USERNAME: ' . $username . ' / Roles: ' . Dumper($roles));
        $c->model('Users')->deploy_user_in_roles(
            $username, $roles
        );
    }

    $c->res->redirect($c->uri_for('/medewerker'));

    $c->detach;
}

sub testimport : Local {
    my ($self, $c) = @_;

    die('DIE STOP HIERE');

    my $userlist        = [
        {
            department => 'DIV en communicatie en WenB werken',
            user        => 'nbh',
            fullname    => 'Nicole Bosch',
        },
        {
            department => 'DIV en communicatie en WenB werken',
            user        => 'don',
            fullname    => 'Dicky Oomen',
        },
        {
            department => 'DIV en communicatie en WenB werken',
            user        => 'wnl',
            fullname    => 'Winny Nagel',
        },
        {
            department => 'DIV en communicatie en WenB werken',
            user        => 'bdr',
            fullname    => 'Bea Daselaar',
        },
        {
            department => 'DIV en communicatie en WenB werken',
            user        => 'mvt',
            fullname    => 'Marian Verkaart',
        },
        {
            department => 'DIV en communicatie en WenB werken',
            user        => 'abm',
            fullname    => 'Aruna Boedhram',
        },
        {
            department => 'DIV en communicatie en WenB werken',
            user        => 'adg',
            fullname    => 'Arnaud Disberg',
        },
        {
            department => 'DIV en communicatie en WenB werken',
            user        => 'mon',
            fullname    => 'Marieke van Oostveen',
        },
        {
            department => 'DIV en communicatie en WenB werken',
            user        => 'agp',
            fullname    => 'Ariean van de Groep',
        },
        {
            department => 'DIV en communicatie en WenB werken',
            user        => 'abg',
            fullname    => 'Alexander van den Berg',
        },
        {
        user=> 'dhn',
        fullname =>'Dennis Hagen',
        department=>'Planvoorbereiding en Groenbeheer'
        },
        {
        user=> 'awj',
        fullname =>'Ad van Wanroij',
        department=>'Planvoorbereiding en Groenbeheer'
        },
        {
        user=> 'cnd',
        fullname =>'Cees Noorland',
        department=>'Planvoorbereiding en Groenbeheer'
        },
        {
        user=> 'dor',
        fullname =>'Dik van den Oudenalder',
        department=>'Planvoorbereiding en Groenbeheer'
        },
        {
        user=> 'ghk',
        fullname =>'Gert Jan Hoitink',
        department=>'Planvoorbereiding en Groenbeheer'
        },
        {
        user=> 'hks',
        fullname =>'Hans Knotters',
        department=>'Planvoorbereiding en Groenbeheer'
        },
        {
        user=> 'jrt',
        fullname =>'Jorrit de Regt',
        department=>'Planvoorbereiding en Groenbeheer'
        },
        {
        user=> 'mvd',
        fullname =>'Marcel Voorveld',
        department=>'Planvoorbereiding en Groenbeheer'
        },
        {
        user=> 'wbe',
        fullname =>'Wim ten Boske',
        department=>'Planvoorbereiding en Groenbeheer'
        },
        {
        user=> 'tbk',
        fullname =>'Thelma Giele- van den Broek',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'avs',
        fullname =>'Ank van der Vlies',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'fbr',
        fullname =>'Fanny Blokker- van Breukelen',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'ftl',
        fullname =>'Frieda Thiel-Drost',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'jha',
        fullname =>'Jikkemien van Beek-Hettinga',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'mur',
        fullname =>'Meral Akdag-Ulker',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'pmk',
        fullname =>'Petra de Munnik',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'smw',
        fullname =>'Sjantie Mahadew',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'ahd',
        fullname =>'Ton van Hardeveld',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'wzd',
        fullname =>'Wendelmoet van Zonneveld',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'wmr',
        fullname =>'Wim Mercuur',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'thr',
        fullname =>'Thiemen den Hollander',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'nnn',
        fullname =>'Nick van Nieuwenhuizen',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'mst',
        fullname =>'Madhava Schuit',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'jhh',
        fullname =>'Johan de Haan',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'fbg',
        fullname =>'Frans van den Berg',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'eli',
        fullname =>'Eric Leroi',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'jbr',
        fullname =>'Jan van den Bor',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'clt',
        fullname =>'Corne Lokhorst',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'mdn',
        fullname =>'Marc Dijkman',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'ors',
        fullname =>'Onno Renes',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'rwk',
        fullname =>'Ronald Wennink',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'tkn',
        fullname =>'Tiem Koelewijn',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'vmr',
        fullname =>'Victor Meier',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
        {
        user=> 'jsr',
        fullname =>'Han Schokker',
        department=>'Facilitaire zaken Receptie en ICT beheer'
        },
    ];

    my $users           = $c->model('Users');

    my $ldap            = $users->ldaph;

    my $ldapusers = {};
    for my $user (@{ $userlist }) {
        my $fullname = $user->{fullname};

        my ($firstname, $lastname) = $fullname =~ /(.*?)\s(.*)$/;

        $ldapusers->{$user->{user}} = {
            #userPassword    => '{SHA}nonexisting',
            displayName     => $lastname . ', ' . $firstname,
            sn              => $lastname,
            givenName       => $firstname,
            mail            => $user->{user} . '@baarn.nl',
            telephoneNumber => '0351234557',
            homeDirectory   => '/home/' . $user->{user},
            loginShell      => '/bin/nologin',
            initials        => uc(substr($firstname, 0, 1)) . '.',
            uid             => $user->{user},
            department      => $user->{department},
        };
    }

    $c->log->debug(Dumper($ldapusers));

    $users->_create_ldap($ldap, $ldapusers);

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

