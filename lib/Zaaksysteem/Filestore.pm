package Zaaksysteem::Filestore;


use strict;
use warnings;

use Data::Dumper;
use Data::Serializer;

use Moose;

#
# todo move this to a proper generic situation
#
use Digest::MD5::File qw/-nofatals file_md5_hex/;
use constant FILESTORE_DB           => 'DB::Filestore';

sub _store_file {
    my ($self, $c, $upload, %options) = @_;

    # store in DB
    my $options     = {
        'filename'      => $options{filename},
        'filesize'      => $upload->size,
        'mimetype'      => $upload->type,
    };

    my $filestore   = $c->model(FILESTORE_DB)->create($options);

    if (!$filestore) {
        $c->log->error(
            '_store_file: Kan filestore entry niet aanmaken: '
            . $options{filename}
        );
        $c->flash->{result} = 'ERROR: Kan bestand niet aanmaken op omgeving';
        return;
    }

    # Store on system

    my $destination = $self->_path($c, $filestore->id);
    $c->log->debug("destination:" . $destination);
    if (!$upload->copy_to($destination)) {
        $filestore->delete;
        $c->log->error(
            '_store_file: Kan bestand niet kopieren: '
            . $options{filename} . ' -> ' . $destination
        );
        $c->flash->{result} = 'ERROR: Kan bestand niet kopieren naar omgeving';
        return;
    }

    # Stored on system and database, now fill in other fields

    # md5sum
    {
        my $md5sum = file_md5_hex($destination);
        $filestore->md5sum($md5sum);
    }

    $filestore->update;

    return $filestore->id
}


sub _path {
    my ($self, $c, $filestore_id) = @_;

    my $files_dir   = $c->config->{files} . '/filestore';
    my $destination = $files_dir . '/' . $filestore_id;

    return $destination;
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

