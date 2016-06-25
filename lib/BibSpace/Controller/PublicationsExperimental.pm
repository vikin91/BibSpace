package BibSpace::Controller::Publicationsexperimental;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use File::Slurp;     # should be replaced in the future
use Path::Tiny;      # for creating directories
use Try::Tiny;
use Time::Piece;
use 5.010;           #because of ~~
use strict;
use warnings;
use DBI;

use TeX::Encode;
use Encode;


use BibSpace::Controller::Core;
use BibSpace::Functions::FPublications;
use BibSpace::Model::MEntry;

use BibSpace::Controller::Set; # deprecated but needed so far. TODO: refactor this

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::UserAgent;
use Mojo::Log;

our %mons = (
    1  => 'January',
    2  => 'February',
    3  => 'March',
    4  => 'April',
    5  => 'May',
    6  => 'June',
    7  => 'July',
    8  => 'August',
    9  => 'September',
    10 => 'October',
    11 => 'November',
    12 => 'December'
);
####################################################################################
## ADD form
sub publications_add_many_get {
    say "CALL: publications_add_many_get";
    my $self = shift;
    my $dbh  = $self->app->db;

    my $bib1
        = '@article{key-'
        . random_string(8) . '-'
        . get_current_year() . ',
      author = {Johny Example},
      title = {{Selected aspects of some methods ' . random_string(8) . '}},
      year = {' . get_current_year() . '},
      month = {' . $mons{ get_current_month() } . '},
      day = {1--31},
  }';

    my $bib2
        = '@article{key-'
        . random_string(8) . '-'
        . get_current_year() . ',
      author = {Johny Example},
      title = {{Selected aspects of some methods ' . random_string(8) . '}},
      year = {' . get_current_year() . '},
      month = {' . $mons{ get_current_month() } . '},
      day = {1--31},
  }';

    my $bib = $bib1 . "\n\n" . $bib2;

    my $msg
        = "Adding multiple publications at once is <strong>experimental!</strong> <br/> <strong>Adding mode</strong> You operate on an unsaved entry!";

    $self->stash(
        bib         => $bib,
        key         => '',
        existing_id => '',
        exit_code   => '',
        msg         => $msg,
        preview     => ''
    );
    $self->render( template => 'publications/add_multiple_entries' );
}
############################################################################################################

## Called after every preview or store command issued by ADD_MULTIPLE form

