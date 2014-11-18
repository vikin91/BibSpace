package AdminApi::Authors;

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

use AdminApi::Core;
use AdminApi::Publications;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';

##############################################################################################################
sub show {
    my $self = shift;
    my $dbh = $self->db;
    my $visible = $self->param('visible') || 0;
    my $search = $self->param('search') || '%';
    my $letter = $self->param('letter') || '%';

   if($letter ne '%'){
      $letter.='%';
   }
   if($search ne '%'){
      $search = '%'.$search;
      $search.='%';
   }

    my @params;
    my $qry = "SELECT master_id, id, master, display, substr(master, 0, 2) as let FROM Author WHERE master NOT NULL ";

    if(defined $visible and $visible eq '1'){
        $qry .= "AND display=1 ";
    }
    if(defined $search and $search ne '%'){
      push @params, $search;
      $qry .= "AND master LIKE ? ";
    }
    elsif(defined $letter and $letter ne '%'){
      push @params, $letter;
      $qry .= "AND let LIKE ? ";
    }
    $qry .= "GROUP BY master_id ORDER BY display DESC, master ASC";

    $self->write_log("Show authors: visible $visible, letter $letter, search $search");

    my $sth = $dbh->prepare_cached( $qry );  
    $sth->execute(@params); 

   
   my @autorzy_id_arr;
   my @autorzy_names_arr;
   my %autorzy_display;

   my $i = 1;
   while(my $row = $sth->fetchrow_hashref()) {
      my $master = $row->{master} || "000 This author has no master_id!" . "<BR>";


      # my $disp = $row->{display} || "0";

      my $master_id = $row->{master_id};
      my $id = $row->{id};
      $master_id = $id if !defined $master_id;

      # my $id = get_author_id_for_master($dbh, $master);
      my $mid = $master_id; #get_master_id_for_master($dbh, $master);

      my $disp = get_visibility_for_id($self, $mid);      

      push @autorzy_id_arr, $mid;
      push @autorzy_names_arr, $master;

      $autorzy_display{$mid} = $disp;
      $i++;
   }

   
   my @letters = get_set_of_first_letters($self, $visible);
   $self->stash(visible => $visible, names_arr  => \@autorzy_names_arr, disp => \%autorzy_display, letters => \@letters, ids_arr => \@autorzy_id_arr);

   $self->render(template => 'authors/authors');
 }
##############################################################################################################
sub add_author {
   my $self = shift;
   my $back_url = $self->param('back_url') || "/publications";

   my $dbh = $self->db;


   $self->stash(master  => '', id => '', back_url => $back_url);
   $self->render(template => 'authors/add_author');
}

