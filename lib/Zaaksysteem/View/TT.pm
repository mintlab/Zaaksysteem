package Zaaksysteem::View::TT;

use strict;
use base 'Catalyst::View::TT';
use DateTime;
use Zaaksysteem::Constants;

__PACKAGE__->mk_accessors(qw/_app_root_dirs/);

#__PACKAGE__->config(TEMPLATE_EXTENSION => '.tt');
__PACKAGE__->config({
#    TEMPLATE_EXTENSION => '.tt',
    RELATIVE    => 1,
    WRAPPER     => 'tpl/zaak_v1/nl_NL/layouts/wrapper.tt',
    RECURSION   => 1,
    PRE_CHOMP   => 2,
    POST_CHOMP  => 2,
});




sub render {
    my $self    = shift;
    my ($c)     = @_;

    $c->stash->{template_root}  = $c->config->{root} . '/tpl/zaak_v1/nl_NL';
    $c->stash->{template_site}  = '/tpl/zaak_v1/nl_NL';

    $c->stash->{constants}      =
        $c->stash->{ZCONSTANTS} = ZAAKSYSTEEM_CONSTANTS;
    $c->stash->{ZNAMING}        = ZAAKSYSTEEM_NAMING;
    $c->stash->{ZOPTIONS}       = ZAAKSYSTEEM_OPTIONS;
    $c->stash->{ZKENMERK}       = ZAAKSYSTEEM_STANDAARD_KENMERKEN;
    $c->stash->{helpers}        = {
        'date'      => DateTime->now()
    };

    $c->stash->{ZKENMERK}       = ZAAKSYSTEEM_STANDAARD_KENMERKEN;
    $c->stash->{ENV}            = \%ENV;

    $c->stash->{invoke_assets_minified} = 1 if
        $c->config->{invoke_assets_minified};

    $c->stash->{additional_template_paths} = [
        $c->stash->{template_root}
    ];

    $self->NEXT::render( @_ );
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

