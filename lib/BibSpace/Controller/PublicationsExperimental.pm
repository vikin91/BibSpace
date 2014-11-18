package BibSpace::Controller::PublicationsExperimental;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use Try::Tiny;

use v5.16;           #because of ~~
use strict;
use warnings;

use List::MoreUtils qw(any uniq);

use TeX::Encode;
use Encode;

use BibSpace::Functions::Core;
use BibSpace::Functions::FPublications;

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

## ADD form
sub publications_add_many_get {
  my $self = shift;

  my $bib1 = '@article{key-ENTRY1-' . get_current_year() . ',
      author = {Johny Example},
      title = {{Selected aspects of some methods ' . random_string(8) . '}},
      journal = {Journal of this and that},
      publisher = {Printer-at-home publishing},
      year = {' . get_current_year() . '},
      month = {' . $mons{12} . '},
      day = {1--31},
  }';

  my $bib2 = '@article{key-ENTRY2-' . get_current_year() . ',
      author = {Johny Example},
      title = {{Selected aspects of some methods ' . random_string(8) . '}},
      journal = {Journal of other things},
      publisher = {Copy-machine publishing house},
      year = {' . get_current_year() . '},
      month = {' . $mons{12} . '},
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
    preview     => ''
  );
  $self->stash(msg_type => 'warning', msg => $msg);
  $self->render(template => 'publications/add_multiple_entries');
}

## Called after every preview or store command issued by ADD_MULTIPLE form
##  finish this function using the new way of adding editing

sub publications_add_many_post {

  my $self          = shift;
  my $id            = $self->param('id') // undef;
  my $new_bib       = $self->param('new_bib');
  my $preview_param = $self->param('preview') // undef;
  my $save_param    = $self->param('save') // undef;

  # my $check_key =  || undef;
  my $preview = 0;
  my $msg = "<strong>Adding mode</strong> You operate on an unsaved entry!<br>";

  $self->app->logger->info("Adding multiple publications");

  $self->app->logger->debug("Adding multiple publications with bib $new_bib");

  my $debug_str = "";

  my $html_preview = "";
  my $code         = -2;

  my @bibtex_codes = split_bibtex_entries($new_bib);

  # status_code_strings
  # -2 => PREVIEW
  # -1 => ERR_BIBTEX
  # 0 => ADD_OK
  # 1 => EDIT_OK
  # 2 => KEY_OK
  # 3 => KEY_TAKEN
  my $num_errors = 0;
  for my $bibtex_code (@bibtex_codes) {

    my ($mentry, $status_code_str, $existing_id, $added_under_id)
      = Fhandle_add_edit_publication($self->app, $bibtex_code, -1, 'preview');

    if ($status_code_str eq 'ERR_BIBTEX') {
      $debug_str .= "BIBTEX error in <br/><pre> $bibtex_code </pre>";
      $num_errors++;
    }
    elsif ($status_code_str eq 'KEY_TAKEN') {    # => bibtex OK, key OK
      $debug_str .= "KEY_TAKEN error in <br/><pre> $bibtex_code </pre>";
      $num_errors++;
    }
    else {
      $debug_str .= "$status_code_str for <br/><pre> $bibtex_code </pre>";
    }
  }

  if ($num_errors > 0) {
    $msg
      = "$num_errors have errors. Please correct entries before continuing. No changes were written to database. <br> $debug_str";
    $self->stash(
      bib         => $new_bib,
      existing_id => 0,
      key         => '',
      msg_type    => 'danger',
      msg         => $msg,
      exit_code   => $code,
      preview     => $html_preview
    );
    $self->render(template => 'publications/add_multiple_entries');
    return;
  }
  if (defined $preview_param) {
    $msg = "Check ready.<br>" . $debug_str;
    $self->stash(
      bib         => $new_bib,
      existing_id => 0,
      key         => '',
      msg_type    => 'info',
      msg         => $msg,
      exit_code   => $code,
      preview     => $html_preview
    );
    $self->render(template => 'publications/add_multiple_entries');
    return;
  }

  # here all Bibtex entries are OK

  my @key_arr = ();

  for my $bibtex_code (@bibtex_codes) {

    # $debug_str.="<br>Found code!";
    my $entry = $self->app->entityFactory->new_Entry(bib => $bibtex_code);
    $entry->populate_from_bib;
    $debug_str .= "<br>Found key: " . $entry->{bibtex_key};

    push @key_arr, $entry->{bibtex_key};
  }

  my @mentries = ();

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

  if ($are_unique == 0) {    # if the array is not empty
    $debug_str .= "<br/>"
      . "Some bibtex keys in the input are not unique. Please correct the input.";
    foreach my $key (keys %seen) {
      $debug_str
        .= "<br/>" . "Bibtex key: $key exists " . $seen{$key} . " times!"
        if $seen{$key} > 1;
    }
    $msg = $debug_str
      . "Please correct entries before continuing. No changes were written to database.";
    $self->stash(
      bib         => $new_bib,
      existing_id => 0,
      key         => '',
      msg_type    => 'danger',
      msg         => $msg,
      exit_code   => $code,
      preview     => $html_preview
    );
    $self->render(template => 'publications/add_multiple_entries');
    return;
  }

  my $msg_type = 'warning';

  if (defined $save_param) {
    $debug_str .= "<br>Entries ready to add! Starting.";

    $msg_type = 'success';

    for my $bibtex_code (@bibtex_codes) {
      my ($mentry, $status_code_str, $existing_id, $added_under_id)
        = Fhandle_add_edit_publication($self->app, $bibtex_code, -1, 'save',
        $self->app->bst);

      if ($status_code_str eq 'ADD_OK') {
        $debug_str
          .= "<br>" . "Added key entry as id $added_under_id successfully!";
      }
      else {    # => bibtex OK, key OK
        $debug_str
          .= "<br>" . "Something went wrong. Status: $status_code_str<br/>";
        $msg_type = 'danger';
      }
    }
  }

  $self->stash(
    bib         => $new_bib,
    existing_id => 0,
    msg_type    => $msg_type,
    key         => '',
    msg         => $msg . $debug_str,
    exit_code   => $code,
    preview     => $html_preview
  );
  $self->render(template => 'publications/add_multiple_entries');
}

1;