##############################################################################################################
### POST like for HTML forms, not a blog post
sub add_post {
     my $self = shift;
     my $dbh = $self->db;
     my $new_master = $self->param('new_master');

     
     if(defined $new_master){

          my $existing_author = get_master_id_for_uid($dbh, $new_master);
          if($existing_author == -1){

              my $sth = $dbh->prepare('INSERT INTO Author(uid, master) VALUES(?, ?)');
              $sth->execute($new_master, $new_master);
              my $aid = $dbh->last_insert_id(undef, undef, 'Author', 'id');


              my $sth2 = $dbh->prepare('UPDATE Author SET master_id=?, display=1 WHERE id=?');
              $sth2->execute($aid, $aid);

              if(!defined $aid){
                  $self->flash(msg => "Something went wrong. The Author has not beed added");
                  $self->redirect_to('/authors/add');
                  return;
              }

              $self->write_log("add new author: Added new author with proposed master ($new_master). Author id is $aid.");

              $self->redirect_to('/authors/edit/'.$aid); 
              return;
          }
          else{
            $self->write_log("add new author: author with proposed master ($new_master) exists!");
            $self->flash(msg => "Author with such MasterID exists! Pick a different one.");
            $self->redirect_to('/authors/add');
            return;
          }
     }
     
     $self->redirect_to('/authors/add');
}
##############################################################################################################
sub edit_author {
   my $self = shift;
   my $id = $self->param('id');
   my $back_url = $self->param('back_url') || "/publications";

   my $dbh = $self->db;
   my $master = get_master_for_id($dbh, $id);

   $self->write_log("edit_author: master: $master. id: $id.");

   my @uids;
   my @aids;

   my $qry = "SELECT master, uid, id, display
               FROM Author 
               WHERE master_id=?";
   my $sth = $dbh->prepare( $qry );  
   $sth->execute($id); 

   my $disp = 0;
   while(my $row = $sth->fetchrow_hashref()) {
      my $uid = $row->{uid} || "no_id";
      my $aid = $row->{id} || "-1";
      $disp = 1 if $row->{display} == 1;
      push @uids, $uid;
      push @aids, $aid;
   }

   my ($all_teams_arr, $all_teams_ids_arr) = get_all_teams($dbh);

   my ($teams_arr, $start_arr, $stop_arr, $team_id_arr) = get_teams_of_author($self, $id);

   my ($tag_ids_arr_ref, $tags_arr_ref) = get_tags_for_author($self, $id);


   $self->stash(master  => $master, id => $id, uids => \@uids, aids => \@aids, disp => $disp, 
                teams => $teams_arr, team_ids => $team_id_arr, start_arr => $start_arr, stop_arr => $stop_arr, back_url => $back_url, exit_code => '',
                tag_ids => $tag_ids_arr_ref, tags => $tags_arr_ref,
                all_teams => $all_teams_arr, all_teams_ids => $all_teams_ids_arr);
   $self->render(template => 'authors/edit_author');
}
##############################################################################################################
sub can_be_deleted{
  my $self = shift;
  my $id = shift;

  my $visibility = get_visibility_for_id($self, $id);


  my ($teams_arr, $start_arr, $stop_arr, $team_id_arr) = get_teams_of_author($self, $id);
  my $num_teams = scalar @$teams_arr;


  return 1 if $num_teams == 0 and $visibility == 0;
  return 0;
}
##############################################################################################################
sub add_to_team {
    my $self = shift;
    my $dbh = $self->db;
    my $master_id = $self->param('id');
    my $team_id = $self->param('tid');

    add_team_for_author($self, $master_id, $team_id);

    my $back_url = $self->param('back_url') || "/authors?visible=1";
    $self->redirect_to($back_url);
};
##############################################################################################################
sub remove_from_team {
    my $self = shift;
    my $dbh = $self->db;
    my $master_id = $self->param('id');
    my $team_id = $self->param('tid');

    remove_team_for_author($self, $master_id, $team_id);

    my $back_url = $self->param('back_url') || "/authors?visible=1";
    $self->redirect_to($back_url);
};
##############################################################################################################
sub remove_uid{
    my $self = shift;
    my $dbh = $self->db;
    my $muid = $self->param('id');
    my $uid = $self->param('uid');

    remove_user_id_from_master($self, $muid, $uid);

    my $back_url = $self->param('back_url') || "/authors?visible=1";
    $self->redirect_to($back_url);

}

