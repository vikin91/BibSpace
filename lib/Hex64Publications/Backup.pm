package Hex64Publications::Backup;

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

use Hex64Publications::Core;

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
sub do_backup_current_state{
    my $self = shift;
    my $fname_prefix = shift || "normal";

    prepare_backup_table($self->app->backup_db);
    dump_db_to_bib_team($self, "full");

    $self->write_log("creating backup with prefix $fname_prefix");
    # return  $self->helper_do_backup_current_state($fname_prefix); # sqlite
    return  $self->helper_do_mysql_backup_current_state($fname_prefix); # mysql
    

    # my $backup_dbh = $self->app->backup_db;  
    # my $normal_dbh = $self->app->db;

    # my $backup_dir = "./backups";
    # my $str = Time::Piece::localtime->strftime('%Y%m%d-%H%M%S');
    # my $dbfname = $backup_dir."/backup-".$fname_prefix."-full-db-".$str.".db";

    

    # $normal_dbh->disconnect();
    # copy("bib.db", $dbfname);

    
    # my $sth = $backup_dbh->prepare("INSERT INTO Backup(creation_time, filename) VALUES (datetime('now','localtime'), ?)");
    # $sth->execute($dbfname);
    
    # return $dbfname;
}
####################################################################################
sub save {
    my $self = shift;
    my $backup_dbh = $self->app->backup_db;  
    my $normal_dbh = $self->app->db;
    my $back_url = $self->param('back_url') || "/";
    $back_url = "/" if $back_url eq $self->req->url->to_abs;

    do_backup_current_state($self, "normal");
    
    $self->redirect_to('/backup');
}

####################################################################################
sub delete_broken_or_old_backup {
    my $self = shift;
    my $back_url = $self->param('back_url') || "/";
    $back_url = "/" if $back_url eq $self->req->url->to_abs;

    do_delete_broken_or_old_backup($self);
    
    $self->redirect_to('/backup');
}

####################################################################################

sub backup {
    my $self = shift;
    my $backup_dbh = $self->app->backup_db;
    my $back_url = $self->param('back_url') || '/backup';  

    prepare_backup_table($backup_dbh);

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
    my $backup_dbh = $self->app->backup_db;
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
    my $backup_dbh = $self->app->backup_db;
    my $back_url = $self->param('back_url') || '/backup';  
    my $id = $self->param('id');

    prepare_backup_table($backup_dbh);

    if( $self->can_delete_backup($id) == 1 ){
        do_delete_backup($self, $id);
    }

    $self->redirect_to("/backup");
}


