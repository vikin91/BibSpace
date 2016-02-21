package Hex64Publications::Controller::Authors;

use Hex64Publications::Functions::AuthorsFunctions;

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

use Hex64Publications::Controller::Core;
use Hex64Publications::Controller::Publications;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';

##############################################################################################################
sub show {
    my $self = shift;
    my $dbh = $self->app->db;
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

    my @uinq_master_id = $dbh->resultset('Author')->search(
        {'master_id' => {'!=', undef}},
        {columns => [{ 'd_master_id' => { distinct => 'me.master_id' } }],}
        )->get_column('d_master_id')->all;

    print Dumper(\@uinq_master_id);
    
    my @authors;
    my $ars = $dbh->resultset('Author')->search_rs({id => {'in' => \@uinq_master_id}});

    @authors = $ars->all;

    for my $a (@authors){
        say $a->uid;#get_column('uid');
    }

    if(defined $visible and $visible eq '1'){
        $ars = $ars->search_rs({'display' => 1});
    }
    if(defined $search and $search ne '%'){
        $ars = $ars->search_rs({ 'master' => { like => $search } });
      $qry .= "AND master LIKE ? ";
    }
    elsif(defined $letter and $letter ne '%'){
        $ars = $ars->search_rs({ 'master' => { like => $letter } });
      # $qry .= "AND let LIKE ? ";
      $qry .= "AND substr(master, 1, 1) LIKE ? "; # mysql
      
    }
    # $qry .= "GROUP BY master_id ORDER BY display DESC, master ASC";
    $qry .= "ORDER BY display DESC, master ASC";

    @authors = $ars->all;

    my $sth = $dbh->prepare_cached( $qry );  
    $sth->execute(@params); 

   
   my @autorzy_id_arr;
   my @autorzy_names_arr;
   my %autorzy_display;

   my $i = 1;
   while(my $row = $sth->fetchrow_hashref()) {
      my $master = $row->{master} || "000 This author has no master_id!" . "<BR>";


      # my $disp = $row->{display} || "0";

    my @letters = $dbh->resultset('Author')->search(
        {},
        {
          columns => [{ 'd_letter' => { distinct => { SUBSTR => 'master, 1, 1' } } }],
        }
    )->get_column('d_letter')->all;

      # my $id = get_author_id_for_master($dbh, $master);
      my $mid = $master_id; #get_master_id_for_master($dbh, $master);

    $self->write_log("Show authors: visible $visible, letter $letter, search $search");
    say "Show authors: visible $visible, letter $letter, search $search";


   # get_set_of_first_letters($self, $visible);
      push @autorzy_names_arr, $master;

      $autorzy_display{$mid} = $disp;
      $i++;
   }

   
   my @letters = get_set_of_first_letters($self, $visible);
   $self->stash(visible => $visible, authors  => \@authors, letters => \@letters);

   $self->render(template => 'authors/authors');
 }
##############################################################################################################
sub add_author {
   my $self = shift;
   my $back_url = $self->param('back_url') || "/publications";

   my $dbh = $self->app->db;


   $self->stash(master  => '', id => '', back_url => $back_url);
   $self->render(template => 'authors/add_author');
}

