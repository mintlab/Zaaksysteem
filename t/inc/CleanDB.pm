package CleanDB;

use FindBin;

use lib "$FindBin::Bin/../lib";

use Moose;

with
    'CleanDB::SQLite',
    'CleanDB::PostgreSQL';

has [qw/
    in_env
    type
    source_db
    source_dbg
    db
    dbg
    db_dsn
    dbg_dsn
/] => (
    'is'    => 'rw'
);

=head2 CONSTRUCTION

=head3 Prepare Constructor

Define the clean source DBs

=cut

=head3 Construct temporarily files

=cut

sub _load_db {
    my  $self   = shift;
}


sub BUILD {
    my $self    = shift;

    if ($self->in_env && $self->type) {
        $ENV{TEST_DBTYPE} = $self->type;
    }

    $self->type($ENV{TEST_DBTYPE}) if ($ENV{TEST_DBTYPE});

    $self->_load_db;

    unless ($self->db && $self->dbg) {
        die('CleanDB: No valid DB found');
    }
}

=head2 DESTRUCTION

Delete temporarily files

=cut

sub _destroy_db {
    my $self    = shift;

}

sub DEMOLISH {
    my ($self) = @_;

    $self->_destroy_db;

}

1;