##############################################################################################################
### POST like for HTML forms, not a blog post
sub edit_post {
     my $self = shift;
     my $dbh = $self->db;

     my $id = $self->param('id');
     my $master = get_master_for_id($dbh, $id);
     my $new_master = $self->param('new_master');
     my $new_user_id = $self->param('new_user_id');

     my $visibility = $self->param('visibility');


     if(defined $master){
         if(defined $new_master){
               my $status = update_master_id($self, $id, $new_master);
               # 0 OK
               # -1 conflict 
               # >0 new master id
               if($status > 0){
                  $self->write_log("change master for master id $id and new master $new_master - status: $status. AUTHOR ID HAS CHANGED!");
                  $self->redirect_to('/authors/edit/'.$status);
               }
               else{
                  $self->write_log("change master for master id $id and new master $new_master - status: $status. SUCH AUTHOR EXISTS ALREADY under id $status!");
                  $self->redirect_to('/authors/edit/'.$id); 
               }
               
         }
         elsif(defined $visibility){
               toggle_visibility($self, $id);
         }
         elsif(defined $new_user_id){
              my $success = add_new_user_id_to_master($self, $id, $new_user_id);
              if($success==0){
                  $self->write_log("add_new_user_id_to_master for master id $id and new_user_id $new_user_id was succesfull.");  
              }
              else{
                  $self->write_log("add_new_user_id_to_master for master id $id and new_user_id $new_user_id was UNSUCCESSFUL: such user already exists.");   
              }
         }
     }
     $self->redirect_to('/authors/edit/'.$id);
}
##############################################################################################################
sub post_edit_membership_dates{
     my $self = shift;
     my $dbh = $self->db;

     my $aid = $self->param('aid');
     my $tid = $self->param('tid');
     my $new_start = $self->param('new_start');
     my $new_stop = $self->param('new_stop');
     

     $self->write_log("post_edit_membership_dates: aid $aid, tid $tid, new_start $new_start, new_stop $new_stop");

     if(defined $aid and $aid > 0 and defined $tid and $tid > 0){
        if($new_start >= 0 and $new_stop >= 0){
            if($new_stop == 0 or $new_start <= $new_stop){
                $self->write_log("post_edit_membership_dates: input valid. Changing");
                $self->do_edit_membership_dates($aid, $tid, $new_start, $new_stop);
            }
            else{
                $self->write_log("post_edit_membership_dates: input INVALID. start later than stop");
            }
        }
        else{
            $self->write_log("post_edit_membership_dates: input INVALID. start or stop negative");
        }
     }
     else{
        $self->write_log("post_edit_membership_dates: input INVALID. author_id or team_id invalid");
    }
    $self->redirect_to('/authors/edit/'.$aid);
}
##############################################################################################################
sub do_edit_membership_dates{
    my $self = shift;
    my $aid = shift;
    my $tid = shift;
    my $new_start = shift;
    my $new_stop = shift;
    my $dbh = $self->db;

    # double check!
    if(defined $aid and $aid > 0 and defined $tid and $tid > 0 and defined $new_start and $new_start >= 0 and defined $new_stop and $new_stop >= 0 and ($new_stop == 0 or $new_start <= $new_stop)){
        my $sth = $dbh->prepare('UPDATE Author_to_Team SET start=?, stop=? WHERE author_id=? AND team_id=?');
        $sth->execute($new_start, $new_stop, $aid, $tid); 
    }
}
##############################################################################################################
sub delete_author {
     my $self = shift;
     my $dbh = $self->db;
     my $id = $self->param('id');

     my $visibility = get_visibility_for_id($self, $id);

     if(defined $id and $id != -1 and can_be_deleted($self, $id)==1){
        delete_author_force($self);
        return;
     }

    my $back_url = $self->param('back_url') || "/authors?visible=1";
    $self->redirect_to($back_url);
     
};
##############################################################################################################
sub delete_author_force {
     my $self = shift;
     my $dbh = $self->db;
     my $id = $self->param('id');

     my $visibility = get_visibility_for_id($self, $id);

     if(defined $id and $id != -1){
        my $sth = $dbh->prepare('DELETE FROM Author WHERE master_id=?');
        $sth->execute($id);  

        my $sth2 = $dbh->prepare('DELETE FROM Author WHERE id=?');
        $sth2->execute($id);

        my $sth3 = $dbh->prepare('DELETE FROM Entry_to_Author WHERE author_id=?');
        $sth3->execute($id);

        my $sth4 = $dbh->prepare('DELETE FROM Author_to_Team WHERE author_id=?');
        $sth4->execute($id);
     }

    
    my $back_url = $self->param('back_url') || "/authors?visible=1";
    $self->redirect_to($back_url);
     
};

##############################################################################################################
sub add_new_user_id_to_master{
  my $self = shift; 
  my $id = shift;
  my $new_user_id = shift;
  my $dbh = $self->db;

  # checking if such an uid already exists
  my $aid = get_author_id_for_uid($dbh, $new_user_id);
  my $master_str = get_master_for_id($dbh, $id);
  
  my $sth = $dbh->prepare('INSERT OR IGNORE INTO Author(uid, master, master_id) VALUES(?, ?, ?)');
  # adding only if doenst exist yet
  if($aid eq '-1'){
      $sth->execute($new_user_id, $master_str, $id);  
      return 0;
  }
  else{
      say "aid: $aid";
      say "master_str: $master_str";
      return -1;
  }
}
##############################################################################################################
sub remove_user_id_from_master{
  my $self = shift; 
  my $mid = shift;
  my $uid = shift;
  my $dbh = $self->db;
  
  # cannot remove aid that is muid, because you would remove the user completly
  if($mid != $uid){
      my $sth = $dbh->prepare('DELETE FROM Author WHERE id=? AND master_id=?');
      $sth->execute($uid, $mid);  
  }
}
##############################################################################################################
sub update_master_id{
    my $self = shift;
    my $id = shift;
    my $new_master = shift;
    my $dbh = $self->db;

    my $ret = 0;
    # 0 - change - OK
    # -1 - new_master exists!!

    my $existing_master_id = get_master_id_for_uid($dbh, $new_master);

    if($existing_master_id == -1){ # the new proposed master name is unique

      my $old_master = get_master_for_id($dbh, $id);
      $self->write_log("Updating master id for user: $old_master. New muid: $new_master.");

      my $sth = $dbh->prepare( "UPDATE Author SET uid=?, master=? WHERE master_id=? AND id=?" );  
      $sth->execute($new_master, $new_master, $id, $id);

      my $sth2 = $dbh->prepare( "UPDATE Author SET master=? WHERE master_id=?" );  
      $sth2->execute($new_master, $id);

      $ret = 0;
    }
    else{    # the new proposed master name exists already in DB!
      $ret = -1 * $existing_master_id;

    }
   

    my $new_master_id = get_author_id_for_master($dbh, $new_master);

    if($new_master_id != -1 and $new_master_id != $id and $ret == 0){   #something has changed in the DB

        $ret = $new_master_id;

        my $sth3 = $dbh->prepare( "UPDATE Entry_to_Author SET author_id=? WHERE author_id=?" );  
        $sth3->execute($new_master_id, $id);

        my $sth4 = $dbh->prepare( "UPDATE Author_to_Team SET author_id=? WHERE author_id=?" );  
        $sth4->execute($new_master_id, $id);
    }

    return $ret;
};

