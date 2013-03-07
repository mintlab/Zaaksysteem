package Zaaksysteem::Model::DB;

use Moose;
use Scalar::Util;

extends 'Catalyst::Model::DBIC::Schema';

with 'Catalyst::Component::InstancePerContext';

__PACKAGE__->config(
    schema_class => 'Zaaksysteem::Schema',
);

sub build_per_context_instance {
    my $self    = shift;
    my $c       = shift;

    my $new = $self->new(%$self);

    ### Customer dependence
    my $customer_instance   = $c->customer_instance;

    unless ($customer_instance->{dbh}) {
        $customer_instance->{dbh} = $self->schema->connect(
            $customer_instance->{start_config}->{'Model::DB'}->{connect_info}
        );
    }

    $new->schema(
        $customer_instance->{dbh}
    );

    #$new->schema->default_resultset_attributes->{c} = $c;
    $new->schema->default_resultset_attributes->{betrokkene_model} =
        Zaaksysteem::Betrokkene->new(
            dbic            => $new->schema,
            stash           => $c->stash,
            dbicg           => $c->model('DBG'),
            log             => $c->log,
            config          => $c->config,
            customer        => $customer_instance,
        );

    $new->schema->default_resultset_attributes->{log} = $c->log;

    $new->schema->default_resultset_attributes->{config} = $c->config;

    $new->schema->default_resultset_attributes->{dbic_gegevens} = $c->model('DBG');

    $new->schema->default_resultset_attributes->{current_user} = $c->user
        if $c->user_exists;

    foreach my $attribute (qw/log config c current_user/) {
        if(!Scalar::Util::isweak($new->schema->default_resultset_attributes->{$attribute})) {
            Scalar::Util::weaken($new->schema->default_resultset_attributes->{$attribute});
        }
    }
    return $new;
}


#sub ACCEPT_CONTEXT {
#    my ($self, $c) = @_;
#
#    $self->schema($self->schema->connect($c->config->{'Model::DB'}->{connect_info}));
#
#    $c->log->debug('Come by');
#
#    $self->schema->default_resultset_attributes->{c} = $c;
#
#    $self->schema->default_resultset_attributes->{log} = $c->log;
#
#    Scalar::Util::weaken($self->schema->default_resultset_attributes->{$_})
#        for qw/log config c/;
#
#    $self->schema->default_resultset_attributes->{betrokkene_model} =
#        Zaaksysteem::Betrokkene->new(
#            dbic            => $self->schema,
#            dbicg           => $c->model('DBG'),
#            log             => $c->log,
#            config          => $c->config,
#        );
#
#    $self->schema->default_resultset_attributes->{current_user} = $c->user
#        if $c->user_exists;
#
#    return $self;
#}


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

