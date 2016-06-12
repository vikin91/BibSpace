package BibSpace::Controller::Helpers;

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
use Set::Scalar;

use BibSpace::Controller::Core;
use BibSpace::Controller::Set;
use BibSpace::Controller::Publications;
use BibSpace::Controller::BackupFunctions;

use BibSpace::Functions::FPublications;

use BibSpace::Functions::TagTypeObj;

use base 'Mojolicious::Plugin';
sub register {

	my ($self, $app) = @_;

    # TODO: Move all implementations to a separate files to avoid code redundancy! Here only function calls should be present, not theirs implementation

    $app->helper(get_rank_of_current_user => sub {
        my $self = shift;
        return 99 if $self->app->is_demo();

        my $uname = shift || $app->session('user');
        my $user_dbh = $app->db;

        my $sth = $user_dbh->prepare("SELECT rank FROM Login WHERE login=?");
        $sth->execute($uname);
        my $row = $sth->fetchrow_hashref();
        my $rank = $row->{rank};

        $rank = 0 unless defined $rank;

        return $rank;
    });

	$app->helper(current_year => sub {
        my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        return 1900 + $year;
    });

	$app->helper(get_year_of_oldest_entry => sub {
        my $self = shift;
        my $sth = $self->app->db->prepare( "SELECT MIN(year) as min FROM Entry" ) or die $self->app->db->errstr;  
        $sth->execute(); 
        my $row = $sth->fetchrow_hashref();
        my $min = $row->{min};
        return $min; 
        
    });
    

	$app->helper(current_month => sub {
        my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        return $mon + 1;
    });



    $app->helper(can_delete_backup => sub {
        my $self = shift;
        my $bid = shift;
        my $backup_dbh = $self->app->db;

        my $backup_dir_absolute = $self->config->{backups_dir};
        $backup_dir_absolute =~ s!/*$!/!;

        my $b_fname = get_backup_filename($self, $bid);
        my $file_path = $backup_dir_absolute.$b_fname;

        my $file_exists = 0;
        $file_exists = 1 if -e $file_path;
        my $b_age = get_backup_age_in_days($self, $bid);

        my $age_limit = $self->config->{allow_delete_backups_older_than};

        # say "helper(can_delete_backup: age limit is $age_limit, backup age: $b_age file_exists $file_exists file_path $file_path ";

        return 1 if $file_exists == 1 and $b_age >= $age_limit;
        return 1 if $file_exists == 0;
        return 0;
    });


    $app->helper(num_pubs => sub {
        my $self = shift;
        
        my @objs = Fget_publications_main_hashed_args_only($self, {hidden => undef});
        my $count =  scalar @objs;
        return $count; 
      });

    $app->helper(get_all_tag_types => sub {
        my $self = shift;
        my $dbh = $self->app->db;
        my @ttobjarr = BibSpace::Functions::TagTypeObj->getAll($dbh);
        return @ttobjarr;
        
        
      });

    $app->helper(get_tag_type_obj => sub {
        my $self = shift;
        my $type = shift || 1;
        my $ttobj = BibSpace::Functions::TagTypeObj->getById($self->app->db, $type);
        return $ttobj;

        # return $ttobj->{name};
    });

    $app->helper(get_tags_of_type_for_paper => sub {
        my $self = shift;
        my $eid = shift;
        my $type = shift || 1;

        return  MTag->static_get_all_of_type_for_paper($self->app->db, $eid, $type);
    });

    $app->helper(get_unassigned_tags_of_type_for_paper => sub {
        my $self = shift;
        my $eid = shift;
        my $type = shift || 1;

        return  MTag->static_get_unassigned_of_type_for_paper($self->app->db, $eid, $type);
    });

    

    

    $app->helper(num_authors => sub {
        my $self = shift;

        my $sth = $self->app->db->prepare( "SELECT COUNT(DISTINCT(master_id)) as num FROM Author " );  
        $sth->execute(); 
        my $row = $sth->fetchrow_hashref();
        my $num = $row->{num};
        return $num; 
      });

    $app->helper(num_visible_authors => sub {
        my $self = shift;

        my $sth = $self->app->db->prepare( "SELECT COUNT(DISTINCT(master_id)) as num FROM Author WHERE display=1" );  
        $sth->execute(); 
        my $row = $sth->fetchrow_hashref();
        my $num = $row->{num};
        return $num; 
      });

    $app->helper(get_num_members_for_team => sub {
        my $self = shift;
        my $id = shift;

        my ($author_ids_ref, $start_arr_ref, $stop_arr_ref) = get_team_members($self, $id);
        my $num_authors = scalar @$author_ids_ref;
        return $num_authors;
    });

    $app->helper(team_can_be_deleted => sub {
        my $self = shift;
        my $id = shift;

        my ($author_ids_ref, $start_arr_ref, $stop_arr_ref) = get_team_members($self, $id);
        my $num_authors = scalar @$author_ids_ref;
        return 0 if $num_authors > 0;

        return 1;
    });

    $app->helper(get_num_teams => sub {
        my $self = shift;
        my ($teams_arr_ref, $team_ids_arr_ref) = get_all_teams($self->app->db);
        return scalar @$team_ids_arr_ref;
    });

    $app->helper(get_teams_id_arr => sub {
        my $self = shift;
        my ($teams_arr_ref, $team_ids_arr_ref) = get_all_teams($self->app->db);
        return @$team_ids_arr_ref;
    });

    $app->helper(get_team_name => sub {
        my $self = shift;
        my $id = shift;
        return get_team_for_id($self->app->db, $id);
    });

    $app->helper(get_tag_name => sub {
        my $self = shift;
        my $id = shift;
        my $mtag = MTag->static_get($self->app->db, $id);
        return $mtag->{name};
    });

    $app->helper(author_is_visible => sub {
        my $self = shift;
        my $id = shift;

        return get_author_visibility_for_id($self, $id);
      });


    $app->helper(author_can_be_deleted => sub {
        my $self = shift;
        my $id = shift;

        my $visibility = get_author_visibility_for_id($self, $id);
        return 0 if $visibility == 1;

        my ($teams_arr, $start_arr, $stop_arr, $team_id_arr) = get_teams_of_author($self, $id);
        my $num_teams = scalar @$teams_arr;


        return 1 if $num_teams == 0 and $visibility == 0;
        return 0;
      });

    $app->helper(num_tags => sub {
        my $self = shift;
        my $type = shift || 1;

        my $sth = $self->app->db->prepare( "SELECT COUNT(id) as num FROM Tag WHERE type=?" );  
        $sth->execute($type); 
        my $row = $sth->fetchrow_hashref();
        my $num = $row->{num};
        return $num; 
      });

    $app->helper(num_pubs_for_year => sub {
        my $self = shift;
        my $year = shift;

        my @objs = Fget_publications_main_hashed_args_only($self, {hidden => 0, year => $year});
        my $count =  scalar @objs;
        return $count;
      });

    $app->helper(get_bibtex_types_aggregated_for_type => sub {
        my $self = shift;
        my $type = shift;
        
        return get_bibtex_types_for_our_type($self->app->db, $type);
    });

    $app->helper(helper_get_description_for_our_type => sub {
        my $self = shift;
        my $type = shift;
        return get_description_for_our_type($self->app->db, $type);
    });

    $app->helper(helper_get_landing_for_our_type => sub {
        my $self = shift;
        my $type = shift;
        return get_landing_for_our_type($self->app->db, $type);
    });

    
    $app->helper(helper_get_entry_title => sub {
      my $self = shift;
      my $id = shift;
      my $dbh = $self->app->db;

      my $mentry = MEntry->static_get($dbh, $id);
      if(!defined $mentry){
        return "";
      }
      return $mentry->{title};
    });

    

    $app->helper(num_bibtex_types_aggregated_for_type => sub {
        my $self = shift;
        my $type = shift;
        return scalar $self->get_bibtex_types_aggregated_for_type($type);
      });

    $app->helper(num_pubs_for_author_and_tag => sub {
        my $self = shift;
        my $mid = shift;
        my $tag_id = shift;

        my @objs = Fget_publications_main_hashed_args_only($self, {hidden => 0, author => $mid, tag=>$tag_id});
        my $count =  scalar @objs;
        return $count;

        # my $set = get_set_of_papers_for_author_and_tag($self, $mid, $tag_id);
      });

    $app->helper(num_pubs_for_author_and_team => sub {
        my $self = shift;
        my $mid = shift;
        my $team_id = shift;

        say "call HELPER num_pubs_for_author_and_team";

        my @objs = Fget_publications_main_hashed_args_only($self, {hidden => 0, author => $mid, team=>$team_id});
        my $count =  scalar @objs;

        return $count;

        # my $set = get_set_of_papers_for_author_and_team($self, $mid, $team_id);
      });

    $app->helper(get_years_arr => sub {
        my $self = shift;

        return MEntry->static_get_unique_years_array($self->app->db);
      });

    $app->helper(num_pubs_for_author => sub {
        my $self = shift;
        my $mid = shift;

        my @objs = Fget_publications_main_hashed_args_only($self, {hidden => 0, author => $mid});
        my $count =  scalar @objs;
        return $count;
      });

    $app->helper(get_authors_of_entry => sub {
        my $self = shift;
        my $eid = shift;

        my $sth = $self->app->db->prepare( "SELECT author_id FROM Entry_to_Author WHERE entry_id=?" );  
        $sth->execute($eid); 

        my @authors;
        while(my $row = $sth->fetchrow_hashref()){
            my $author_id = $row->{author_id};    
            push @authors, $author_id;
        }
        
        return @authors; 
      });

    $app->helper(num_unhidden_pubs_for_tag => sub {
        my $self = shift;
        my $tid = shift;

        my @objs = Fget_publications_main_hashed_args_only($self, {hidden => 0, tag => $tid});
        my $count =  scalar @objs;
        return $count;
      });


    $app->helper(num_pubs_for_tag => sub {
        my $self = shift;
        my $tid = shift;

        my @objs = Fget_publications_main_hashed_args_only($self, {hidden => undef, tag => $tid});
        my $count =  scalar @objs;
        return $count;
      });

    $app->helper(get_author_mids_arr => sub {
        my $self = shift;

        my $sth = $self->app->db->prepare( "SELECT DISTINCT master_id, master FROM Author WHERE display = 1 ORDER BY master ASC" );  
        $sth->execute(); 
        my @arr;
        while(my $row = $sth->fetchrow_hashref()) {
            my $mid = $row->{master_id};
            push @arr, $mid;
        }        
        return @arr; 
      });

    $app->helper(get_master_for_id => sub {
        my $self = shift;
        my $id = shift;
        # navi uses it

        return get_master_for_id($self->app->db, $id);
      });

    $app->helper(get_first_letters => sub {
           my $self = shift;
           my $dbh = $self->app->db;

           my $sth = $dbh->prepare( "SELECT DISTINCT substr(master, 0, 2) as let FROM Author
                 WHERE display=1
                 ORDER BY let ASC" ); 
           $sth->execute(); 
           my @letters;
           while(my $row = $sth->fetchrow_hashref()) {
              my $letter = $row->{let} || "*";
              push @letters, uc($letter);
           }
           # @letters = uniq(@letters);
           my @sorted_letters = sort(@letters);
           return @sorted_letters;
    });
}


1;
