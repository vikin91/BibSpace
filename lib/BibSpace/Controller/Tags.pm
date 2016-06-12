package BibSpace::Controller::Tags;

use strict;
use warnings;
use Data::Dumper;
use utf8;
use Text::BibTeX; # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010; #because of ~~
use DBI;
use Scalar::Util qw(looks_like_number);

use BibSpace::Controller::Core;
use BibSpace::Functions::TagTypeObj;
use BibSpace::Controller::Set;

use BibSpace::Model::MTag;
use BibSpace::Model::MTagCloud;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;



####################################################################################

sub index {
    my $self = shift;
    my $dbh = $self->app->db;
    my $letter = $self->param('letter') || '%';
    my $type = $self->param('type') || 1;

    if($letter ne '%'){
        $letter.='%';
    }


    my @all_with_letter = MTag->static_get_all_w_letter($dbh, $type, $letter);
    my @letters_arr = get_first_letters($self, $type);

    $self->stash(otags => \@all_with_letter, type => $type, letters_arr => \@letters_arr);
    $self->render(template => 'tags/tags');
}

####################################################################################
sub get_first_letters{
    my $self = shift;
    my $dbh = $self->app->db;
    my $type = shift || 1;

    my $sth = $dbh->prepare( "SELECT DISTINCT substr(name, 0, 2) as let FROM Tag WHERE type=? ORDER BY let ASC" ); 
    $sth->execute($type); 
    my @letters;
    while(my $row = $sth->fetchrow_hashref()) {
      my $letter = $row->{let} || "*";
      push @letters, uc($letter);
    }

    return @letters;
}
####################################################################################
sub add_tags_from_string {
    my $self = shift;
    my $tags_to_add = shift;
    my $type = shift || 1;
    my $dbh = $self->app->db;

    my @tag_ids;
    my @tags_arr;

    say "call: add_tags_from_string";

    say "tags_to_add $tags_to_add";

    if(defined $tags_to_add){

        my @pre_tags_arr = split(';', $tags_to_add);
        

        foreach my $tag(@pre_tags_arr){
            $tag = clean_tag_name($tag);

            if(defined $tag and $tag ne '' and length($tag)>0){
               push @tags_arr, $tag if defined $tag;
               $self->write_log("Adding new tag ->".$tag."<-");
            }
        }

        

        foreach my $tag (@tags_arr) {
            my $qry = 'INSERT IGNORE INTO Tag(name, type) VALUES (?,?)';
            my $sth = $dbh->prepare( $qry );  
            $sth->execute($tag, $type); 
            $sth->finish();
        } 
        
    
        foreach my $tag(@tags_arr){
            my $sth2 = $dbh->prepare( "SELECT id FROM Tag WHERE name=? AND type=?" );  
            $sth2->execute($tag, $type);
            my $row = $sth2->fetchrow_hashref();
            my $id = $row->{id} || -1;
            push @tag_ids, $id if $id > -1;
            $sth2->finish();
        }
   }

   return @tag_ids;

}
####################################################################################
sub add {
    my $self = shift;
    my $dbh = $self->app->db;
    my $type = $self->param('type') || 1;

    $self->render(template => 'tags/add', type => $type);
}

####################################################################################
sub add_post {
    my $self = shift;

    my $dbh = $self->app->db;
    my $type = $self->param('type') || 1;

    my $tags_to_add = $self->param('new_tag');
    my @tag_ids = add_tags_from_string($self, $tags_to_add, $type);

    if(scalar @tag_ids >0 ){
        $self->flash(msg  => "The following tags (of type $type) were added successfully: <i>$tags_to_add</i> , ids: <i>".join(", ",@tag_ids)."</i>");
    }
    $self->write_log("tags added: $tags_to_add, ids: ".join(", ",@tag_ids));
    $self->redirect_to("/tags/$type");
    # $self->render(template => 'tags/add');
}

####################################################################################

