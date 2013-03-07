package Zaaksysteem::Controller::Page;

use strict;
use warnings;
use Data::Dumper;
use parent 'Catalyst::Controller';
use File::stat;




sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Zaaksysteem::Controller::Page in Page.');
}

sub begin : Private {
    my ($self, $c) = @_;

    # No caching doen omdat IE de boel vernacheld
    my $useragent = $c->request->header('user-agent') || '';
    
    if($useragent =~ m|MSIE|) {
	    $c->response->headers->last_modified(time);
    	$c->response->headers->expires(time + ($self->{cache_time}||0));
    	$c->response->headers->header(cache_control => "public, max-age=" . ($self->{cache_time}||0));
	}

    ### Auth action:
    my $authaction = $c->req->action;
    $authaction =~ s|^/|| unless $authaction eq '/';

    $c->log->debug("-----------------------------------------------------");
    $c->log->debug("Request URI: " . $c->req->uri);
    $c->log->debug('Auth: requested action: ' . $authaction);

    ### PreAUTH: Speedbump for some special actions, javascript/css bundle
    if (
        lc($authaction) eq 'page/minified' ||
        lc($authaction) eq 'page/css_minified' ||
        lc($authaction) =~ /^tpl\/zaak_v1\/nl_nl\/css/
    ) {
        return 1;
    }

    ### Define own stash workspace
    $c->stash->{_Page} = {};

    if (
        $c->session->{zaaksysteem} &&
        $c->session->{zaaksysteem}->{mode} &&
        $c->session->{zaaksysteem}->{mode} eq 'simple'
    ) {
        $c->stash->{layout_type} = 'simple'
    }

    $c->languages(['nl']) if $c->can('languages');

    ### Make sure everyone is logged in
    if (
        !$c->user_exists &&
        lc($authaction) ne 'auth/login' &&
        lc($authaction) !~ /^form/ &&
        lc($authaction) !~ /^plugins\/pip/ &&
        lc($authaction) !~ /zaak\/documents\/get/ &&
        lc($authaction) !~ /^test.*/ &&
        lc($authaction) !~ /^plugins\/digid.*/ &&
        lc($authaction) !~ /^plugins\/maps.*/ &&
        lc($authaction) !~ /^plugins\/bedrijfid.*/ &&
        lc($authaction) !~ /^plugins\/ogone.*/ &&
        lc($authaction) !~ /^plugins\/parkeergebied.*/ &&
        lc($authaction) !~ /^api.*/ &&
        lc($authaction) !~ /^gegevens\/bag\/search.*/ &&
        lc($authaction) ne 'zaak/create' &&
        lc($authaction) ne 'page/retrieve_component' &&
        lc($authaction) ne 'monitor' &&
        ! (
            lc($authaction) =~ /^beheer\/import\/.*\/run/ &&
            $c->config->{otap_ip} eq $c->req->address
        ) &&
        ! (
            lc($authaction) =~ /^gegevens\/bag\/import/ &&
            $c->config->{otap_ip} eq $c->req->address
        )
    ) {
        $c->flash->{referer} = $c->uri_for('/' . $c->req->path);
        $c->response->redirect($c->uri_for('/auth/login'));
        $c->detach;
        return;
    }

    if ($c->engine->env) {
        $c->log->debug(
            'SSL Client Side Certificate Secured: '
            . ($c->engine->env->{SSL_CLIENT_S_DN} ? 'Yes' : 'No')
        );

        $c->stash->{ssl_client_side} = 1 if
            $c->engine->env->{SSL_CLIENT_S_DN};

        if ($c->stash->{ssl_client_side}) {
            $c->log->debug(Dumper($c->engine->env));

        }
    }

    ### Create under contstruction pages
    $c->forward('under_construction');

    ### Give every controller a chance to load page specific data
    foreach my $controller ($c->controllers) {

        if ($c->controller($controller)->can('prepare_page')) {
            $c->controller($controller)->prepare_page($c);
            #$c->log->debug('Menu: '.Dumper(%{$c->stash->{menu}->{'main'}}));
            
            #$c->forward('/' . lc($controller) . '/prepare_page');
        }
    }

    return 1;
}

{
    my $PAGE_COMPONENTS = {
        'usermenu'  => 'layouts/default_container_top.tt',
        'mainmenu'  => 'layouts/default_container_mainmenu.tt',
    };

    sub retrieve_component : Local {
        my ($self, $c, $component) = @_;

        unless ($component && $PAGE_COMPONENTS->{$component}) {
            $c->res->body('Ehm?');
            $c->detach;
        }

        my $user = $c->find_user(
            {
                username    => $c->req->params->{username}
            }
        );

        $c->set_authenticated($user);

        $c->delete_session;

        $c->stash->{nowrapper}  = 1;
        $c->stash->{template}   = $PAGE_COMPONENTS->{$component};
    }
}

