package BibSpace::Functions::MySqlBackupFunctions;

use BibSpace::Functions::FDB;
use BibSpace::Functions::Core;

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
    dump_mysql_to_file
    can_delete_backup
    do_mysql_db_backup_silent
    do_mysql_db_backup
    do_delete_backup
    do_delete_broken_or_old_backup
    get_backup_filename_by_id
    do_restore_backup_from_file
    do_backup_current_state
    get_backup_id
    get_backup_creation_time
    get_backup_age_in_days
);
####################################################################################
sub dump_mysql_to_file {
    my $fname = shift;
    my $config = shift;


    my $db_host     = $config->{db_host};
    my $db_user     = $config->{db_user};
    my $db_database = $config->{db_database};
    my $db_pass     = $config->{db_pass};

    my @ignored_tables = ( "Token", "Backup" );

    my $ignored_tables_string = "";
    for my $ign_tab (@ignored_tables) {
        $ignored_tables_string .= " --ignore-table=$db_database.$ign_tab";
    }

    my $command_prefix = "mysqldump --skip-comments --no-autocommit";

    try{
        if ( $db_pass =~ /^\s*$/ ) {    # password empty
            `$command_prefix -u $db_user $db_database $ignored_tables_string > $fname`;
        }
        else {
            `$command_prefix -u $db_user -p$db_pass $db_database $ignored_tables_string > $fname`;
        }
    }
    catch{

    };
    return $fname;
}
####################################################################################
sub can_delete_backup {
    my $dbh  = shift;
    my $bid  = shift;
    my $config = shift; # exception - we need this here
    

    my $backup_dir_absolute = $config->{backups_dir};
    $backup_dir_absolute =~ s!/*$!/!;

    my $b_fname = get_backup_filename_by_id( $dbh, $bid );
    my $file_path = $backup_dir_absolute . $b_fname;

    my $file_exists = 0;
    $file_exists = 1 if -e $file_path;
    my $b_age = get_backup_age_in_days( $dbh, $bid );

    my $age_limit = $config->{allow_delete_backups_older_than};

    return 1 if $file_exists == 1 and $b_age >= $age_limit;
    return 1 if $file_exists == 0;
    return 0;
}
####################################################################################
sub do_mysql_db_backup_silent {
    my $self = shift;
    my $fname_prefix = shift || "normal";
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

    my $command_prefix = "mysqldump --skip-comments --no-autocommit";

    if ( $db_pass =~ /^\s*$/ ) {    # password empty
        `$command_prefix -u $db_user $db_database $ignored_tables_string > $db_fname_path`;
    }
    else {
        `$command_prefix -u $db_user -p$db_pass $db_database $ignored_tables_string > $db_fname_path`;
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

    my $dbh = $self->app->db;
    my $dbfname = do_mysql_db_backup_silent( $self, $fname_prefix );
    
    if ( !defined $dbfname or $dbfname eq "" ) {
        return "";
    }
    else {
        my $sth = $dbh->prepare(
            "REPLACE INTO Backup(creation_time, filename) VALUES (NOW(), ?)");
        $sth->execute($dbfname);
        $sth->finish();
        # $dbh->commit();
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

    $self->app->logger->info("destroying backup id $id");

    my $sth2 = $dbh->prepare("DELETE FROM Backup WHERE id=?");
    $sth2->execute($id);
    # $dbh->commit();
    unlink $file_path;
}
####################################################################################
sub do_delete_broken_or_old_backup {    # added 22.08.14 # TODO: refactor -get rid of self!
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
        my $b_age            = get_backup_age_in_days( $backup_dbh, $id );
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
    my $app       = shift;
    my $dbh       = shift;
    my $file_path = shift;
    my $config    = shift;

    # I assume that $file_path is the SQL dump that I want to restore

    my $file_exists = 0;
    if ( -e $file_path ) {
        $file_exists = 1;
    }
    else {
        $app->logger->warn("Cannot restore database from file $file_path. I stop now.",__PACKAGE__." do_restore_backup_from_file ");
        return;
    }

    
    try{
        $dbh->{mysql_auto_reconnect} = 0;
        $dbh->disconnect();
    }
    catch{
        $app->logger->error("Cannot disconnect: $_",__PACKAGE__." do_restore_backup_from_file ");
    };

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
        $app->logger->error("Restoring DB failed from file $file_path. Reason: $_. Status? $?. Command_output: $command_output.",
            __PACKAGE__." do_restore_backup_from_file ");
        db_connect($db_host, $db_user, $db_database, $db_pass);
        $app->db; # this will reconnect
        $app->db->{mysql_auto_reconnect} = 1;
    };

    $app->db(); # this will reconnect
    $app->db->{mysql_auto_reconnect} = 1;

    if ( $? == 0 ) {
        $app->repo->hardReset;
        $app->setup_repositories;

        $app->logger->info("Restoring backup succeeded from file $file_path");
        return 1;
    }
    else {
        $app->logger->error("Restoring backup FAILED from file $file_path");
        return;
    }
}
####################################################################################
sub do_backup_current_state {
    my $self = shift;
    my $fname_prefix = shift // "normal";

    $self->app->logger->info("creating backup with prefix $fname_prefix");
    return do_mysql_db_backup( $self, $fname_prefix );
}
################################################################################
 


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
    my $dbh       = shift;
    my $bid        = shift;

    my $sth
        = $dbh->prepare(
        "SELECT id, ABS(TIMESTAMPDIFF(DAY, CURRENT_TIMESTAMP, creation_time)) as age FROM Backup WHERE id=? LIMIT 1"
        );
    $sth->execute($bid);
    my $row = $sth->fetchrow_hashref();

    my $ret = -1;
    $ret = $row->{age} if defined $row->{age} and $row->{age} >= 0;
    return $ret;
}

################################################################################

####################################################################################
1;