####################################################################################
sub restore_backup_sqlite{
    my $self = shift;
    my $backup_dbh = $self->app->backup_db;
    my $back_url = $self->param('back_url') || '/backup';  
    my $id = $self->param('id');

    prepare_backup_table($backup_dbh);

    my $sth = $backup_dbh->prepare("SELECT filename FROM Backup WHERE id = ?");
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref();
    my $fname = $row->{filename};

    # $self->app->db->disconnect();
    
    # saving current state with special prefix to provide the possibility to restore the pre-restore state 
    do_backup_current_state($self, "pre-restore");

    $self->write_log("restoring backup from file $fname");

    unlink "bib.db";
    copy($fname, "bib.db");


    $self->redirect_to('/backup');
    # $self->redirect_to($back_url);
}
####################################################################################
sub restore_backup{
    my $self = shift;
    my $backup_dbh = $self->app->backup_db;
    my $back_url = $self->param('back_url') || '/backup';  
    my $id = $self->param('id');

    prepare_backup_table($backup_dbh);

    my $sth = $backup_dbh->prepare("SELECT filename FROM Backup WHERE id = ?");
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref();
    my $fname = $row->{filename};

    $self->app->db->disconnect();
    
    # saving current state with special prefix to provide the possibility to restore the pre-restore state 
    do_backup_current_state($self, "pre-restore");

    $self->write_log("Cleaning the whole DB before restoring.");

    # $self->app->db->do("SET autocommit=0");
    # $self->app->db->do("SET foreign_key_checks=0");
    # $self->app->db->do("START TRANSACTION");

    # $self->app->db->do("TRUNCATE TABLE Author_to_Team");
    # $self->app->db->do("TRUNCATE TABLE Entry_to_Author");
    # $self->app->db->do("TRUNCATE TABLE Entry_to_Tag");
    # $self->app->db->do("TRUNCATE TABLE Exceptions_Entry_to_Team");
    # $self->app->db->do("TRUNCATE TABLE OurType_to_Type");
    # $self->app->db->do("TRUNCATE TABLE Tag");
    # $self->app->db->do("TRUNCATE TABLE TagType");
    # $self->app->db->do("TRUNCATE TABLE Entry");
    # $self->app->db->do("TRUNCATE TABLE Team");
    # $self->app->db->do("TRUNCATE TABLE Author");

    # $self->app->db->do("SET foreign_key_checks=1");
    # $self->app->db->do("SET autocommit=1");
    # $self->app->db->do("COMMIT");

    $self->write_log("restoring backup from file $fname");

    my $db_host = $self->config->{db_host};
    my $db_user = $self->config->{db_user};
    my $db_database = $self->config->{db_database};
    my $db_pass = $self->config->{db_pass};


    my $cmd = "mysql -u $db_user -p$db_pass $db_database  < $fname";
    say "cmd: $cmd";
    `$cmd`;

    if ($? == 0){
        say "Restoring backup succeded from file $fname";
        `head -n 100 $fname`;
        say "---";
        say "---";
    }
    else{
        say "Restoring backup FAILED from file $fname";
    }


    $self->redirect_to('/backup');
    # $self->redirect_to($back_url);
}


####################################################################################

sub dump_db_to_bib_team{
  my $self = shift;
  my $team = shift;
  my $backup_dbh = $self->app->backup_db;  
  my $normal_dbh = $self->app->db;
  my $teamid = get_team_id($normal_dbh, $team);

  prepare_backup_table($backup_dbh);

  # my $config = $self->conf;
  # my $config = $self->app->plugin('Config');
  # my $backup_dir = $config->{backupdir} || "./backups";
  
  my $backup_dir = "./backups";
  my $str = Time::Piece::localtime->strftime('%Y%m%d-%H%M%S');
  my $fname = $backup_dir."/backup-".$team."-".$str.".bak.bib";

  # my $dbfname = $backup_dir."/backup-full-db-".$str.".db";

  # log_to_backup_table($backup_dbh, $dbfname);

  # $self->app->db->disconnect();
  # copy("bib.db", $dbfname);

  # $normal_dbh = $self->app->db;
  
  

  my $sth = undef;

  if(! defined $team or $team eq 'full'){
      $team = "full";
      $sth = $normal_dbh->prepare( "SELECT DISTINCT bib FROM Entry ORDER BY year DESC, bibtex_key ASC" );  
      $sth->execute();
  }
  else{
      $sth = $normal_dbh->prepare( "SELECT DISTINCT bib
      FROM Entry
      LEFT JOIN Exceptions_Entry_to_Team  ON Entry.id = Exceptions_Entry_to_Team.entry_id 
      LEFT JOIN Entry_to_Author ON Entry.id = Entry_to_Author.entry_id
      LEFT JOIN Author_to_Team ON Entry_to_Author.author_id = Author_to_Team.author_id       
         WHERE Entry.bibtex_key IS NOT NULL
         AND ((Exceptions_Entry_to_Team.team_id = ? ) OR (Author_to_Team.team_id = ?))
         ORDER BY Entry.year DESC, Entry.bibtex_key ASC" );  
      $sth->execute($teamid, $teamid);
  }

  $self->write_log("Dumping bib form DB for team: $team");
 
  
  say "saving bib dump to file $fname";
  
  write_file( $fname, {append => 0 }, undef );


  while(my $row = $sth->fetchrow_hashref()) {
      my $bib = $row->{bib} || " ";
      write_file( $fname, {append => 1 }, $bib );
   }
}
####################################################################################

1;