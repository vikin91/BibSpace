package BibSpace::Controller::PublicationsLanding;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;

# use File::Slurp;     # should be replaced in the future
use Path::Tiny;      # for creating directories
use Try::Tiny;

use v5.16;           #because of ~~
use strict;
use warnings;


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


=item NAMING CONVENTION

Peer-Reviewed Journal and Magazine Articles <--- this is section (the text is section description)

             VVV these are entries in this section VVV
[2] Christoph Müller, Piotr Rygielski, Simon Spinner, and Samuel Kounev. Enabling Fluid Analysis for ...
[1] Aleksandar Milenkoski, Alexandru Iosup, Samuel Kounev, Kai Sachs, Diane E. Mularz, Jonathan A. Cu...

Peer-Reviewed International Conference, Workshop Papers, and Book Chapters <--- this is section (the text is section description)

             VVV these are entries in this section VVV
[4] Piotr Rygielski, Marian Seliuchenko, Samuel Kounev, and Mykhailo Klymash. Performance Analysis of...
[3] Piotr Rygielski, Marian Seliuchenko, and Samuel Kounev. Modeling and Prediction of Software-Defin...
[2] Piotr Rygielski, Viliam Simko, Felix Sittner, Doris Aschenbrenner, Samuel Kounev, and Klaus Schil...
=cut 

