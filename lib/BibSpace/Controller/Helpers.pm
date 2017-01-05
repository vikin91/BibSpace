package BibSpace::Controller::Helpers;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010;           #because of ~~
use strict;
use warnings;
use DBI;
use Set::Scalar;

use Mojo::Redis2;

use BibSpace::Controller::Core;
use BibSpace::Controller::Publications;
use BibSpace::Controller::BackupFunctions;

use BibSpace::Functions::FPublications;

use BibSpace::Model::MTagType;

use base 'Mojolicious::Plugin';

sub register {

    my ( $self, $app ) = @_;


    $app->helper(
        get_dbh => sub {
            my $self = shift;
            return $self->app->db;
        }
    );
    $app->helper( 
        bst => sub {
            my $self = shift;

            my $bst_candidate_file = $self->app->home . '/lib/descartes2.bst';

            if( defined $self->app->config->{bst_file} ){
                $bst_candidate_file = $self->app->config->{bst_file};
                say "BST candidate 1: $bst_candidate_file";
                return File::Spec->rel2abs( $bst_candidate_file )
                    if File::Spec->file_name_is_absolute( $bst_candidate_file )
                    and -e File::Spec->rel2abs( $bst_candidate_file );

                $bst_candidate_file = $self->app->home . $self->app->config->{bst_file};
                say "BST candidate 2: $bst_candidate_file";

                return File::Spec->rel2abs( $bst_candidate_file )
                    if File::Spec->file_name_is_absolute( $bst_candidate_file )
                    and -e File::Spec->rel2abs( $bst_candidate_file );     
            }
            
            $bst_candidate_file = $self->app->home . '/lib/descartes2.bst';
            say "BST candidate 3: $bst_candidate_file";

            return File::Spec->rel2abs( $bst_candidate_file )
                if -e File::Spec->rel2abs( $bst_candidate_file );

            say "All BST candidates failed";
            return './bst-not-found.bst';
        }
    );



# TODO: Move all implementations to a separate files to avoid code redundancy! Here only function calls should be present, not theirs implementation

    $app->helper(
        get_rank_of_current_user => sub {
            my $self = shift;
            return 99 if $self->app->is_demo();

            my $uname = shift || $app->session('user');
            my $user_dbh = $app->db;

            my $sth
                = $user_dbh->prepare("SELECT rank FROM Login WHERE login=?");
            $sth->execute($uname);
            my $row  = $sth->fetchrow_hashref();
            my $rank = $row->{rank};

            $rank = 0 unless defined $rank;

            return $rank;
        }
    );

    $app->helper(
        current_year => sub {
            my ($sec,  $min,  $hour, $mday, $mon,
                $year, $wday, $yday, $isdst
            ) = localtime(time);
            return 1900 + $year;
        }
    );

    $app->helper(
        get_year_of_oldest_entry => sub {
            my $self = shift;
            my $sth
                = $self->app->db->prepare(
                "SELECT MIN(year) as min FROM Entry")
                or die $self->app->db->errstr;
            $sth->execute();
            my $row = $sth->fetchrow_hashref();
            my $min = $row->{min};
            return $min;

        }
    );

    $app->helper(
        current_month => sub {
            my ($sec,  $min,  $hour, $mday, $mon,
                $year, $wday, $yday, $isdst
            ) = localtime(time);
            return $mon + 1;
        }
    );

    $app->helper(
        can_delete_backup_helper => sub {
            my $self       = shift;
            my $bid        = shift;

            return can_delete_backup($self->app->db, $bid, $self->app->config);
        }
    );

    $app->helper(
        num_pubs => sub {
            my $self = shift;

            my @objs = Fget_publications_main_hashed_args_only( $self,
                { hidden => undef } );
            my $count = scalar @objs;
            return $count;
        }
    );

    $app->helper(
        get_all_tag_types => sub {
            my $self     = shift;
            return MTagType->static_all($self->app->db);
        }
    );

    $app->helper(
        get_tag_type_obj => sub {
            my $self = shift;
            my $type = shift || 1;

            return MTagType->static_get($self->app->db, $type);
        }
    );

    $app->helper(
        get_tags_of_type_for_paper => sub {
            my $self = shift;
            my $eid  = shift;
            my $type = shift || 1;

            return MTag->static_get_all_of_type_for_paper( $self->app->db,
                $eid, $type );
        }
    );

    $app->helper(
        get_unassigned_tags_of_type_for_paper => sub {
            my $self = shift;
            my $eid  = shift;
            my $type = shift || 1;

            return MTag->static_get_unassigned_of_type_for_paper(
                $self->app->db, $eid, $type );
        }
    );

    $app->helper(
        num_authors => sub {
            my $self = shift;
            return scalar MAuthor->static_all_masters($self->app->db);
        }
    );

    $app->helper(
        num_visible_authors => sub {
            my $self = shift;
            return scalar grep {$_->{display} == 1} MAuthor->static_all_masters($self->app->db);
        }
    );

    $app->helper(
        get_num_members_for_team => sub {
            my $self = shift;
            my $id   = shift;

            my $author = MAuthor->static_get( $self->app->db, $id );
            return scalar $author->teams($self->app->db);
        }
    );

    $app->helper(
        team_can_be_deleted => sub {
            my $self = shift;
            my $id   = shift;

            my $team = MTeam->static_get( $self->app->db, $id );
            return 0 if !defined $team or scalar $team->members($self->app->db) > 0;
            return 1;
        }
    );

    $app->helper(
        get_num_teams => sub {
            my $self = shift;
            return scalar MTeam->static_all( $self->app->db );
        }
    );



    $app->helper(
        num_tags => sub {
            my $self = shift;
            my $type = shift || 1;

            return scalar MTag->static_all_type($self->app->db, $type);
        }
    );

    $app->helper(
        num_pubs_for_year => sub {
            my $self = shift;
            my $year = shift;

            my @objs = Fget_publications_main_hashed_args_only( $self,
                { hidden => 0, year => $year } );
            my $count = scalar @objs;
            return $count;
        }
    );

    $app->helper(
        get_bibtex_types_aggregated_for_type => sub {
            my $self = shift;
            my $type = shift;

            return get_bibtex_types_for_our_type( $self->app->db, $type );
        }
    );

    $app->helper(
        helper_get_description_for_our_type => sub {
            my $self = shift;
            my $type = shift;
            return get_description_for_our_type( $self->app->db, $type );
        }
    );

    $app->helper(
        helper_get_landing_for_our_type => sub {
            my $self = shift;
            my $type = shift;
            return get_landing_for_our_type( $self->app->db, $type );
        }
    );

    $app->helper(
        helper_get_entry_title => sub {
            my $self = shift;
            my $id   = shift;
            my $dbh  = $self->app->db;

            my $mentry = MEntry->static_get( $dbh, $id );
            if ( !defined $mentry ) {
                return "";
            }
            return $mentry->{title};
        }
    );

    $app->helper(
        num_bibtex_types_aggregated_for_type => sub {
            my $self = shift;
            my $type = shift;
            return scalar $self->get_bibtex_types_aggregated_for_type($type);
        }
    );

    $app->helper(
        num_pubs_for_author_and_tag => sub {
            my $self      = shift;
            my $master_id = shift;
            my $tag_id    = shift;


            my @objs = Fget_publications_main_hashed_args_only( $self,
                { hidden => 0, author => $master_id, tag => $tag_id } );

            my $count = scalar @objs;
            return $count;
        }
    );

    $app->helper(
        num_pubs_for_author_and_team => sub {
            my $self      = shift;
            my $master_id = shift;
            my $team_id   = shift;

            

            my @objs = Fget_publications_main_hashed_args_only( $self,
                { hidden => 0, author => $master_id, team => $team_id } );
            my $count = scalar @objs;

            return $count;

     # my $set = get_set_of_papers_for_author_and_team($self, $mid, $team_id);
        }
    );

    $app->helper(
        get_recent_years_arr => sub {
            my $self = shift;

            my @arr = MEntry->static_get_unique_years_array( $self->app->db );
            my $max = scalar @arr;
            $max = 10 if $max > 10;
            return @arr[0 .. $max];
        }
    );

    $app->helper(
        num_entries_for_author => sub {
            my $self = shift;
            my $mid  = shift;

            my @objs = Fget_publications_main_hashed_args_only( $self,
                { hidden => 0, author => $mid } );
            my $count = scalar @objs;
            return $count;
        }
    );

    $app->helper(
        num_talks_for_author => sub {
            my $self = shift;
            my $mid  = shift;

            my @objs = Fget_publications_main_hashed_args_only( $self,
                { hidden => 0, author => $mid, entry_type => 'talk' } );
            my $count = scalar @objs;
            return $count;
        }
    );

    $app->helper(
        num_papers_for_author => sub {
            my $self = shift;
            my $mid  = shift;

            my @objs = Fget_publications_main_hashed_args_only( $self,
                { hidden => 0, author => $mid, entry_type => 'paper' } );
            my $count = scalar @objs;
            return $count;
        }
    );


    $app->helper(
        num_pubs_for_tag => sub {
            my $self = shift;
            my $tid  = shift;

            my @objs = Fget_publications_main_hashed_args_only( $self,
                { hidden => undef, tag => $tid } );
            my $count = scalar @objs;
            return $count;
        }
    );

}

1;
