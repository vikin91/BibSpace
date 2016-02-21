package Hex64Publications::Functions::AuthorsFunctions;

# use Hex64Publications::Controller::Core;
use Hex64Publications::Functions::PublicationsFunctions;

use Data::Dumper;
use utf8;
use Text::BibTeX; # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010; #because of ~~
use strict;
use warnings;

use Exporter;
our @ISA= qw( Exporter );
our @EXPORT = qw( 
    postprocess_all_entries_after_author_uids_change_w_creating_authors
    postprocess_all_entries_after_author_uids_change
    add_team_for_author
    );


################################################################################
sub add_team_for_author {
   my $self = shift;
   my $master_id = shift;
   my $team_id = shift;

   my $dbh = $self->app->db;

   $dbh->resultset('AuthorToTeam')->find_or_create({
            team_id => $team_id, 
            author_id => $master_id
            });

   $self->write_log("Author with master id $master_id becomes a member of team with id $team_id.");
}
##################################################################
sub postprocess_all_entries_after_author_uids_change_w_creating_authors{  # assigns papers to their authors ONLY. No tags, no regeneration. Not existing authors will be created
    my $self = shift;

    $self->write_log("reassigning papers to authors (with authors creation) started");

    # my $qry = "SELECT DISTINCT bibtex_key, id, bib FROM Entry";
    my $rs = $self->app->db->resultset('Entry')->search(
    {},
    { 
        columns => [{ 'bibtex_key' => { distinct => 'me.bibtex_key' } }, 'id', 'bib'],
    })->get_column('bib');

    my @bibs = $rs->all;
    

    foreach my $entry_str(@bibs){
        my $entry_obj = new Text::BibTeX::Entry();
        $entry_obj->parse_s($entry_str);
    
        after_edit_process_authors($self->app->db, $entry_obj);
        assign_entry_to_existing_authors_no_add($self->app->db, $entry_obj);
    }

    $self->write_log("reassigning papers to authors (with authors creation) finished");
};
##################################################################
sub postprocess_all_entries_after_author_uids_change{  # assigns papers to their authors ONLY. No tags, no regeneration.
    my $self = shift;

    $self->write_log("reassing papers to authors started");

    my $rs = $self->app->db->resultset('Entry')->search(
    {},
    { 
        columns => [{ 'bibtex_key' => { distinct => 'me.bibtex_key' } }, 'id', 'bib'],
    })->get_column('bib');

    my @bibs = $rs->all;

    foreach my $entry_str(@bibs){
        my $entry_obj = new Text::BibTeX::Entry();
        $entry_obj->parse_s($entry_str);
    
        assign_entry_to_existing_authors_no_add($self->app->db, $entry_obj);
    }

    $self->write_log("reassing papers to authors finished");
};

1;