sub under_construction : Private {
    my ($self, $c) = @_;

    $c->forward('/page/add_menu_item', [
        {
            'main' => [
                {
                    'cat'   => 'Beheer',
                    'name'  => 'Gebruikersbeheer',
                    'href'  => $c->uri_for('/page/construction')
                },
                {
                    'cat'   => 'Beheer',
                    'name'  => 'Gegevensbeheer',
                    'href'  => $c->uri_for('/page/construction')
                },
                {
                    'cat'   => 'Beheer',
                    'name'  => 'Pluginbeheer',
                    'href'  => $c->uri_for('/page/construction')
                },
                {
                    'cat'   => 'Beheer',
                    'name'  => 'Zaaktypebeheer',
                    'href'  => $c->uri_for('/page/construction')
                },
            ],
        }
    ]);

}




sub add_menu_item : Private {
    my ($self, $c, $menu) = @_;

    if (!UNIVERSAL::isa($menu, 'HASH')) {
        $c->log->debug('add_menu_item: invalid menu');
        return;
    }

    if (!exists($c->stash->{menu})) {
        $c->stash->{menu} = {
            'quick' => [],
            'main'  => {},
        };

        ### Add home to our menu
#        $c->forward('add_menu_item', [
#            {
#                'quick' => [
#                    {
#                        'name'  => 'Home',
#                        'href'  => $c->uri_for('/'),
#                    }
#                ],
#            }
#        ]);

    }

    if (exists($menu->{'quick'})) {
        for my $item (@{ $menu->{'quick'} }) {
            ### TODO check for valid menu item
            push(@{ $c->stash->{menu}->{'quick'} }, $item);
        }
    }

    if (exists($menu->{'main'})) {
        for my $item (@{ $menu->{'main'} }) {
            ### TODO check for valid menu item
            if (!exists($c->stash->{menu}->{'main'}->{ $item->{'cat'} })) {
                $c->stash->{menu}->{'main'}->{ $item->{'cat'} } = [];
            }
            push(@{ $c->stash->{menu}->{'main'}->{ $item->{'cat'} } }, $item);
        }
    }
}

sub confirmation : Private {
    my ($self, $c) = @_;

    $c->stash->{template} = 'confirmation.tt';

    if ($c->req->header("x-requested-with") eq 'XMLHttpRequest') {
        $c->stash->{nowrapper}  = 1;
        $c->stash->{xmlrequest} = 1;
    }
}


sub dialog : Private {
    my ($self, $c, $opt) = @_;

    Params::Profile->register_profile(
        'method'    => [caller(0)]->[3],
        'profile'   => $opt->{validatie}
    );

    ### Auth
    $c->assert_any_zaak_permission(@{ $opt->{permissions} });

    if ($c->req->header("x-requested-with") eq 'XMLHttpRequest') {
        if ($c->req->params->{do_validation}) {
            $c->zvalidate;
            $c->detach;
        }

        $c->stash->{nowrapper} = 1;
        $c->stash->{template} = $opt->{template};
        $c->detach;
    }

    if ($c->req->params->{confirmed} && (my $dv = $c->zvalidate)) {
        $c->res->redirect($opt->{complete_url});
        return $dv;
    }

    return;
}


my $MINIFIED_MAPPING = {
    'css'   => {
        'common'    => 'common_header_includes_css.tt',
        'private'   => 'private_header_includes_css.tt',
    },
    'js'    => {
        'common'    => 'common_header_includes_js.tt',
        'private'   => 'private_header_includes_js.tt',
    },
};

sub css_minified : Path('/tpl/zaak_v1/nl_NL/css') {
    my ($self, $c, $template) = @_;

    $template =~ s/\.css$//;

    $c->forward('minified', [ $template, 'css' ]);
}

sub minified : Local {
    my ($self, $c, $template, $cat) = @_;

    $c->stash->{nowrapper}                      = 1;
    $c->stash->{invoke_assets_minified_request} = 1;

    ### Use zaaksysteem.js as modification time for last-modified header
    my $filename;
    if ($cat eq 'js') {
    	$c->response->content_type("text/javascript");
        $filename    = $c->path_to(
            '/root/tpl/zaak_v1/nl_NL/js/zaaksysteem.js'
        );
    } else {
        $c->response->content_type('text/css');
        $filename    = $c->path_to(
            '/root/tpl/zaak_v1/nl_NL/css/stylesheet.css'
        );
    }

    my $mtime       = $self->is_asset_modified($c, $filename);
    if ($MINIFIED_MAPPING->{$cat}->{$template}) {
        $c->stash->{template} = 'layouts/' .
            $MINIFIED_MAPPING->{$cat}->{$template};

        $c->response->headers->last_modified($mtime);
        $c->detach;
    };

    $c->res->body('Forbidden');
    $c->res->status(403);
}

sub is_asset_modified : Local {
    my ($self, $c, $filename) = @_;

    my $fileinfo = stat($filename);

    if (!$fileinfo) {
        $c->res->body('Forbidden');
        $c->res->status(403);
        $c->detach;
    }

    if (
        $c->req->headers->if_modified_since &&
        $c->req->headers->if_modified_since < time() &&
        $c->req->headers->if_modified_since >= $fileinfo->mtime
    ) {
        $c->res->status(304);
        $c->detach;
    }

    return $fileinfo->mtime;
}

sub about : Local {
    my ($self, $c)  = @_;

    $c->stash->{nowrapper} = 1;
    $c->stash->{template} = 'widgets/about.tt';

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

