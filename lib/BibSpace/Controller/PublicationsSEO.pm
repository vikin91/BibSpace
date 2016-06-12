# package BibSpace::Controller::PublicationsSEO;
package BibSpace::Controller::Publicationsseo; 
# this must be written in non-capitalized because otherwise you get error: 
# Class "BibSpace::Controller::Publicationsseo" is not a controller

use strict;
use warnings;
use utf8;
use Text::BibTeX; # parsing bib files
use DateTime;
use 5.010; #because of ~~

use TeX::Encode;
use Encode;

use BibSpace::Controller::Core; # ok
use BibSpace::Functions::FPublications; #ok
use BibSpace::Model::MEntry; # ok

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::UserAgent;
use Mojo::Log;




####################################################################################
sub metalist {
    say "CALL: BibSpace::Controller::PublicationsSEO::metalist ";
    my $self = shift;

    my @ids_arr = ();
    my @pubs = Fget_publications_main_hashed_args_only($self, {hidden => 0, entry_type=>'paper'});
    for my $entry (@pubs){
        my $eid = $entry->{id};
        push @ids_arr, $eid if defined $eid;
    }
    $self->stash(ids => \@ids_arr);
    $self->render(template => 'publicationsSEO/metalist');
}

####################################################################################

sub meta {
	say "CALL: BibSpace::Controller::PublicationsSEO::meta";
  my $self = shift;
  my $id = $self->param('id');

  my $mentry = MEntry->static_get($self->app->db, $id);
  if(!defined $mentry){
    $self->flash(msg => "There is no entry with id $id");
    $self->redirect_to($self->get_referrer);  
    return;
  }

  if($mentry->{hidden} == 1){
    $self->render(text => 'Cannot find entry id: '.$id, status => 404);
    return;
  }
    

  # PARSING BIBTEX

  my $entry_str = $mentry->{bib};
  my $entry = new Text::BibTeX::Entry();
  $entry->parse_s($entry_str);
  unless($entry->parse_ok){
    $self->render(text => 'Cannot parse BibTeX code for this entry! Entry id: '.$id, status => 503); # TODO: check proper error code
    return;   
  }

  # EXTRACTING IMPORTANT FIELDS

  # TITLE
  my $title = $entry->get('title') || '';
  $title =~ s/\{//g;
  $title =~ s/\}//g;
  $title = decode('latex', $title);

  my $citation_title = $title;

  # AUTHORS
  my @names;
  my @citation_authors;
  if($entry->exists('author')){
    my @authors = $entry->split('author');
    my (@n) = $entry->names('author');
    @names = @n;
  }
  elsif($entry->exists('editor')){
    my @authors = $entry->split('editor');
    my (@n) = $entry->names('editor');
    @names = @n;
  }
  for my $name (@names){

    my $name_clean = "";
    $name_clean = decode('latex', $name_clean);
    my $firstname = join (' ', $name->part('first'));
    my $von = join (' ', $name->part('von'));
    my $lastname = join (' ', $name->part('last'));
    my $jr = join (' ', $name->part('jr'));

    $name_clean = $firstname;
    $name_clean .= " ".$von if defined $von;
    $name_clean .= " ".$lastname if defined $lastname;
    $name_clean .= " ".$jr if defined $jr;

    $name_clean =~ s/\ +/ /g;
    $name_clean =~ s/\ $//g;

    push @citation_authors, $name_clean;
  }


  # PUBLICATION DATE
  my $year = $entry->get('year');

  my $month = 0;
  $month = $entry->get('month') if $entry->exists('month');

  my $days = 0;
  $days = $entry->get('day') if $entry->exists('day');
  my @day = ();
  @day = split("--", $days) if defined $days;
  my $first_day = 0;
  $first_day = $day[0] if defined $days;

  my $citation_publication_date = $year;
  # $citation_publication_date .= "/".$month if defined $month;
  # $citation_publication_date .= "/".$first_day if defined $first_day and defined $days;;

  # ABSTRACT
  my $abstract = $entry->get('abstract') || "This paper has no abstract. The title is: ".$citation_title;
  $abstract =~ s/\{//g;
  $abstract =~ s/\}//g;
  $abstract = decode('latex', $abstract);

  # TYPE
  my $type = $entry->type;

  my $citation_journal_title; # OK
  my $citation_conference_title; #ok
  my $citation_issn;  # IGNORE
  my $citation_isbn;  # IGNORE
  my $citation_volume; #ok
  my $citation_issue; # ok
  my $citation_firstpage; #ok
  my $citation_lastpage; #ok

  if($type eq "article"){
    if($entry->exists('journal')){
        $citation_journal_title = $entry->get('journal');
        $citation_journal_title = decode('latex', $citation_journal_title);
    }
    if($entry->exists('volume')){
        $citation_volume = $entry->get('volume');
    }
    if($entry->exists('number')){
        $citation_issue = $entry->get('number');
    }
  }

  if($entry->exists('pages')){
    my $pages = $entry->get('pages');

    my @pages_arr;
    if ($pages =~ /--/) {
        @pages_arr = split("--", $pages);
    }
    elsif ($pages =~ /-/) {
        @pages_arr = split("--", $pages);
    }
    else{
        push @pages_arr, $pages;
        push @pages_arr, $pages;
    }
    $citation_firstpage = $pages_arr[0] if defined $pages_arr[0];
    $citation_lastpage = $pages_arr[1] if defined $pages_arr[1];
  }

  if($entry->exists('booktitle')){
    $citation_conference_title = $entry->get('booktitle');
    $citation_conference_title = decode('latex', $citation_conference_title);
  }


  # TECH REPORTS AND THESES

  my $citation_dissertation_institution;
  my $citation_technical_report_institution;
  my $citation_technical_report_number;

  if($type eq "mastersthesis" or $type eq "phdthesis"){
    $citation_dissertation_institution = $entry->get('school') if $entry->exists('school');
    $citation_dissertation_institution = decode('latex', $citation_dissertation_institution);
  }

  if($type eq "techreport"){
    $citation_technical_report_institution = $entry->get('institution') if $entry->exists('institution');
    $citation_technical_report_institution = decode('latex', $citation_technical_report_institution);
    $citation_technical_report_number = $entry->get('number') if $entry->exists('number');
    $citation_technical_report_number = $entry->get('type') if $entry->exists('type');
  }


  # PDF URL
  my $citation_pdf_url = undef;
  $citation_pdf_url = $self->url_for('download_publication_pdf', filetype=>'paper', id=>$id) if $entry->exists('pdf');
  $citation_pdf_url = $self->url_for('download_publication_pdf', filetype=>'slides', id=>$id) if $entry->exists('slides');
  $citation_pdf_url = $entry->get('url') if $entry->exists('url') and $entry->get('url') =~ /.*\.pdf^/;





  # READY SET OF VARIABLES HOLDING METADATA. Some may be undef
  my $ca_ref = \@citation_authors;

  $self->stash(citation_title => $citation_title,
   citation_authors => $ca_ref,
   abstract => $abstract,
   citation_publication_date => $citation_publication_date,
   citation_journal_title => $citation_journal_title,
   citation_conference_title => $citation_conference_title,
   citation_issn => $citation_issn,
   citation_isbn => $citation_isbn,
   citation_volume => $citation_volume,
   citation_issue => $citation_issue,
   citation_firstpage => $citation_firstpage,
   citation_lastpage => $citation_lastpage,
   citation_dissertation_institution => $citation_dissertation_institution,
   citation_technical_report_institution => $citation_technical_report_institution,
   citation_technical_report_number => $citation_technical_report_number,
   citation_pdf_url => $citation_pdf_url);

  $self->render(template => 'publicationsSEO/meta');

 }
####################################################################################


1;
