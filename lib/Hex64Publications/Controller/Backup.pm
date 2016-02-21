package Hex64Publications::Controller::Backup;

use Data::Dumper;
use utf8;
use Text::BibTeX; # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010; #because of ~~
use strict;
use warnings;
use DBI;
use File::Copy qw(copy);

use Hex64Publications::Controller::Core;
use Hex64Publications::Functions::BackupFunctions;
use Hex64Publications::Controller::DB;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;



####################################################################################
# sub backup_db_file {
#   my $backup_dir = "./backups";
#   my $str = Time::Piece::localtime->strftime('%Y%m%d-%H%M%S');
#   my $dbfname = $backup_dir."/backup-full-db-".$str.".db";

#   copy("bib.db", $dbfname);
#   return $dbfname;
# }


####################################################################################
sub save {
    my $self = shift;
    my $back_url = $self->param('back_url') || "/";
    $back_url = "/" if $back_url eq $self->req->url->to_abs;

    my $return_value = do_backup_current_state($self, "normal");

    if(defined $return_value){
        $self->flash(msg => "Backup created succesfully");
    }
    else{
        $self->flash(msg => "Backup create failed!");
    }
    
    $self->redirect_to('/backup');
}

####################################################################################
sub cleanup {
    my $self = shift;
    my $back_url = $self->param('back_url') || "/";
    $back_url = "/" if $back_url eq $self->req->url->to_abs;

    my $num_deleted = do_delete_broken_or_old_backup($self);

    $self->flash(msg => "$num_deleted backups have been cleaned.");
    
    $self->redirect_to('/backup');
}

####################################################################################

sub index {
    my $self = shift;
    # my $backup_dbh = $self->app->backup_db;
    my $backup_dbh = $self->app->db;
    my $back_url = $self->param('back_url') || '/backup';

    say "call: Backup::backup";  

    create_backup_table($backup_dbh);

    my $sth = $backup_dbh->prepare("SELECT id, creation_time, filename FROM Backup ORDER BY creation_time DESC");
    $sth->execute();

    my $dir_size = 0;
    $dir_size = get_dir_size("backups");
    $dir_size = $dir_size >> 20;

    my @ctime_arr;
    my @fname_arr;
    my @id_arr;
    my @exists_arr;

    my $i = 1;
    while(my $row = $sth->fetchrow_hashref()) {
      my $id = $row->{id};

      $self->can_delete_backup($id);

      my $fname = $row->{filename};
      my $exists = 0;
      $exists = 1 if -e $fname;

      my $ctime = $row->{creation_time};
      push @exists_arr, $exists;
      push @ctime_arr, $ctime;
      push @fname_arr, $fname;
      push @id_arr, $id;
    }

    $self->stash(back_url => $back_url, ids => \@id_arr, fnames => \@fname_arr, ctimes => \@ctime_arr, exists => \@exists_arr, dir_size => $dir_size);
    $self->render(template => 'backup/backup');
}

####################################################################################

sub backup_download {
    my $self = shift;
    # my $backup_dbh = $self->app->backup_db;
    my $backup_dbh = $self->app->db;

    my $back_url = $self->param('back_url') || '/backup'; 
    my $backup_file = $self->param('file'); 

    $backup_file =~ s/\///g;
    my $ext = ".sql";


    my $file_path = "backups/".$backup_file.$ext;
    my $public_file_system = "public/backups/".$backup_file.$ext;

    copy($file_path, $public_file_system);
    
    my $exists = 0;
    $exists = 1 if -e $public_file_system;

    say $public_file_system;
    say "exists $exists";

    if($exists == 1){
        $self->write_log("downloading backup $file_path");
        $self->redirect_to("/".$file_path);
    }
    else{
        $self->redirect_to("/backup");
    }
}

####################################################################################
sub delete_backup{  # modified 22.08.14
    my $self = shift;
    # my $backup_dbh = $self->app->backup_db;
    my $backup_dbh = $self->app->db;
    my $back_url = $self->param('back_url') || '/backup';  
    my $id = $self->param('id');

    create_backup_table($backup_dbh);

    if( $self->can_delete_backup($id) == 1 ){
        do_delete_backup($self, $id);
    }

    $self->redirect_to("/backup");
}

####################################################################################
sub restore_backup{
    my $self = shift;
    # my $backup_dbh = $self->app->backup_db;
    my $backup_dbh = $self->app->db;
    my $back_url = $self->param('back_url') || '/backup';  
    my $id = $self->param('id');

    my $return_value = do_restore_backup($self, $id);

    if($return_value ==1){
        $self->flash(msg => "Backup restored succesfully");
    }
    else{
        $self->flash(msg => "Backup restore failed!");
    }

    $self->redirect_to('/backup');
    # $self->redirect_to($back_url);
}



####################################################################################

1;