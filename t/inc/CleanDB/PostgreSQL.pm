package CleanDB::PostgreSQL;

use Moose::Role;

use DBI;
use FindBin;

has ['db_name','dbg_name'] => (
    'is'    => 'ro',
);

after '_load_db'    => sub {
    my $self    = shift;

    if ($self->type && lc($self->type eq 'pg')) {
        $self->_load_postgresql;
    }
};

after '_destroy_db'    => sub {
    my $self    = shift;

    if ($self->type && lc($self->type eq 'pg')) {
        $self->_destroy_postgresql;
    }
};

sub _destroy_postgresql {
    my $self    = shift;

    if (
        (!$ENV{'clean_db'} || $self->in_env) &&
        !$ENV{TEST_KEEP} &&
        $self->db
    ) {
        $self->_destroy_postgresql_db($self->db);
    }

    if (
        (!$ENV{'clean_dbg'} || $self->in_env) &&
        !$ENV{TEST_KEEP} &&
        $self->dbg
    ) {
        $self->_destroy_postgresql_db($self->dbg);
    }
}

sub _destroy_postgresql_db {
    my $self        = shift;
    my $db_name     = shift;

    ### Protect
    die('CleanDB: Database must be in form unit_test_DBSECTION_ID')
        unless ($db_name =~ /unit_test_.*?_\d+/);

    my $dbh = DBI->connect('dbi:Pg:dbname=template1')
        or die('CleanDB: Could not connect to source db: template1');

    my $q   = $dbh->prepare("SELECT COUNT(*) FROM pg_database WHERE datname=?");
    $q->execute($db_name);
    my $row = $q->fetchrow_hashref();

    return unless $row->{count};

    unless (
        $dbh->do("DROP DATABASE " . $db_name)
    ) {
        die('CleanDB: Could not remove testdb: ' . $db_name . ' in PostgreSQL');
    }

}

sub _generate_postgresql_db {
    my $self        = shift;
    my $db_source   = shift;

    my $dbh = DBI->connect('dbi:Pg:dbname=template1')
        or die('CleanDB: Could not connect to source db: template1');

    my $db_name = $db_source . '_test_' . $$;

    ### Check DB
    my $q   = $dbh->prepare("SELECT COUNT(*) FROM pg_database WHERE datname=?");
    $q->execute($db_name);
    my $row = $q->fetchrow_hashref();

    die('CleanDB: Found existing test db: ' . $db_name . ' in PostgreSQL')
        if $row->{count};

    ### Check NEW DB
    unless (
        $dbh->do("CREATE DATABASE " . $db_name . " WITH TEMPLATE " . $db_source)
    ) {
        die('CleanDB: Could not create testdb: ' . $db_name . ' in PostgreSQL');
    }

    return $db_name;
}

sub _load_postgresql {
    my $self    = shift;

    $self->source_db(   $self->db_name || 'unit_test_beheer'    );
    $self->source_dbg(  $self->dbg_name || 'unit_test_gegevens' );

    if ($ENV{'clean_db'}) {
        $self->db($ENV{'clean_db'});
    } else {
        $self->db(  $self->_generate_postgresql_db( $self->source_db )  );
        if ($self->in_env) {
            $ENV{'clean_db'} = $self->db;
        }
    }

    if ($ENV{'clean_dbg'}) {
        $self->dbg($ENV{'clean_dbg'});
    } else {
        $self->dbg( $self->_generate_postgresql_db( $self->source_dbg ) );
        if ($self->in_env) {
            $ENV{'clean_dbg'} = $self->dbg;
        }
    }

    return unless ($self->db && $self->dbg);

    $self->db_dsn(  'dbi:Pg:dbname=' . $self->db    );
    $self->dbg_dsn( 'dbi:Pg:dbname=' . $self->dbg   );
}

1;