sub add_and_assign {
    my $self = shift;
    my $tags_to_add = $self->param('new_tag');
    my $eid = $self->param('eid');
    my $type = $self->param('type') || 1;
    my $dbh = $self->app->db;

    my @tag_ids = add_tags_from_string($self, $tags_to_add);

    foreach my $tag_id (@tag_ids){
        say "Want to assign tag (type $type) id $tag_id to entry eid $eid";
        my $sth = $dbh->prepare( "INSERT INTO Entry_to_Tag(entry_id, tag_id) VALUES (?,?)");
        $sth->execute($eid, $tag_id) if defined $eid and $eid > 0 and defined $tag_id and $tag_id > 0;
    }

    $self->redirect_to($self->get_referrer);
}

####################################################################################

sub edit {
    my $self = shift;
    my $dbh = $self->app->db;
    my $tagid = $self->param('id');

    my $new_name = $self->param('new_tag') || undef;
    my $new_permalink = $self->param('new_permalink') || undef;
    my $new_type = $self->param('new_type') || undef;
    my $saved = 0;

    # the tag as it is stored in the db

    my $mtag = MTag->static_get($dbh, $tagid);

    

    $mtag->{name} = $new_name if defined $new_name;
    $mtag->{permalink} = $new_permalink if defined $new_permalink;
    $mtag->{type} = $new_type if defined $new_type;
    $saved = $mtag->save($dbh);


    $self->stash(tagobj  => $mtag, saved  => $saved);
    $self->render(template => 'tags/edit');
   
}

