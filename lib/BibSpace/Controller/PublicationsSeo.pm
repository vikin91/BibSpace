package BibSpace::Controller::PublicationsSeo;

use strict;
use warnings;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use v5.16;           #because of ~~

use TeX::Encode;
use Encode;

use BibSpace::Functions::Core;
use BibSpace::Functions::FPublications;
use BibSpace::Controller::Publications;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::UserAgent;
use Mojo::Log;

sub metalist {
  my $self = shift;

  my @pubs = Fget_publications_main_hashed_args($self,
    {entry_type => 'paper', hidden => 0});

  $self->stash(entries => \@pubs);
  $self->render(template => 'publicationsSEO/metalist');
}

sub meta {
  my $self = shift;
  my $id   = $self->param('id');

  my $mentry = $self->app->repo->entries_find(sub { $_->id == $id });

  if ((!defined $mentry) or ($mentry->is_hidden)) {
    $self->render(
      text   => 'Cannot find entry ID \'' . $id . '\'.',
      status => 404
    );
    return;
  }

  # PARSING BIBTEX

  #this should happen earlier!
  $mentry->bib(fix_bibtex_national_characters($mentry->bib));
  $mentry->populate_from_bib();

  my $bibtex_entry_str = $mentry->bib;
  my $bibtex_entry     = new Text::BibTeX::Entry();
  $bibtex_entry->parse_s($bibtex_entry_str);
  unless ($bibtex_entry->parse_ok) {
    $self->render(
      text => 'Error 503: Cannot parse BibTeX code for this entry! Entry id: '
        . $id,
      status => 503
    );    # TODO: check proper error code
    return;
  }

  # EXTRACTING IMPORTANT FIELDS

  # TITLE
  my $title = $mentry->get_title;

  my $citation_title = $title;

  # AUTHORS
  my @names;
  my @citation_authors;
  if ($bibtex_entry->exists('author')) {
    my @authors = $bibtex_entry->split('author');
    my (@n) = $bibtex_entry->names('author');
    @names = @n;
  }
  elsif ($bibtex_entry->exists('editor')) {
    my @authors = $bibtex_entry->split('editor');
    my (@n) = $bibtex_entry->names('editor');
    @names = @n;
  }
  for my $name (@names) {

    my $name_clean = "";
    $name_clean = decode('latex', $name_clean);
    my $firstname = undef;
    $firstname = join(' ', grep { defined $_ } $name->part('first'))
      if defined $name->part('first');
    my $von = undef;
    $von = join(' ', $name->part('von')) if defined $name->part('von');
    my $lastname = join(' ', $name->part('last'));
    my $jr       = undef;
    $jr = join(' ', $name->part('jr')) if defined $name->part('jr');

    $name_clean = $firstname;
    $name_clean .= " " . $von      if defined $von;
    $name_clean .= " " . $lastname if defined $lastname;
    $name_clean .= " " . $jr       if defined $jr;

    $name_clean =~ s/\ +/ /g;
    $name_clean =~ s/\ $//g;

    push @citation_authors, $name_clean;
  }

  # PUBLICATION DATE
  my $year = $bibtex_entry->get('year');

  my $month = 0;
  $month = $bibtex_entry->get('month') if $bibtex_entry->exists('month');

  my $days = 0;
  $days = $bibtex_entry->get('day') if $bibtex_entry->exists('day');
  my @day = ();
  @day = split("--", $days) if defined $days;
  my $first_day = 0;
  $first_day = $day[0] if defined $days;

  my $citation_publication_date = $year;

# $citation_publication_date .= "/".$month if defined $month;
# $citation_publication_date .= "/".$first_day if defined $first_day and defined $days;;

  # ABSTRACT
  my $abstract = $bibtex_entry->get('abstract');
  $abstract ||= "This paper has no abstract. The title is: " . $citation_title;

  $abstract = decode('latex', $abstract);
  $abstract =~ s/^\{//g;
  $abstract =~ s/\}$//g;

  # TYPE
  my $type = $bibtex_entry->type;

  my $citation_journal_title;       # OK
  my $citation_conference_title;    #ok
  my $citation_issn;                # IGNORE
  my $citation_isbn;                # IGNORE
  my $citation_volume;              #ok
  my $citation_issue;               # ok
  my $citation_firstpage;           #ok
  my $citation_lastpage;            #ok

  if ($type eq "article") {
    if ($bibtex_entry->exists('journal')) {
      $citation_journal_title = $bibtex_entry->get('journal');
      $citation_journal_title = decode('latex', $citation_journal_title);
    }
    if ($bibtex_entry->exists('volume')) {
      $citation_volume = $bibtex_entry->get('volume');
    }
    if ($bibtex_entry->exists('number')) {
      $citation_issue = $bibtex_entry->get('number');
    }
  }

  if ($bibtex_entry->exists('pages')) {
    my $pages = $bibtex_entry->get('pages');

    my @pages_arr;
    if ($pages =~ /--/) {
      @pages_arr = split("--", $pages);
    }
    elsif ($pages =~ /-/) {
      @pages_arr = split("--", $pages);
    }
    else {
      push @pages_arr, $pages;
      push @pages_arr, $pages;
    }
    $citation_firstpage = $pages_arr[0] if defined $pages_arr[0];
    $citation_lastpage  = $pages_arr[1] if defined $pages_arr[1];
  }

  if ($bibtex_entry->exists('booktitle')) {
    $citation_conference_title = $bibtex_entry->get('booktitle');
    $citation_conference_title = decode('latex', $citation_conference_title);
  }

  # TECH REPORTS AND THESES

  my $citation_dissertation_institution;
  my $citation_technical_report_institution;
  my $citation_technical_report_number;

  if ($type eq "mastersthesis" or $type eq "phdthesis") {
    $citation_dissertation_institution = $bibtex_entry->get('school')
      if $bibtex_entry->exists('school');
    $citation_dissertation_institution
      = decode('latex', $citation_dissertation_institution);
  }

  if ($type eq "techreport") {
    $citation_technical_report_institution = $bibtex_entry->get('institution')
      if $bibtex_entry->exists('institution');
    $citation_technical_report_institution
      = decode('latex', $citation_technical_report_institution);
    $citation_technical_report_number = $bibtex_entry->get('number')
      if $bibtex_entry->exists('number');
    $citation_technical_report_number = $bibtex_entry->get('type')
      if $bibtex_entry->exists('type');
  }

  # PDF URL
  my $citation_pdf_url = undef;

  if ($bibtex_entry->exists('pdf')) {
    my $local_file_paper = $mentry->get_attachment('paper');
    if ($local_file_paper and -e $local_file_paper) {
      $citation_pdf_url = $self->url_for(
        'download_publication_pdf',
        filetype => 'paper',
        id       => $id
      );
    }
    else {
      $citation_pdf_url = $bibtex_entry->get('pdf');
    }
  }
  elsif ($bibtex_entry->exists('slides')) {
    my $local_file_slides = $mentry->get_attachment('slides');
    if ($local_file_slides and -e $local_file_slides) {
      $citation_pdf_url = $self->url_for(
        'download_publication_pdf',
        filetype => 'slides',
        id       => $id
      );
    }
    else {
      $citation_pdf_url = $bibtex_entry->get('slides');
    }
  }
  elsif ($bibtex_entry->exists('url')) {
    $citation_pdf_url = $bibtex_entry->get('url');
  }
  else {
    # this entry has no pdf/slides/url. $citation_pdf_url remains undef
  }

  # READY SET OF VARIABLES HOLDING METADATA. Some may be undef
  my $ca_ref = \@citation_authors;

  $self->stash(
    citation_title                    => $citation_title,
    citation_authors                  => $ca_ref,
    abstract                          => $abstract,
    citation_publication_date         => $citation_publication_date,
    citation_journal_title            => $citation_journal_title,
    citation_conference_title         => $citation_conference_title,
    citation_issn                     => $citation_issn,
    citation_isbn                     => $citation_isbn,
    citation_volume                   => $citation_volume,
    citation_issue                    => $citation_issue,
    citation_firstpage                => $citation_firstpage,
    citation_lastpage                 => $citation_lastpage,
    citation_dissertation_institution => $citation_dissertation_institution,
    citation_technical_report_institution =>
      $citation_technical_report_institution,
    citation_technical_report_number => $citation_technical_report_number,
    citation_pdf_url                 => $citation_pdf_url
  );

  $self->render(template => 'publicationsSEO/meta');

}

1;
