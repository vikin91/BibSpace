package Menry::Functions::AuthorsFunctions;

# use Menry::Controller::Core;
use Menry::Functions::PublicationsFunctions;

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
    );


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