## THIS DOES NOT WORK ! finish this function using the new way of adding editing
sub publications_add_many_post {
    say "CALL: publications_add_many_post ";
    my $self          = shift;
    my $id            = $self->param('id') || undef;
    my $new_bib       = $self->param('new_bib');
    my $preview_param = $self->param('preview') || undef;

    # my $check_key =  || undef;
    my $preview = 0;
    my $msg = "<strong>Adding mode</strong> You operate on an unsaved entry!";

    $self->write_log("post_add_many_store add publication with bib $new_bib");

    my $debug_str = "";

    my $dbh          = $self->app->db;
    my $html_preview = "";
    my $code         = -2;

    my @bibtex_codes = split_bibtex_entries($new_bib);
    my @key_arr      = ();

    for my $bibtex_code (@bibtex_codes) {

        # $debug_str.="<br>Found code!";

        my $bibtex_key = get_key_from_bibtex_code($bibtex_code);
        $debug_str .= "<br>Found key: $bibtex_key";

        push @key_arr, $bibtex_key;
    }

    my @mentries = ();

    # status_code_strings
    # -2 => PREVIEW
    # -1 => ERR_BIBTEX
    # 0 => ADD_OK
    # 1 => EDIT_OK
    # 2 => KEY_OK
    # 3 => KEY_TAKEN
    my $num_errors = 0;
    for my $bibtex_code (@bibtex_codes) {
        my ( $mentry, $status_code_str, $existing_id, $added_under_id )
            = Fhandle_add_edit_publication( $dbh, $bibtex_code, -1,
            'preview' );

        if ( $status_code_str eq 'ERR_BIBTEX' ) {
            $debug_str
                .= "<br>BIBTEX error in <br/><pre> $bibtex_code </pre><br/>";
            $num_errors = $num_errors + 1;
        }
        elsif ( $status_code_str eq 'KEY_TAKEN' ) {    # => bibtex OK, key OK
            $debug_str
                .= "<br>KEY_TAKEN error in <br/><pre> $bibtex_code </pre><br/>";
            $num_errors = $num_errors + 1;
        }
    }

    if ( $num_errors > 0 ) {
        $msg = $debug_str
            . "Please correct entries before continuing. No changes were written to database.";
        $self->stash(
            bib         => $new_bib,
            existing_id => 0,
            key         => '',
            msg         => $msg,
            exit_code   => $code,
            preview     => $html_preview
        );
        $self->render( template => 'publications/add_multiple_entries' );
        return;
    }

    # here all Bibtex entries are OK

    my %seen;
    my $are_unique = 0;

    # if size of arr is equal to size of uniq arr
    $are_unique = 1 if uniq(@key_arr) == @key_arr;

    # count how many times a given key appears
    foreach my $value (@key_arr) {
        $seen{$value}++;
    }

    $debug_str .= "<br>Checking if input keys are unique: ";
    $debug_str .= "Yes!" if $are_unique;
    $debug_str .= "No! " unless $are_unique;

    if ( $are_unique == 0 ) {    # if the array is not empty
        $debug_str .= "<br/>"
            . "Some bibtex keys in the input are not unique. Please correct the input.";
        foreach my $key ( keys %seen ) {
            $debug_str
                .= "<br/>"
                . "Bibtex key: $key exists "
                . $seen{$key}
                . " times!"
                if $seen{$key} > 1;
        }
        $msg = $debug_str
            . "Please correct entries before continuing. No changes were written to database.";
        $self->stash(
            bib         => $new_bib,
            existing_id => 0,
            key         => '',
            msg         => $msg,
            exit_code   => $code,
            preview     => $html_preview
        );
        $self->render( template => 'publications/add_multiple_entries' );
        return;
    }

    $debug_str .= "<br>Entries ready to add! Starting.";

    for my $bibtex_code (@bibtex_codes) {
        my ( $mentry, $status_code_str, $existing_id, $added_under_id )
            = Fhandle_add_edit_publication( $dbh, $bibtex_code, -1, 'save', $self->app->bst );

        if ( $status_code_str eq 'ADD_OK' ) {
            $debug_str .= "<br>"
                . "Added key entry as id $added_under_id successfully!";
        }
        else {    # => bibtex OK, key OK
            $debug_str .= "<br>"
                . "Something went wrong. Status: $status_code_str<br/>";
        }
    }
    say "after bibtex codes loop";

    $self->stash(
        bib         => $new_bib,
        existing_id => 0,
        key         => '',
        msg         => $msg . $debug_str,
        exit_code   => $code,
        preview     => $html_preview
    );
    $self->render( template => 'publications/add_multiple_entries' );
}
####################################################################################
sub split_bibtex_entries {
    say "CALL: split_bibtex_entries";
    my $input = shift;

    my @bibtex_codes = ();
    $input =~ s/^\s+|\s+$//g;
    $input =~ s/^\t//g;

    for my $b_code ( split /@/, $input ) {
        next unless length($b_code) > 10;
        my $entry_code = "@" . $b_code;

        my $entry = new Text::BibTeX::Entry;
        $entry->parse_s($entry_code);
        if ( $entry->parse_ok ) {
            push @bibtex_codes, $entry_code;
        }
    }

    return @bibtex_codes;
}
####################################################################################

### THIS IS ONLY Exemplary FUNCTION TO play with functionalities provided by sets
sub all_defined_by_set {
    say "CALL: all_defined_by_set ";
    my $self = shift;

    my $end_set = get_set_of_papers_for_all_authors_of_team_id( $self, 1 );
    $end_set = $end_set - get_set_of_papers_for_team( $self, 1 );

    #test
    my $all_papers          = get_set_of_all_paper_ids( $self->app->db );
    my $not_relevant_papers = $all_papers
        - get_set_of_papers_for_all_authors_of_team_id( $self, 1 );

    $end_set = $not_relevant_papers;

    ### TODO!!!
    # not_relev = not_relev - tagged
    # not_relev = not_relev - exceptions

    my @objs = Fget_publications_core_from_set( $self, $end_set );
    $self->stash( entries => \@objs );
    $self->render( template => 'publications/all' );
}
####################################################################################
sub all_with_pdf_on_sdq {
    say "CALL: all_with_pdf_on_sdq ";
    my $self = shift;
    my $num  = $self->param('num') || 10;
    my $dbh  = $self->app->db;

    $self->write_log("Displaying papers with pdfs on sdq server");

    my $qry = "SELECT id from Entry WHERE html_bib LIKE ?";

    my $sth = $dbh->prepare($qry);
    $sth->execute("%sdqweb%");

    my @array;
    while ( my $row = $sth->fetchrow_hashref() ) {
        my $eid = $row->{id};
        push @array, $eid;
    }

    my $msg
        = "This list contains papers that have pdfs on the sdqweb server. Please use this list to move pdfs to our server - this improves the performance.";

    my @objs = Fget_publications_core_from_array_ref( $self, \@array );
    $self->stash( msg     => $msg );
    $self->stash( entries => \@objs );
    $self->render( template => 'publications/all' );
}
####################################################################################

1;