our $text_delimiter_l = '';
our $text_delimiter_r = '';
our $anchor_delimiter_l = ' [';
our $anchor_delimiter_r = '] ';
############################################################################################################
## Controller function
sub landing_types {
    my $self        = shift;
    my $bibtex_type = $self->param('bibtex_type') // undef;
    my $entry_type  = $self->param('entry_type') // undef;

    my @all_types
        = $self->app->repo->types_filter( sub { $_->onLanding == 1 } );

    # key: our bibtex type
    # value: description of our bibtex type
    my %hash_our_type_to_description
        = map { $_->our_type => $_->description } @all_types;


    my @entries_to_show;
    my @section_names = keys %hash_our_type_to_description;

    ##########
    ## Step 1: define which sections to show on the landing list and get the entire papers set for this filtering query
    ##########
    if ($bibtex_type) {

       # user wants to filter on bibtex_type => user wants to show only papers
       # we assume that talks do not have bibtex_type - they are special

        @section_names   = ($bibtex_type);
        @entries_to_show = $self->get_papers_for_landing;
    }
    elsif ( $entry_type and $entry_type eq 'talk' ) {

        # user wants to show only talks

        # this needs to be added manually as talks are special
        $hash_our_type_to_description{'talk'} = "Talks";
        @section_names                        = ('talk');
        @entries_to_show                      = $self->get_talks_for_landing;
    }
    elsif ( $entry_type and $entry_type eq 'paper' ) {

        # user wants to show only papers

        # this needs to be added manually as talks are special
        @entries_to_show = $self->get_papers_for_landing;
    }
    else {
        # user wants to show everything = talks and papers

        # this needs to be added manually as talks are special
        $hash_our_type_to_description{'talk'} = "Talks";
        push @section_names, 'talk';
        @entries_to_show = $self->get_entries_for_landing;
    }

    ##########
    ## Step 2: set default section descriptions if needed
    ##########
    ## issue default description if there is no custom description in the system
    foreach my $section_name ( sort reverse @section_names ) {
        if ( !exists( $hash_our_type_to_description{$section_name} ) ) {
            $hash_our_type_to_description{$section_name}
                = get_generic_type_description($section_name);
        }
    }


    # key: our bibtex type
    # value: ref to array of entry objects
    my %hash_our_type_to_entries;

    ##########
    ## Step 3: assign papers to given sections
    ##########

    my @sections_having_entries;
    foreach my $section_name ( sort reverse @section_names ) {

        # TODO: refactor into: get_entries_for_section
        my @entries_in_section;
        if ( $section_name eq 'talk' ) {
            @entries_in_section = grep { $_->is_talk } @entries_to_show;
        }
        else {
            @entries_in_section
                = grep { $_->is_paper and $_->bibtex_type eq $section_name }
                @entries_to_show;
        }

        $hash_our_type_to_entries{$section_name} = \@entries_in_section;

        if ( scalar(@entries_in_section) > 0 ) {
            push @sections_having_entries, $section_name;
        }
    }

    ## hash_our_type_to_entries:  our bibtex type string -> ref_arr_entry_objects
    ## hash_our_type_to_description:    our bibtex type string -> our bibtex type description string
    ## sections_having_entries: array of section names that have more than 0 entries
    return $self->display_landing(
        \%hash_our_type_to_entries, \%hash_our_type_to_description,
        \@sections_having_entries,  $self->get_switchlink_html('years'),
        $self->get_filtering_navbar_html()
    );
}
############################################################################################################
## Controller function
sub landing_years {
    my $self = shift;
    my $year = $self->param('year') // undef;
    my $author = $self->param('author') // undef;

    # shows talks + papers by default
    # my $entry_type = $self->param('entry_type') // undef;


    my $min_year = $self->get_year_of_oldest_entry($author) // $self->current_year;
    my $max_year = $self->current_year;

    # 8 is a month in which we show publications from the next year
    if ( $self->current_month > 8 ) {    # TODO export to config.
        $max_year++;
    }

    if ($year) {
        $min_year = $year;
        $max_year = $year;
    }

    my %hash_year_to_description
        = map { $_ => $_ } ( $min_year .. $max_year );
    my %hash_year_to_entries;

    ## fetch all entries outside of the loop
    my @all_entries = $self->get_entries_for_landing;

    foreach my $year ( $min_year .. $max_year ) {

        my @entries_to_show = grep { $_->year == $year } @all_entries;
        $hash_year_to_entries{$year} = \@entries_to_show;

        if ( scalar(@entries_to_show) == 0 ) {
            delete $hash_year_to_description{$year};
            delete $hash_year_to_entries{$year};

        }
    }

    my @sections_sorted = reverse sort keys %hash_year_to_entries;

    # displaying years - you may switch to types
    my $switchlink  = $self->get_switchlink_html("types");
    my $navbar_html = $self->get_filtering_navbar_html();

    return $self->display_landing( \%hash_year_to_entries,
        \%hash_year_to_description, \@sections_sorted, $switchlink,
        $navbar_html );
}
############################################################################################################
sub display_landing {
    my $self                         = shift;
    my $hash_our_type_to_entries     = shift;
    my $hash_our_type_to_description = shift;
    my $ordered_section_names_ref    = shift;
    my $switchlink                   = shift;
    my $navbar_html                  = shift;

    my $navbar      = $self->param('navbar')     // 0;
    my $show_title  = $self->param('title')      // 0;
    my $show_switch = $self->param('switchlink') // 1;
    my $query_permalink = $self->param('permalink');
    my $query_tag_name  = $self->param('tag');

    # reset switchlink if show_switch different to 1
    $switchlink  = "" if $show_switch != 1;
    $navbar_html = "" if $navbar != 1;


    my $display_tag_name;
    if ( defined $query_permalink ) {

        my $tag_obj_with_permalink = $self->app->repo->tags_find(
            sub {
                defined $_->permalink and $_->permalink eq $query_permalink;
            }
        );
        if ( defined $tag_obj_with_permalink ) {
            $display_tag_name = $tag_obj_with_permalink->name;
        }
        else {
            $display_tag_name = $query_permalink;
        }
    }
    elsif ( defined $query_tag_name ) {
        $display_tag_name = $query_tag_name;
    }

    if (    defined $display_tag_name
        and defined $show_title
        and $show_title == 1 )
    {
        $display_tag_name =~ s/_+/_/g;
        $display_tag_name =~ s/_/\ /g;
    }


    my $title = "Publications and Talks ";
    $title = " Publications "
        if $self->param('entry_type')
        and $self->param('entry_type') eq 'paper';
    $title = " Talks "
        if $self->param('entry_type')
        and $self->param('entry_type') eq 'talk';


    $title .= " of team '" . $self->param('team') . "'"
        if $self->param('team');
    $title .= " of author '" . $self->param('author') . "'"
        if $self->param('author');
    $title .= " labeled as '" . $display_tag_name . "'" if $display_tag_name;
    $title .= " of type '" . $self->param('bibtex_type') . "'"
        if $self->param('bibtex_type');
    $title .= " published in year '" . $self->param('year') . "'"
        if $self->param('year');

    # my $url = $self->req->url;
    # say "scheme ".$url->scheme;
    # say "userinfo ".$url->userinfo;
    # say "host ".$url->host;
    # say "port ".$url->port;
    # say "path ".$url->path;
    # say "query ".$url->query;
    # say "fragment ".$url->fragment;

    # keys = years
    # my @objs = @{ $hash_values{$year} };
    # foreach my $obj (@objs){
    $self->stash(
        hash_our_type_to_entries     => $hash_our_type_to_entries,
        hash_our_type_to_description => $hash_our_type_to_description,
        # this defines order of sections
        ordered_section_names        => $ordered_section_names_ref,
        navbar                       => $navbar_html,
        show_title                   => $show_title,
        title                        => $title,
        switch_link                  => $switchlink
    );
    $self->res->headers->header( 'Access-Control-Allow-Origin' => '*' );


    my $html
        = $self->render_to_string( template => 'publications/landing_obj' );
    $self->render( data => $html );

    # $self->render( template => 'publications/landing_obj' );
}
############################################################################################################
####################################### HELPER functions for this controller ###############################
############################################################################################################