####################################################################################
sub get_authors_for_tag_read{
    my $self = shift;
    my $dbh = $self->app->db;
    my $tag_id = $self->param('tid');
    my $team_id = $self->param('team');

    my $team_by_name = MTeam->static_get_by_name($dbh, $team_id);
    my $team_by_id = MTeam->static_get($dbh, $team_id);
    my $team = undef;
    $team = $team_by_name if defined $team_by_name;
    $team = $team_by_id if defined $team_by_id;


    my $tag_by_name = MTag->static_get_by_name($dbh, $tag_id);
    my $tag_by_id = MTag->static_get($dbh, $tag_id);
    my $tag = undef;
    $tag = $tag_by_name if defined $tag_by_name;
    $tag = $tag_by_id if defined $tag_by_id;

    if(!defined $tag){
      $self->render(text => "Tag $tag_id does not exist", status => 404);
      return;
    }
    if(defined $team_id and !defined $team){
      $self->render(text => "Team $team_id does not exist", status => 404);
      return;
    }
     


    my @author_ids = get_author_ids_for_tag_id($self, $tag->{id});
    if(defined $team_id and defined $team){
        @author_ids = get_author_ids_for_tag_id_and_team($self, $tag->{id}, $team->{id});    
    }

    $self->stash(tag => $tag->{name}, tag_id => $tag->{id}, author_ids  => \@author_ids);
    $self->render(template => 'tags/authors_having_tag_read');
}
####################################################################################
sub get_tags_for_author_read{

    my $self = shift;
    my $user = $self->param('aid');
    my $maid = $user;

    my $dbh = $self->app->db;
    $maid = get_master_id_for_master($dbh, $user);
    if($maid == -1){
        #user input is already master id! using the user's input
        $maid = $user;
    }

    my ($tag_ids_arr_ref, $tags_arr_ref) = get_tags_for_author($self, $maid);

    ### here list of objects should be created


    my @TCarr;

    my $i = 0;
    foreach my $tag_id (@$tag_ids_arr_ref){
        my $tag = $$tags_arr_ref[$i];

        my $name = $tag;
        $name =~ s/_/\ /g;

        # my $set = get_set_of_papers_for_author_and_tag($self, $maid, $tag_id); # DEPRECATED!
        my @objs = Fget_publications_main_hashed_args($self, {hidden => 0, author => $maid, tag=>$tag_id});
        my $count =  scalar @objs;
        

        # my $url = "/ly/p?author=".get_master_for_id($self->app->db, $maid)."&tag=".$tag."&title=1&navbar=1";
        my $author_master = get_master_for_id($self->app->db, $maid);
        my $url = $self->url_for('lyp')->query(author=>$author_master, tag=>$tag, title=>'1', navbar=>'1');
        
        my $tc_obj = MTagCloud->new();
        $tc_obj->{tag} = $tag;
        $tc_obj->{url} = $url;
        $tc_obj->{count} = $count;
        $tc_obj->{name} = $name;

        push @TCarr, $tc_obj;
        $i++;
    }

    my @sorted = reverse sort { $a->getCount() <=> $b->getCount()} @TCarr;

    ### old code

    $self->stash(tags => $tags_arr_ref, tag_ids => $tag_ids_arr_ref, author_id  => $maid, tcarr => \@sorted);
    $self->render(template => 'tags/author_tags_read');

}
####################################################################################
sub get_tags_for_team_read{
    my $self = shift;
    my $team = $self->param('tid');
    my $tid = $team;

    my $dbh = $self->app->db;
    $tid = get_team_id($dbh, $team); 
    if($tid == -1){
        #user input is already team id! using the user's input
        $tid = $team;
    }

    my ($tag_ids_arr_ref, $tags_arr_ref) = get_tags_for_team($self, $tid, 1);

    ### here list of objects should be created

    my @TCarr;

    my $i = 0;
    foreach my $tag_id (@$tag_ids_arr_ref){
        my $tag = $$tags_arr_ref[$i];

        my $name = $tag;
        $name =~ s/_/\ /g;

        my $set = get_set_of_papers_for_team_and_tag($self, $tid, $tag_id);
        my $count =  scalar $set->members;

        # my $url = "/ly/p?team=".get_team_for_id($self->app->db, $tid)."&tag=".$tag."&title=1&navbar=1";
        my $team_name = get_team_for_id($self->app->db, $tid);
        my $url = $self->url_for('lyp')->query(team=>$team_name, tag=>$tag, title=>'1', navbar=>'1');

        my $tc_obj = MTagCloud->new();
        $tc_obj->{tag} = $tag;
        $tc_obj->{url} = $url;
        $tc_obj->{count} = $count;
        $tc_obj->{name} = $name;

        push @TCarr, $tc_obj;
        $i++;
    }

    my @sorted = reverse sort { $a->getCount() <=> $b->getCount()} @TCarr;

    ### old code

    $self->stash(tags => $tags_arr_ref, tag_ids => $tag_ids_arr_ref, author_id  => $team, tcarr => \@sorted);
    $self->render(template => 'tags/author_tags_read');

}
####################################################################################
sub get_authors_for_tag{
  my $self = shift;
  my $dbh = $self->app->db;
  my $tag_id = $self->param('tid');

  my $mtag = MTag->static_get($self->app->db, $tag_id);
  if(!defined $mtag){
    $self->render(text => 'Tag does not exist.', status => 404);
  }
  my $tag;

  my @authors = ();
  if(defined $mtag){
    $tag = $mtag->{name};
    @authors = get_author_ids_for_tag_id($self, $tag_id);    
  }
  else{
    $tag_id = 0;
    $tag = 'noname';
  }

  $self->stash(tag => $tag, tag_id => $tag_id, author_ids  => \@authors);
  $self->render(template => 'tags/authors_having_tag');
}
####################################################################################

sub delete {
    my $self = shift;
    my $dbh = $self->app->db;

    my $tag_to_delete = $self->param('id_to_delete');
    my $type = $self->param('type') || 1;

    say $tag_to_delete;

    if(defined $tag_to_delete){

        $self->write_log("Deleting tag id: $tag_to_delete.");

        my $sth = $dbh->prepare( 'DELETE FROM Tag WHERE id=?' );  
        $sth->execute($tag_to_delete); 


        my $sth2 = $dbh->prepare( 'DELETE FROM Entry_to_Tag WHERE tag_id=?' );  
        $sth2->execute($tag_to_delete);
    }

    $self->redirect_to($self->get_referrer);
}


1;