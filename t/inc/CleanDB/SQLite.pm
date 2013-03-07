package CleanDB::SQLite;

use Moose::Role;

use FindBin;
use File::Copy;
use File::Temp qw/tmpnam/;

after '_load_db'    => sub {
    my $self    = shift;

    if (!$self->type || lc($self->type eq 'sqlite')) {
        $self->_load_sqlite;
    }
};

after '_destroy_db'    => sub {
    my $self    = shift;

    if (!$self->type || lc($self->type eq 'sqlite')) {
        $self->_destroy_sqlite;
    }
};

sub _destroy_sqlite {
    my $self    = shift;

    if (
        (!$ENV{'clean_db'} || $self->in_env) && !$ENV{TEST_KEEP}
    ) {
        unlink($self->db) if $self->db;
    }

    if (
        (!$ENV{'clean_dbg'} || $self->in_env) && !$ENV{TEST_KEEP}
    ) {
        unlink($self->dbg) if $self->dbg;
    }

}

sub _load_sqlite {
    my $self    = shift;

    $self->source_db(   $FindBin::Bin . '/../db/db.db'  );
    $self->source_dbg(  $FindBin::Bin . '/../db/dbg.db' );

    if ($ENV{'clean_db'} && -f $ENV{'clean_db'}) {
        $self->db($ENV{'clean_db'});
    } else {
        $self->db(scalar tmpnam());
        if ($self->in_env) {
            $ENV{'clean_db'} = $self->db;
        }
    }

    if ($ENV{'clean_dbg'} && -f $ENV{'sqlite_dbg'}) {
        $self->dbg($ENV{'clean_dbg'});
    } else {
        $self->dbg(scalar tmpnam());
        if ($self->in_env) {
            $ENV{'clean_dbg'} = $self->dbg;
        }
    }

    return unless ($self->db && $self->dbg);

    $self->db_dsn(  'dbi:SQLite:' . $self->db   );
    $self->dbg_dsn( 'dbi:SQLite:' . $self->dbg  );

    copy($self->source_db, $self->db);
    copy($self->source_dbg, $self->dbg);
}

1;