##############################################################################################################
### POST like for HTML forms, not a blog post
sub add_post {
     my $self = shift;
     my $dbh = $self->app->db;
     my $new_master = $self->param('new_master');

     
     if(defined $new_master){
        my $num = $dbh->resultset('Author')->search({'uid' => $new_master})->count;
        say "num authors with $new_master = $num";
        if($num == 0){

          # my $sth = $dbh->prepare('INSERT INTO Author(uid, master) VALUES(?, ?)');
          # $sth->execute($new_master, $new_master);
          # my $aid = $dbh->last_insert_id(undef, undef, 'Author', 'id');

          my $new_user = $dbh->resultset('Author')->find_or_create({ 
                                        uid => $new_master,
                                        master => $new_master,
                                        display => 1,
                                        });

          # my $a = $dbh->resultset('Author')->find({ 'master' => $new_master})->first;
          $new_user->update({'master_id' => $new_user->id});

              my $sth2 = $dbh->prepare('UPDATE Author SET master_id=?, display=1 WHERE id=?');
              $sth2->execute($aid, $aid);

          # my $sth2 = $dbh->prepare('UPDATE Author SET master_id=?, display=1 WHERE id=?');
                  $self->flash(msg => "Something went wrong. The Author has not beed added");
          # $sth2->execute($aid, $aid);
                  return;
              }

          $self->write_log("add new author: Added new author with proposed master ($new_master). Author id is ".$new_user->id);

          $self->redirect_to('/authors/edit/'.$new_user->id); 
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
   my $back_url = $self->param('back_url') || "/authors";

   my $dbh = $self->app->db;
   my $master = get_master_for_id($dbh, $id);

   my $a = $dbh->resultset('Author')->search({id => $id})->first;

   $self->redirect_to('/authors') unless defined $a;
   my @aids;

   my $qry = "SELECT master, uid, id, display
               FROM Author 
   my @uids = $dbh->resultset('Author')->search({master_id => $id})->get_column('uid')->all;
   my @aids = $dbh->resultset('Author')->search({master_id => $id})->get_column('id')->all;
   $sth->execute($id); 

   my $disp = 0;
   while(my $row = $sth->fetchrow_hashref()) {
      my $uid = $row->{uid} || "no_id";
      my $aid = $row->{id} || "-1";
      $disp = 1 if $row->{display} == 1;
      push @uids, $uid;
      push @aids, $aid;
   }

   my $teams_a = $self->app->db->resultset('AuthorToTeam')->search(
            {'author_id' => $id},
            { 
                join => 'team', 
   }
            );


    my @a2t = $teams_a->all;
    my @all_teams = $dbh->resultset('Team')->all; # CHANGE TO ALL WHERE NOT MEMBER
    my @tag_ids = (); # TODO: Query this

   my ($tag_ids_arr_ref, $tags_arr_ref) = get_tags_for_author($self, $id);

   $self->stash(author => $a, all_teams => \@all_teams,  tag_ids => \@tag_ids, back_url => $back_url, exit_code => '');

   # $self->stash(master  => $master, id => $id, uids => \@uids, aids => \@aids, disp => $disp, 
   #              teams => \@teams_arr, team_ids => \@team_id_arr, start_arr => \@start_arr, stop_arr =>\@stop_arr, back_url => $back_url, exit_code => '',
   #              tag_ids => \@tag_ids_arr_ref, tags => \@tags_arr_ref,
   #              all_teams => \@all_teams_arr, all_teams_ids => \@all_teams_ids_arr);
   $self->render(template => 'authors/edit_author');
}
##############################################################################################################
sub can_be_deleted{
  my $self = shift;
  my $id = shift;

  my $dbh = $self->app->db;

  my $a = $dbh->resultset('Author')->search({id => $id})->first;

  return $a->can_be_deleted();
  my $num_teams = scalar @$teams_arr;


  # my ($teams_arr, $start_arr, $stop_arr, $team_id_arr) = get_teams_of_author($self, $id);
  # my $num_teams = scalar @$teams_arr;
  # return 1 if $num_teams == 0 and $visibility == 0;
  # return 0;
}
##############################################################################################################
sub add_to_team {
    my $self = shift;
    my $dbh = $self->app->db;
    my $master_id = $self->param('id');
    my $team_id = $self->param('tid');

    my $a = $dbh->resultset('Author')->search({id => $master_id})->first;
    $dbh->resultset('AuthorToTeam')->find_or_create({
            team_id => $team_id, 
            author_id => $master_id
            });
    $self->write_log("Author with master id $master_id becomes a member of team with id $team_id.");

    my $back_url = $self->param('back_url') || "/authors?visible=1";
    $self->redirect_to($back_url);
};
##############################################################################################################
sub remove_from_team {
    my $self = shift;
    my $dbh = $self->app->db;
    my $master_id = $self->param('id');
    my $team_id = $self->param('tid');

    my $a = $dbh->resultset('AuthorToTeam')->search({team_id => $team_id, author_id => $master_id})->delete;
    
    # $a->delete_related('author_to_teams', { team_id => $team_id });  # removes all memebers of the team

    # remove_team_for_author($self, $master_id, $team_id);

    my $back_url = $self->param('back_url') || "/authors?visible=1";
    $self->redirect_to($back_url);
};
##############################################################################################################
sub remove_uid{
    my $self = shift;
    my $dbh = $self->app->db;
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
     my $dbh = $self->app->db;

     my $id = $self->param('id');
    my $a = $dbh->resultset('Author')->search({id => $id})->first;
     
    # my @cols   = $a->result_source->columns;
    # say "======";
    # for my $c (@cols) {
    #     my $val = $a->get_column( $c );
    #     say "$c: $val";
    # }
    # say "======";


     my $master = $a->master;

     my $new_master = $self->param('new_master');
     my $new_user_id = $self->param('new_user_id');

     my $visibility = $self->param('visibility');


     if(defined $master){
         if(defined $new_master){
            $a->update({'master' => $new_master});

            my $status = 0; #update_master_id($self, $id, $new_master);

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
            $a->toggle_visibility();
         }
         elsif(defined $new_user_id){

            my $new_user = $dbh->resultset('Author')->find_or_create({ 
              if($success==0){
                                uid => $new_user_id,
                                master_id => $a->id,
                                master => $a->master,
                                });
              }
              }
         }
     $self->redirect_to('/authors/edit/'.$id);
}
##############################################################################################################
sub post_edit_membership_dates{
     my $self = shift;
     my $dbh = $self->app->db;

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
    my $dbh = $self->app->db;

    # double check!
    if(defined $aid and $aid > 0 and defined $tid and $tid > 0 and defined $new_start and $new_start >= 0 and defined $new_stop and $new_stop >= 0 and ($new_stop == 0 or $new_start <= $new_stop)){
        my $rs = $dbh->resultset('AuthorToTeam')->search({'team_id' => $tid, 'author_id' => $aid})->update({start => $new_start, stop => $new_stop});
        $sth->execute($new_start, $new_stop, $aid, $tid); 
    }
}
##############################################################################################################
sub delete_author {
     my $self = shift;
     my $dbh = $self->app->db;
     my $id = $self->param('id');

     my $visibility = get_visibility_for_id($self, $id);

     my $a = $dbh->resultset('Author')->search({id => $id})->first;
     if($a->can_be_deleted()){
        $a->delete;
     }

    my $back_url = "/authors?visible=1";
    $self->redirect_to($back_url);
     
};
##############################################################################################################
sub delete_author_force {
     my $self = shift;
     my $dbh = $self->app->db;
     my $id = $self->param('id');

    my $a = $dbh->resultset('Author')->search({id => $id})->first->delete;
    
    
    $self->flash(msg => "Author with id $id removed successfully.");
    $self->write_log("Author with id $id removed successfully.");

    # say "delete_author_force: going back to: $back_url";

    my $back_url = "/authors?visible=1";
    $self->redirect_to($back_url);
     
};
##############################################################################################################
sub do_delete_author_force {
     my $self = shift;
     my $dbh = $self->app->db;
     my $id = shift;

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
};
##############################################################################################################
sub add_new_user_id_to_master{
  my $self = shift; 
  my $id = shift;
  my $new_user_id = shift;
  my $dbh = $self->app->db;

  # checking if such an uid already exists
  my $aid = get_author_id_for_uid($dbh, $new_user_id);
  my $master_str = get_master_for_id($dbh, $id);
  
  my $sth = $dbh->prepare('INSERT IGNORE INTO Author(uid, master, master_id) VALUES(?, ?, ?)');
  # adding only if doenst exist yet
  if($aid eq '-1'){
      $sth->execute($new_user_id, $master_str, $id);  
      return 0;
  }
  else{
      say "add_new_user_id_to_master: author ID already exists. aid: $aid. Master for this ais is:  $master_str";
      say "calling: add_new_user_id_to_master_force($id, $new_user_id)";
      return add_new_user_id_to_master_force($self, $id, $new_user_id);
  }
}

##############################################################################################################
sub add_new_user_id_to_master_force{
  my $self = shift; 
  my $id = shift;
  my $new_user_id = shift;
  my $dbh = $self->app->db;

  # checking if such an uid already exists
  my $aid = get_author_id_for_uid($dbh, $new_user_id);  # SELECT id FROM Author WHERE uid=?
  my $master_str = get_master_for_id($dbh, $id); # SELECT master FROM Author WHERE id=?
  
  # my $sth = $dbh->prepare('INSERT IGNORE INTO Author(uid, master, master_id) VALUES(?, ?, ?)');
  # aid is <> than -1 if such author already exists
  if($aid ne '-1'){
      
      # duplicate uid (user to be merged): $aid
      # master id (user to be merged with): $id

      my $sth3 = $dbh->prepare('UPDATE Entry_to_Author SET author_id=? WHERE author_id=?');
      $sth3->execute($id, $aid);

      my $sth4 = $dbh->prepare('UPDATE Author_to_Team SET author_id=? WHERE author_id=?');
      $sth4->execute($id, $aid);

      do_delete_author_force($self, $aid);

      return add_new_user_id_to_master($self, $id, $new_user_id);
  }
  else{
      add_new_user_id_to_master($self, $id, $new_user_id);
  }
}

##############################################################################################################
sub remove_user_id_from_master{
  my $self = shift; 
  my $mid = shift;
  my $uid = shift;
  my $dbh = $self->app->db;
  
  
  # cannot remove aid that is muid, because you would remove the user completly
  if($mid != $uid){
        my $a = $dbh->resultset('Author')->search({master_id => $mid, id => $uid})->first->delete;

  }
  else{
    say "remove_user_id_from_master: cannot remove aid that is muid, because you would remove the user completly";
  }
}
##############################################################################################################
sub update_master_id{
    my $self = shift;
    my $id = shift;
    my $new_master = shift;
    my $dbh = $self->app->db;

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
   
#    my $dbh = $self->app->db;

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

#    my $master = get_master_for_id($self->app->db, $id);
#    delete_author_master($self, $master);
   
#    my $back_url = $self->param('back_url') || "/authors?visible=1";
#    $self->redirect_to($back_url);
# };
##############################################################################################################

 sub get_set_of_first_letters {
   my $self = shift;
   my $dbh = $self->app->db;
   my $visible = shift or undef;

   my $sth = undef;
   if(defined $visible and $visible eq '1'){
      # $sth = $dbh->prepare( "SELECT DISTINCT substr(master, 0, 2) as let FROM Author WHERE display=1 ORDER BY let ASC" ); 
      $sth = $dbh->prepare( "SELECT DISTINCT substr(master, 1, 1) as let FROM Author WHERE display=1 ORDER BY let ASC" ); 
   }
   else{
      # $sth = $dbh->prepare( "SELECT DISTINCT substr(master, 0, 2) as let FROM Author ORDER BY let ASC" );   
      $sth = $dbh->prepare( "SELECT DISTINCT substr(master, 1, 1) as let FROM Author ORDER BY let ASC" );   
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
   
   my $dbh = $self->app->db;

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
    my $dbh = $self->app->db;

    postprocess_all_entries_after_author_uids_change($self);

    my $back_url = $self->param('back_url') || "/authors?visible=1";
    $self->redirect_to($back_url);
}
##############################################################################################################
sub reassign_authors_to_entries_and_create_authors {
    my $self = shift;
    my $dbh = $self->app->db;

    postprocess_all_entries_after_author_uids_change_w_creating_authors($self);

    my $back_url = $self->param('back_url') || "/authors?visible=1";
    $self->redirect_to($back_url);
}

##############################################################################################################

 sub toggle_visibility {
   my $self = shift;
   my $id = $self->param('id');

   my $dbh = $self->app->db;

    my $a = $dbh->resultset('Author')->search({ id => $id })->first;
    my $disp = $a->display;

   if($disp == 1){

        $dbh->resultset('Author')->search({ id => $id })->update({display => 0});
   }
   else{
        $dbh->resultset('Author')->search({ id => $id })->update({display => 1});
   }
   }
    $disp = $a->display;
    


   $self->write_log("Author with id $id has now visibility set to $disp");
   say "Author with id $id has now visibility set to $disp";

   
   $sth2->finish() if defined $sth2;

   my $back_url = $self->param('back_url') || "/authors?visible=1";
   $self->redirect_to($back_url);
};

##############################################################################################################

1;