sub get_switchlink_html {
    my $self    = shift;
    my $keyword = shift;

    my $str;
    $str .= 'Grouping: ';
    

    if ( $keyword eq 'years' ) {
        $str .= $anchor_delimiter_l.'<a class="landing_selected" href="' . $self->url_with('lp') . '">'.$text_delimiter_l.'Types'.$text_delimiter_r.'</a>'.$anchor_delimiter_r;
        $str .= $anchor_delimiter_l.'<a class="landing_normal"  href="' . $self->url_with('lyp') . '">'.$text_delimiter_l.'Years'.$text_delimiter_r.'</a>'.$anchor_delimiter_r;
    }
    elsif ( $keyword eq 'types' ) {
        $str .= $anchor_delimiter_l.'<a class="landing_normal"  href="' . $self->url_with('lp') . '">'.$text_delimiter_l.'Types'.$text_delimiter_r.'</a>'.$anchor_delimiter_r;
        $str .= $anchor_delimiter_l.'<a class="landing_selected" href="' . $self->url_with('lyp') . '">'.$text_delimiter_l.'Years'.$text_delimiter_r.'</a>'.$anchor_delimiter_r;
    }
    $str .= '</br>';
    return $str;
}
############################################################################################################
############################################################################################################
############################################################################################################
sub get_filtering_navbar_html { 
    my $self = shift;

    my $str;
    ############### KIND
    $str .= $self->get_navbar_kinds_html;
    ############### TYPES
    $str .= $self->get_navbar_types_html;
    ############### YEARS
    $str .= $self->get_navbar_years_html;

    $str .= '</br>';
    my $url = $self->url_with->query( [bibtex_type => undef, entry_type => undef, year => undef] );
    $str .= $anchor_delimiter_l.'<a href="'.$url.'">'.$text_delimiter_l.'clear all selections'.$text_delimiter_l.'</a>'.$anchor_delimiter_r;
    return $str;
}
############################################################################################################
sub get_navbar_kinds_html {
    my $self = shift;

    my $curr_bibtex_type = $self->req->param('bibtex_type') // undef;
    my $curr_entry_type  = $self->req->param('entry_type')  // undef;
    my $curr_year        = $self->req->param('year')        // undef;

    ############### KIND
    my $str;

    $str .= 'Kind: ';
    
    
    foreach my $key (qw(Paper Talk)) {

        my $url;
        if($key eq 'Talk'){
            $url = $self->url_with->query( [entry_type => lc($key), bibtex_type => undef] );
        }
        else{
            $url = $self->url_with->query( [entry_type => lc($key)] );   
        }
        
        my $text = $text_delimiter_l . $key . $text_delimiter_r;

        my $num = $self->num_pubs_filtering( 
            $curr_bibtex_type, 
            $key,
            $curr_year );

        if ( defined $curr_entry_type and lc($key) eq $curr_entry_type ) {
            $str .= $anchor_delimiter_l.'<a class="landing_selected" href="' . $url . '">'.$text.'</a>'.$anchor_delimiter_r;
        }
        else {
            $str .= $anchor_delimiter_l.'<a class="landing_normal" href="' . $url . '">'.$text.'</a>'.$anchor_delimiter_r;
        }
    }
    $str .= '</br>';
    $str;
}
############################################################################################################
sub get_navbar_types_html {
    my $self = shift;

    my $curr_bibtex_type = $self->req->param('bibtex_type') // undef;
    my $curr_entry_type  = $self->req->param('entry_type')  // undef;
    my $curr_year        = $self->req->param('year')        // undef;

    my @landingTypes
        = $self->app->repo->types_filter( sub { $_->onLanding == 1 } );

    my %bibtex_type_to_label
        = map { $_->our_type => $_->description } @landingTypes;
    foreach my $k ( keys %bibtex_type_to_label ) {
        if ( !$bibtex_type_to_label{$k} ) {
            $bibtex_type_to_label{$k} = get_generic_type_description($k);
        }
    }

    ############### TYPE
    my $str;

    $str .= 'Type: ';


    foreach my $type ( sort { $a->our_type cmp $b->our_type } @landingTypes )
    {
        my $key = $type->our_type;
        my $num = $self->num_pubs_filtering( $key, 'paper', $curr_year );
        my $url = $self->url_with->query( [bibtex_type => $key] );

        my $text = $text_delimiter_l . $bibtex_type_to_label{$key} . $text_delimiter_r;

        if ( defined $curr_bibtex_type and $key eq $curr_bibtex_type ) {
          if ($num) {
                $str .= $anchor_delimiter_l.'<a class="landing_selected" href="' . $url . '">'.$text.'</a>'.$anchor_delimiter_r;
                
            }
            else{
                $str .= $anchor_delimiter_l.'<a class="landing_selected landing_no_papers" href="' . $url . '">'.$text.'</a>'.$anchor_delimiter_r;
            }
        }
        else {
            if ($num) {
                $str .= $anchor_delimiter_l.'<a href="' . $url . '">'.$text.'</a>'.$anchor_delimiter_r;
            }
            else {
                $str .= $anchor_delimiter_l.'<a class="landing_no_papers" href="' . $url . '">'.$text.'</a>'.$anchor_delimiter_r;
            }
        }
    }
    $str .= '</br>';
    $str;
}
############################################################################################################
sub get_navbar_years_html {
    my $self = shift;

    my $curr_bibtex_type = $self->param('bibtex_type') // undef;
    my $curr_entry_type  = $self->param('entry_type')  // undef;
    my $curr_year        = $self->param('year')        // undef;
    my $author           = $self->param('author')      // undef;

    my $min_year = $self->get_year_of_oldest_entry($author) // $self->current_year;
    my $max_year = $self->current_year;

    # 8 is a month in which we show publications from the next year
    if ( $self->current_month > 8 ) {    # TODO export to config.
        $max_year++;
    }
    my @all_years = ( $min_year .. $max_year );
    @all_years = reverse @all_years;

    ############### YEARS
    my $str;
    $str .= 'Year: ';


    foreach my $key ( reverse sort @all_years ) {
        my $num = $self->num_pubs_filtering( 
                    $curr_bibtex_type, 
                    $curr_entry_type,
                    $key );

        my $url = $self->url_with->query( [year => $key] );
        my $text = $text_delimiter_l . $key . $text_delimiter_r;
        

        if ( defined $curr_year and $key eq $curr_year ) {
           if ($num) {
                $str .= $anchor_delimiter_l.'<a class="landing_selected" href="' . $url . '">';
                
            }
            else{
                $str .= $anchor_delimiter_l.'<a class="landing_selected landing_no_papers" href="' . $url . '">';
            }
        }
        else {
            if ($num) {
                $str .= $anchor_delimiter_l.'<a href="' . $url . '">';
            }
            else {
                $str .= $anchor_delimiter_l.'<a class="landing_no_papers" href="' . $url . '">';
            }
        }
        $str .= $text;
        $str .= '</a>'.$anchor_delimiter_r;
    }

    $str;
}
############################################################################################################
sub num_pubs_filtering {
    my $self             = shift;
    my $curr_bibtex_type = shift;
    my $curr_entry_type  = shift;
    my $curr_year        = shift;


    return scalar Fget_publications_main_hashed_args(
        $self,
        {   bibtex_type => $curr_bibtex_type,
            entry_type  => $curr_entry_type,
            year        => $curr_year,
            visible     => 1,
            hidden      => 0
        }
    );
}
############################################################################################################
############################################################################################################
############################################################################################################
sub get_papers_for_landing {
    my $self = shift;

    # undef is default, it means: all types
    my $bibtex_type = $self->param('bibtex_type') // undef;

    return Fget_publications_main_hashed_args(
        $self,
        {   bibtex_type => $bibtex_type,
            entry_type  => 'paper',
            visible     => 0,
            hidden      => 0

                # the rest of parameters will be taken from $self
        }
    );
}
############################################################################################################
sub get_talks_for_landing {
    my $self = shift;
    return Fget_publications_main_hashed_args(
        $self,
        {   bibtex_type => undef,
            entry_type  => 'talk',
            visible     => 0,
            hidden      => 0

                # the rest of parameters will be taken from $self
        }
    );
}
############################################################################################################
sub get_entries_for_landing {
    my $self = shift;
    return Fget_publications_main_hashed_args(
        $self,
        {   visible => 0,
            hidden  => 0,
            debug   => 1,

            # the rest of parameters will be taken from $self
        }
    );
}
############################################################################################################
1;