##############################################################################################################
# sub delete_author_master{
#    my $self = shift;
#    my $master = shift;
   
#    my $dbh = $self->db;

#    $self->write_log("Deleting author: $master.");

#    my $sth = $dbh->prepare( "DELETE FROM Authors WHERE master=?" );  
#    $sth->execute($master); 

#    my $sth2 = $dbh->prepare( "DELETE FROM Author_to_Team WHERE author=?" );  
#    $sth2->execute($master); 

#    my $sth3 = $dbh->prepare( "DELETE FROM Entry_to_Author WHERE author=?" );  
#    $sth3->execute($master); 
# };
# ##############################################################################################################
# sub delete_author_id{
#    my $self = shift;
#    my $id = $self->param('id') ;

#    my $master = get_master_for_id($self->db, $id);
#    delete_author_master($self, $master);
   
#    my $back_url = $self->param('back_url') || "/authors?visible=1";
#    $self->redirect_to($back_url);
# };
##############################################################################################################

 sub get_set_of_first_letters {
   my $self = shift;
   my $dbh = $self->db;
   my $visible = shift or undef;

   my $sth = undef;
   if(defined $visible and $visible eq '1'){
      $sth = $dbh->prepare( "SELECT DISTINCT substr(master, 0, 2) as let FROM Author
         WHERE display=1
         ORDER BY let ASC" ); 
   }
   else{
      $sth = $dbh->prepare( "SELECT DISTINCT substr(master, 0, 2) as let FROM Author
         ORDER BY let ASC" );   
   }
   $sth->execute(); 

   my @letters;
   while(my $row = $sth->fetchrow_hashref()) {
      my $letter = $row->{let} || "*";
      push @letters, uc($letter);
   }
   @letters = uniq(@letters);
   return sort(@letters);
 }
##############################################################################################################
sub get_visibility_by_name {
   my $self = shift;
   my $name = shift;
   
   my $dbh = $self->db;

   my $sth;
   $sth = $dbh->prepare( "SELECT display FROM Author WHERE master=? AND uid=?" );
   $sth->execute($name, $name); 
   
   my $row = $sth->fetchrow_hashref();
   my $disp = $row->{display};

   return $disp;

}
##############################################################################################################
sub reassign_authors_to_entries {
    my $self = shift;
    my $dbh = $self->db;

    postprocess_all_entries_after_author_uids_change($self);

    my $back_url = $self->param('back_url') || "/authors?visible=1";
    $self->redirect_to($back_url);
}
##############################################################################################################
sub reassign_authors_to_entries_and_create_authors {
    my $self = shift;
    my $dbh = $self->db;

    postprocess_all_entries_after_author_uids_change_w_creating_authors($self);

    my $back_url = $self->param('back_url') || "/authors?visible=1";
    $self->redirect_to($back_url);
}

##############################################################################################################

 sub toggle_visibility {
   my $self = shift;
   my $id = $self->param('id');

   my $dbh = $self->db;
   my $master = get_master_for_id($dbh, $id);
   my $disp = get_visibility_for_id($self, $id);

   my $sth2;

   $sth2 = $dbh->prepare('UPDATE Author SET display=? WHERE id=?');
   if($disp == 1){
      $sth2->execute(0, $id); 
   }
   else{
      $sth2->execute(1, $id); 
   }

   $self->write_log("Author with id $id has now visibility set to $disp");
   say "Author with id $id has now visibility set to $disp";

   
   $sth2->finish() if defined $sth2;

   my $back_url = $self->param('back_url') || "/authors?visible=1";
   $self->redirect_to($back_url);
};

##############################################################################################################

1;