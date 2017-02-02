package BibSpace::Functions::BackupFunctions;

use BibSpace::Functions::MySqlBackupFunctions;
use BibSpace::Model::Backup;
use BibSpace::Functions::Core;

use Storable;

use Data::Dumper;
use utf8;

use DateTime;
use Try::Tiny;
use 5.010;           #because of ~~

use strict;
use warnings;

use Exporter;
our @ISA = qw( Exporter );

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw(
    find_backup
    read_backups
    do_storable_backup
    do_mysql_backup
    restore_storable_backup
);
## Trivial DAO FIND
####################################################################################
sub find_backup {
    my $uuid = shift;
    my $dir = shift;

    my @file_list;
    try{
        opendir(D, "$dir") or die;
        @file_list = readdir(D);
        closedir(D);
    }
    catch{
        warn;
    };

    my @backups;

    foreach my $file (@file_list){
        next unless $file =~ /^backup/;
        next unless $file =~ /\.dat$/ or $file =~ /\.sql$/;
        next unless $file =~ /$uuid/;

        my $backup;
        try{
            $backup = Backup->parse($file);
            $backup->dir($dir);
        }
        catch{
            # wrong format = wrong file - ignore
        };
        return $backup;
    }
    return;
}
## Trivial DAO ALL
####################################################################################
sub read_backups {
    my $dir = shift;

    my @file_list;
    try{
        opendir(D, "$dir") or die;
        @file_list = readdir(D);
        closedir(D);
    }
    catch{
        warn;
    };

    my @backups;

    foreach my $file (@file_list){
        next unless $file =~ /^backup/;
        next unless $file =~ /\.dat$/ or $file =~ /\.sql$/;

        my $backup; 
        try{
            $backup = Backup->parse($file);
            $backup->dir($dir);
            push @backups, $backup;
        }
        catch{
            # wrong format = wrong file - ignore
        };
    }
    return @backups;
}
####################################################################################
sub do_storable_backup {
    my $app = shift;

    my $backup_dir_absolute = $app->config->{backups_dir};
    $backup_dir_absolute =~ s!/*$!/!;  

    my $backup = Backup->create("normal", "storable");
    $backup->dir($backup_dir_absolute);


    my $layer = $app->repo->lr->get_read_layer;
    my $path = "".$backup->get_path;

    $Storable::forgive_me = "do store regexp please";
    Storable::store $layer, $path;

    return $backup;
}
####################################################################################
sub do_mysql_backup {
    my $app = shift;

    my $backup_dir_absolute = $app->config->{backups_dir};
    $backup_dir_absolute =~ s!/*$!/!;  

    my $backup = Backup->create("normal", "mysql");
    $backup->dir($backup_dir_absolute);
    dump_mysql_to_file( $backup->get_path, $app->config );

    return $backup;
}
####################################################################################
sub restore_storable_backup {
    my $backup = shift;
    my $app    = shift;

    my $layer = retrieve($backup->get_path);
    $app->repo->lr->replace_layer('smart', $layer);

}
####################################################################################
1;
