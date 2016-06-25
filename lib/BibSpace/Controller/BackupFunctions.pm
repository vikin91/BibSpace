package BibSpace::Controller::BackupFunctions;

use BibSpace::Functions::FDB;
use BibSpace::Controller::Core;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use File::Slurp;
use File::Find;
use Time::Piece;
use Try::Tiny;
use 5.010;           #because of ~~
use Cwd;
use strict;
use warnings;

use Exporter;
our @ISA = qw( Exporter );

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw(
    do_mysql_db_backup_silent
    do_mysql_db_backup
    do_delete_backup
    do_delete_broken_or_old_backup
    get_backup_filename_by_id
    do_restore_backup_by_id
    do_restore_backup_from_file
    do_backup_current_state
    get_dir_size
    get_backup_id
    get_backup_creation_time
    get_backup_age_in_days
);

####################################################################################
# TODO: This function should be moved to a separate file, e.g. BackupFunctions.pm
# The same for the other functions related to a given controller ..
sub do_mysql_db_backup_silent {
    my $self = shift;
    my $fname_prefix = shift || "normal";

    say "call: BackupFunctions::do_mysql_db_backup_silent";

    # my $backup_dbh = $self->app->db;
    my $dbh = $self->app->db;

    my $backup_dir_absolute = $self->config->{backups_dir};
    $backup_dir_absolute
        =~ s!/*$!/!;    # makes sure that there is exactly one / at the end

    # say "backup_dir_absolute: $backup_dir_absolute";

    my $str      = Time::Piece::localtime->strftime('%Y%m%d-%H%M%S');
    my $db_fname = "backup-" . $fname_prefix . "-full-db-" . $str . ".sql";

    # say "db_fname: $db_fname";
    my $db_fname_path = $backup_dir_absolute . $db_fname;

    # say "db_fname_path: $db_fname_path";

    my $db_host     = $self->config->{db_host};
    my $db_user     = $self->config->{db_user};
    my $db_database = $self->config->{db_database};
    my $db_pass     = $self->config->{db_pass};

    my @ignored_tables = ( "Token", "Login", "Backup" );

    my $ignored_tables_string = "";
    for my $ign_tab (@ignored_tables) {
        $ignored_tables_string .= " --ignore-table=$db_database.$ign_tab";
    }

    # say $ignored_tables_string;

    if ( $db_pass =~ /^\s*$/ ) {    # password empty
        `mysqldump -u $db_user $db_database $ignored_tables_string > $db_fname_path`;
    }
    else {
        `mysqldump -u $db_user -p$db_pass $db_database $ignored_tables_string > $db_fname_path`;
    }
    if ( $? == 0 ) {
        return $db_fname;
    }
    return "";

}
####################################################################################
sub do_mysql_db_backup {
    my $self = shift;
    my $fname_prefix = shift || "normal";

    say "call: BackupFunctions::do_mysql_db_backup";

    my $dbh = $self->app->db;
    my $dbfname = do_mysql_db_backup_silent( $self, $fname_prefix );
    if ( !defined $dbfname or $dbfname eq "" ) {
        return "";
    }
    else {
        my $sth = $dbh->prepare(
            "REPLACE INTO Backup(creation_time, filename) VALUES (NULL, ?)");
        $sth->execute($dbfname);
        $sth->finish();
        return $dbfname;
    }

}

####################################################################################
sub do_delete_backup {    # added 22.08.14
    my $self = shift;
    my $id   = shift;
    my $dbh  = $self->app->db;

    say "call BackupFunctions::do_delete_backup";

    my $backup_dir_absolute = $self->config->{backups_dir};
    $backup_dir_absolute =~ s!/*$!/!;

    my $sth = $dbh->prepare("SELECT filename FROM Backup WHERE id = ?");
    $sth->execute($id);
    my $row   = $sth->fetchrow_hashref();
    my $fname = $row->{filename};

    my $file_path = $backup_dir_absolute . $fname;
    my $exists    = 0;
    $exists = 1 if -e $file_path;

    # say "do_delete_backup deletes file: $file_path exists $exists";

    $self->write_log("destroying backup id $id");

    my $sth2 = $dbh->prepare("DELETE FROM Backup WHERE id=?");
    $sth2->execute($id);
    unlink $file_path;
}
####################################################################################
sub do_delete_broken_or_old_backup {    # added 22.08.14
    my $self       = shift;
    my $backup_dbh = $self->app->db;

    my $sth
        = $backup_dbh->prepare(
        "SELECT id, creation_time, filename FROM Backup ORDER BY creation_time DESC"
        );
    $sth->execute();

    my $backup_age_in_days_to_delete_automatically
        = $self->config->{backup_age_in_days_to_delete_automatically};
    my $file_age_counter = 1
        ; # 1 (one) backup will not be deleted for files older than $backup_age_in_days_to_delete

    my @ids;
    my @backup_file_names;

    my $backup_dir_absolute = $self->config->{backups_dir};
    $backup_dir_absolute
        =~ s!/*$!/!;    # makes sure that there is exactly one / at the end

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $id               = $row->{id};
        my $backup_file_name = $row->{filename};

        push @ids,               $id;
        push @backup_file_names, $backup_file_name;
    }

    my $i           = 0;
    my $num_deleted = 0;
    foreach my $id (@ids) {
        my $b_age            = get_backup_age_in_days( $self, $id );
        my $backup_file_name = $backup_file_names[$i];
        my $exists           = 0;

        my $backup_file_path = $backup_dir_absolute . $backup_file_name;
        $exists = 1 if -e $backup_file_path;

        if ( $exists == 0 ) {

            # CAN DELETE
            do_delete_backup( $self, $id );
            $num_deleted = $num_deleted + 1;
        }
        else {    # file exists
            if ( $b_age > $backup_age_in_days_to_delete_automatically ) {

                # we delete only automatically-created backups
                if ( $backup_file_name =~ /cron/ ) {
                    if ( $file_age_counter > 0 ) {   # we leave some untouched
                        $file_age_counter = $file_age_counter - 1;
                    }
                    else {                           # rest should be deleted
                        do_delete_backup( $self, $id );
                        $num_deleted = $num_deleted + 1;
                    }
                }
            }
        }
        $i = $i + 1;
    }
    say "do_delete_broken_or_old_backup: num_deleted $num_deleted";
    return $num_deleted;
}

####################################################################################
sub get_backup_filename_by_id {
    my $dbh = shift;
    my $id  = shift;

    my $sth
        = $dbh->prepare("SELECT id, filename FROM Backup WHERE id=? LIMIT 1");
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref();
    return $row->{filename} || "";
}
####################################################################################
sub do_restore_backup_from_file {
    my $dbh       = shift;
    my $file_path = shift;
    my $config    = shift;

    say "CALL: do_restore_backup_from_file";

    # I assume that $file_path is the SQL dump that I want to restore

    my $file_exists = 0;
    if ( -e $file_path ) {
        $file_exists = 1;
    }
    else {
        warn "Cannot restore database from file $file_exists. I stop now.";
        return 0;
    }

    #$dbh->disconnect() if defined $dbh;

    my $db_host     = $config->{db_host};
    my $db_user     = $config->{db_user};
    my $db_database = $config->{db_database};
    my $db_pass     = $config->{db_pass};

    my $cmd = "mysql -u $db_user -p$db_pass $db_database  < $file_path";
    if ( $db_pass =~ /^\s*$/ ) {    # password empty
        $cmd = "mysql -u $db_user $db_database  < $file_path";
    }
    my $command_output = "";
    try {
        $command_output = `$cmd`;
    }
    catch {
        say
            "Restoring DB failed from file $file_path. Reason: $_. Status? $?. Command_output: $command_output.";

        # say "Command was: $cmd";
        return 0;
    };

    if ( $? == 0 ) {
        say "Restoring backup succeeded from file $file_path";
        return 1;
    }
    else {
        say "Restoring backup FAILED from file $file_path";
        return 0;
    }
}
####################################################################################
sub do_backup_current_state {
    my $self = shift;
    my $fname_prefix = shift || "normal";

    say "call: Backup::do_backup_current_state";
    say "creating backup with prefix $fname_prefix";

    $self->write_log("creating backup with prefix $fname_prefix");
    return do_mysql_db_backup( $self, $fname_prefix );

}
################################################################################

sub get_dir_size {
    my $dir  = shift;
    my $size = 0;

    find( sub { $size += -f $_ ? -s _ : 0 }, $dir );

    return $size;
}

####################################################################################
sub get_backup_id {
    my $self     = shift;
    my $filename = shift;
    my $dbh      = $self->app->db;

    my $sth = $dbh->prepare(
        "SELECT id, filename FROM Backup WHERE filename=? LIMIT 1");
    $sth->execute($filename);
    my $row = $sth->fetchrow_hashref();
    return $row->{id} || 0;
}
####################################################################################
sub get_backup_creation_time {
    my $self = shift;
    my $bip  = shift;
    my $dbh  = $self->app->db;

    my $sth = $dbh->prepare(
        "SELECT creation_time FROM Backup WHERE id=? LIMIT 1");
    $sth->execute($bip);
    my $row = $sth->fetchrow_hashref();
    return $row->{creation_time} || 0;
}
####################################################################################
sub get_backup_age_in_days {
    my $self       = shift;
    my $bid        = shift;
    my $backup_dbh = $self->app->db;

# mysql: SELECT TIMESTAMPDIFF(SECOND, '2010-11-29 13:13:55', '2010-11-29 13:16:55')
    my $sth
        = $backup_dbh->prepare(
        "SELECT id, ABS(TIMESTAMPDIFF(DAY, CURRENT_TIMESTAMP, creation_time)) as age FROM Backup WHERE id=? LIMIT 1"
        );

# my $sth = $backup_dbh->prepare("SELECT (julianday('now', 'localtime') - julianday(creation_time)) as age FROM Backup WHERE id=? LIMIT 1");
    $sth->execute($bid);
    my $row = $sth->fetchrow_hashref();

    my $ret = -1;
    $ret = $row->{age} if defined $row->{age} and $row->{age} >= 0;

    # say "call: Core::get_backup_age_in_days. Returning $ret";
    return $ret;
}

################################################################################

####################################################################################
1;
