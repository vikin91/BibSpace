package BibSpace::Functions::BackupFunctions;

use BibSpace::Functions::MySqlBackupFunctions;
use BibSpace::Model::Backup;
use BibSpace::Functions::Core;
use BibSpace::Functions::FDB;

use Storable;

use Data::Dumper;
use utf8;

use DateTime;
use Try::Tiny;
use v5.16;           #because of ~~

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
    delete_old_backups
);
## Trivial DAO FIND
## TODO: port it to Path::Tiny
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
    my $name = shift // 'normal';

    my $backup_dir_absolute = $app->config->{backups_dir};
    $backup_dir_absolute =~ s!/*$!/!;  

    my $backup = Backup->create($name, "storable");
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
    my $name = shift // 'normal';

    my $backup_dir_absolute = $app->config->{backups_dir};
    $backup_dir_absolute =~ s!/*$!/!;  

    my $backup = Backup->create($name, "mysql");
    $backup->dir($backup_dir_absolute);
    dump_mysql_to_file( $backup->get_path, $app->config );

    return $backup;
}
####################################################################################
sub restore_storable_backup {
    my $backup = shift;
    my $app    = shift;

    my $layer = retrieve($backup->get_path);

    say "restore_storable_backup has retrieved:" . $layer->get_summary_table;

    ## this writes to all layers!!

    my @layers = $app->repo->lr->get_all_layers;
    foreach (@layers){ $_->reset_data };
    $app->repo->lr->reset_uid_providers;

    # say "Smart layer after reset:" . $app->repo->lr->get_layer('smart')->get_summary_table;

    my $layer_to_replace = $app->repo->lr->get_read_layer;
    $app->repo->lr->replace_layer($layer_to_replace->name, $layer);

    foreach my $layer (@layers){ 
        next if $layer->name eq $layer_to_replace->name;

        $app->repo->lr->copy_data( { from => $layer_to_replace->name, to => $layer->name } );
    };    

    # say "Smart layer after replace:" . $app->repo->lr->get_layer('smart')->get_summary_table;

    

    say "restore_storable_backup DONE. Smart layer after copy_data:" . $app->repo->lr->get_layer('smart')->get_summary_table;
    say "restore_storable_backup DONE. All layer after copy_data:" . $app->repo->lr->get_summary_table;
}
####################################################################################
sub delete_old_backups {
    my $app    = shift;
    my $age_treshold = shift // $app->config->{backup_age_in_days_to_delete_automatically};

    my $num_deleted = 0;

    my @backups_arr = sort {$b->date cmp $a->date} read_backups($app->backup_dir);
    foreach my $backup (@backups_arr){
        my $age = $backup->get_age->days;
        if( $age >= $age_treshold ){
            ++$num_deleted;
            unlink $backup->get_path;
        }
    }
    return $num_deleted;
}
####################################################################################
1;
