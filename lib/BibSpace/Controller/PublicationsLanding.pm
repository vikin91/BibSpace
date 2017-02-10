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


############################################################################################################
sub get_switchlink {
    my $self    = shift;
    my $keyword = shift;
    my $str
        = '<button type="button" class="btn btn-primary btn-xs">View:</button>&nbsp;';

    # my $str = '<span class="label label-info" >View: </span>&nbsp;';

    if ( $keyword eq 'years' ) {

        $str
            .= '<a type="button" class="btn btn-primary btn-xs" href="'
            . $self->url_with('lp')
            . '">Types</a> ';
        $str
            .= '<a type="button" class="btn btn-default btn-xs" href="'
            . $self->url_with('lyp')
            . '">Years</a> ';
    }
    elsif ( $keyword eq 'types' ) {
        $str
            .= '<a type="button" class="btn btn-default btn-xs" href="'
            . $self->url_with('lp')
            . '">Types</a> ';
        $str
            .= '<a type="button" class="btn btn-primary btn-xs" href="'
            . $self->url_with('lyp')
            . '">Years</a> ';
    }

    # $str .= '<br/>';
    return $str;
}
############################################################################################################
############################################################################################################
############################################################################################################
sub get_filtering_navbar {    # only temporary TODO: refactor
    my $self = shift;

    my $str = $self->get_navbar_clear_filter_row;
    ############### KIND
    $str .= $self->get_filtering_navbar_kinds();
    ############### TYPES
    $str .= $self->get_filtering_navbar_types();
    ############### YEARS
    $str .= $self->get_filtering_navbar_years();
    return $str;
}
############################################################################################################
sub get_navbar_clear_filter_row {    # only temporary TODO: refactor
    my $self = shift;

    my $tmp_year = $self->req->url->query->param('year');
    $self->req->url->query->remove('year');

    my $str
        = '<button type="button" class="btn btn-primary btn-xs">Filter:</button>&nbsp;';
    $str
        .= '<a type="button" class="btn btn-default btn-xs" href="'
        . $self->url_with('current')
        . '">Clear year filter</a> ';

    $self->req->url->query->param( year => $tmp_year )
        if defined $tmp_year and $tmp_year ne "";
    $self->req->url->query->remove('bibtex_type');
    $self->req->url->query->remove('entry_type');

    $str
        .= '<a type="button" class="btn btn-default btn-xs" href="'
        . $self->url_with('current')
        . '">Clear type filter</a> ';
    $str .= '<br/>';
    return $str;
}
############################################################################################################
sub get_filtering_navbar_kinds {
    my $self = shift;

    my $curr_bibtex_type = $self->req->param('bibtex_type') // "";
    my $curr_entry_type  = $self->req->param('entry_type')  // "";
    my $curr_year        = $self->req->param('year')        // "";

    ############### KIND
    my $str
        .= '<button type="button" class="btn btn-primary btn-xs">Kind:</button>&nbsp;';
    foreach my $key (qw(paper talk)) {

        $self->req->url->query->param( year => $curr_year )
            if defined $curr_year;
        $self->req->url->query->param( entry_type => $key );
        $self->req->url->query->remove('bibtex_type');

        my $num = $self->num_pubs_filtering( $curr_bibtex_type, $key,
            $curr_year );

        if ( defined $curr_entry_type and $key eq $curr_entry_type ) {
            $str .= '<a type="button" class="btn btn-primary btn-xs" href="';
        }
        else {
            $str .= '<a type="button" class="btn btn-default btn-xs" href="';
        }
        $str .= $self->url_with( 'current', entry_type => $key );
        $str .= '">' . $key . '</a> ';
    }

    $str;
}
############################################################################################################
sub get_filtering_navbar_types {
    my $self = shift;

    my $curr_bibtex_type = $self->req->param('bibtex_type') // "";
    my $curr_entry_type  = $self->req->param('entry_type')  // "";
    my $curr_year        = $self->req->param('year')        // "";

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
    my $str
        .= '<br/><button type="button" class="btn btn-primary btn-xs">Types:</button>&nbsp;';

    foreach my $type ( sort { $a->our_type cmp $b->our_type } @landingTypes )
    {
        my $key = $type->our_type;

        $self->req->url->query->param( year => $curr_year )
            if defined $curr_year;
        $self->req->url->query->remove('year') if !defined $curr_year;
        $self->req->url->query->param( entry_type  => 'paper' );
        $self->req->url->query->param( bibtex_type => $key );

        my $num = $self->num_pubs_filtering( $key, 'paper', $curr_year );

        if ( defined $curr_bibtex_type and $key eq $curr_bibtex_type ) {
            $str .= '<a type="button" class="btn btn-primary btn-xs" href="';
        }
        else {
            $str .= '<a type="button" class="btn btn-default btn-xs" href="';
        }
        $str .= $self->url_with( 'current', bibtex_type => $key );
        if ($num) {
            $str .= '">' . $bibtex_type_to_label{$key} . '</a> ';
        }
        else {
            $str .= '" disabled="disabled">'
                . $bibtex_type_to_label{$key} . '</a> ';
        }

    }

    $str;
}
############################################################################################################
sub get_filtering_navbar_years {
    my $self = shift;

    my $curr_bibtex_type = $self->req->param('bibtex_type') // "";
    my $curr_entry_type  = $self->req->param('entry_type')  // "";
    my $curr_year        = $self->req->param('year')        // "";

    my $min_year = $self->get_year_of_oldest_entry // $self->current_year;
    my $max_year = $self->current_year;

    # 8 is a month in which we show publications from the next year
    if ( $self->current_month > 8 ) {    # TODO export to config.
        $max_year++;
    }
    my @all_years = ( $min_year .. $max_year );
    @all_years = reverse @all_years;

    ############### YEARS
    my $str
        .= '<br/><button type="button" class="btn btn-primary btn-xs">Years:</button>&nbsp;';

    foreach my $key ( reverse sort @all_years ) {
        $self->req->url->query->param( entry_type => $curr_entry_type )
            if defined $curr_entry_type;
        $self->req->url->query->remove('entry_type')
            if !defined $curr_entry_type;
        $self->req->url->query->param( bibtex_type => $curr_bibtex_type )
            if defined $curr_bibtex_type;
        $self->req->url->query->remove('bibtex_type')
            if !defined $curr_bibtex_type;
        $self->req->url->query->param( year => $key );
        my $num
            = $self->num_pubs_filtering( $curr_bibtex_type, $curr_entry_type,
            $key );


        if ( defined $curr_year and $key eq $curr_year ) {
            $str .= '<a type="button" class="btn btn-primary btn-xs" href="';
        }
        else {
            $str .= '<a type="button" class="btn btn-default btn-xs" href="';
        }
        $str .= $self->url_with( 'current', year => $key );
        if ($num) {
            $str .= '">' . $key . '</a>';
        }
        else {
            $str .= '" disabled="disabled">' . $key . '</a>';
        }
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
    my $self        = shift;
    my $bibtex_type = $self->param('bibtex_type') // undef; # undef is default -> all types

    return  Fget_publications_main_hashed_args(
        $self,
        {   bibtex_type => $bibtex_type,
            entry_type  => 'paper',
            visible     => 0,
            hidden      => 0
        }
    );
}
############################################################################################################

sub get_talks_for_landing { 
    my $self        = shift;

    return  Fget_publications_main_hashed_args(
        $self,
        {   bibtex_type => undef,
            entry_type  => 'talk',
            visible     => 0,
            hidden      => 0
        }
    );

}
############################################################################################################

sub landing_types_obj {  
    my $self        = shift;
    my $bibtex_type = $self->param('bibtex_type') // undef;
    my $entry_type  = $self->param('entry_type') // undef;

    my @all_types
        = $self->app->repo->types_filter( sub { $_->onLanding == 1 } );

    # key: our bibtex type
    # value: description of our bibtex type
    my %hash_our_type_to_description = map { $_->our_type => $_->description } @all_types;

    
    my @entries_to_show;
    my @section_names = keys %hash_our_type_to_description;

    ##########
    # Step 1: define which sections to show on the landing list and get the entire papers set for this filtering query
    ##########
    if ( $bibtex_type ) { 
        # user wants to filter on bibtex_type => user wants to show only papers
        # we assume that talks do not have bibtex_type - they are special

        @section_names = ($bibtex_type);
        @entries_to_show = $self->get_papers_for_landing;
    }
    elsif ( $entry_type and $entry_type eq 'talk') { 
        # user wants to show only talks

        # this needs to be added manually as talks are special
        $hash_our_type_to_description{'talk'} = "Talks";    
        @section_names = ('talk');
        @entries_to_show = $self->get_talks_for_landing;
    }
    elsif ( $entry_type and $entry_type eq 'paper') { 
        # user wants to show only papers

        # this needs to be added manually as talks are special
        @entries_to_show = $self->get_papers_for_landing;
    }
    else{  
        # user wants to show everything = talks and papers

        # this needs to be added manually as talks are special
        $hash_our_type_to_description{'talk'} = "Talks";    
        push @section_names, 'talk';
        @entries_to_show = ($self->get_talks_for_landing, $self->get_papers_for_landing);   
    }

    ##########
    # Step 2: set default section descriptions if needed
    ##########
    # issue default description if there is no custom description in the system
    foreach my $section_name ( sort reverse @section_names ) {
        if ( !exists( $hash_our_type_to_description{ $section_name } ) ) {
            $hash_our_type_to_description{ $section_name }
                = get_generic_type_description( $section_name );
        }
    }


    # key: our bibtex type
    # value: ref to array of entry objects
    my %hash_our_type_to_entries;

    ##########
    # Step 3: assign papers to given sections
    ##########

    my @sections_having_entries;
    foreach my $section_name ( sort reverse @section_names ) {

        # TODO: refactor into: get_entries_for_section
        my @entries_in_section;
        if ( $section_name eq 'talk' ) {
            @entries_in_section = grep { $_->is_talk } @entries_to_show;
        }
        else {
            @entries_in_section = grep { $_->is_paper and $_->bibtex_type eq $section_name } @entries_to_show;
        }

        $hash_our_type_to_entries{ $section_name } = \@entries_in_section;

        if ( scalar(@entries_in_section) > 0 ) {
            push @sections_having_entries, $section_name;
        }
    }

    # hash_our_type_to_entries:  our bibtex type string -> ref_arr_entry_objects
    # hash_our_type_to_description:    our bibtex type string -> our bibtex type description string 
    # sections_having_entries: array of section names that have more than 0 entries
    return $self->display_landing(
        \%hash_our_type_to_entries, \%hash_our_type_to_description, \@sections_having_entries,
        $self->get_switchlink('years'),
        $self->get_filtering_navbar()
    );
}
############################################################################################################

sub landing_years_obj {
    my $self = shift;
    my $year = $self->param('year') || undef;

# if you want to list talks+papers by default on the landing_years page, use the following line
    my $entry_type = $self->param('entry_type') || undef;

# if you want to list ONLY papers by default on the landing_years page, use the following line
# my $entry_type = $self->param('entry_type') || 'paper';

    my $min_year = $self->get_year_of_oldest_entry // $self->current_year;
    my $max_year = $self->current_year;

    # 8 is a month in which we show publications from the next year
    if ( $self->current_month > 8 ) {    # TODO export to config.
        $max_year++;
    }

    if ( defined $year ) {
        $min_year = $year;
        $max_year = $year;
    }

    my %hash_our_type_to_description;
    my %hash_our_type_to_entries;
    my @allkeys = ( $min_year .. $max_year );
    @allkeys = reverse @allkeys;

    my @objs_arr;
    my @keys;

    foreach my $yr (@allkeys) {

        my @objs = Fget_publications_main_hashed_args(
            $self,
            {   year       => $yr,
                entry_type => $entry_type,
                visible    => 0,
                hidden     => 0
            }
        );

        # delete the year from the @keys array if the year has 0 papers
        if ( scalar @objs > 0 ) {
            $hash_our_type_to_description{$yr}   = $yr;
            $hash_our_type_to_entries{$yr} = \@objs;
            push @keys, $yr;
        }
    }

    my $switchlink = $self->get_switchlink("types");
    my $navbar_html
        = $self->get_filtering_navbar( \@keys, \%hash_our_type_to_description, 'years' );

    return $self->display_landing( \%hash_our_type_to_entries, \%hash_our_type_to_description, \@keys,
        $switchlink, $navbar_html );
}
############################################################################################################
sub display_landing {
    my $self                      = shift;
    my $hash_our_type_to_entries
= shift;
    my $hash_our_type_to_description = shift;
    my $keys_ref                  = shift;
    my $switchlink                = shift;
    my $navbar_html               = shift;

    my $navbar     = $self->param('navbar') || 0;
    my $show_title = $self->param('title')  || 0;
    my $show_switch     = $self->param('switchlink');
    my $query_permalink = $self->param('permalink');
    my $query_tag_name  = $self->param('tag');

    # if you ommit the switchlink param, assume default = enabled
    # by 0, do not show
    # by 1, do show
    $show_switch = 1 unless defined $show_switch;

    # reset switchlink if show_switch different to 1
    $switchlink = "" unless $show_switch == 1;

    $navbar_html = "" unless $navbar == 1;


    my $display_tag_name;
    if ( defined $query_permalink ) {

        my $tag_obj_with_permalink = $self->app->repo->tags_find(
            sub {
                ( defined $_->permalink
                        and ( $_->permalink cmp $query_permalink ) == 0 );
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


    my $title = "";
    $title .= " Publications "
        if $self->param('entry_type')
        and $self->param('entry_type') eq 'paper';
    $title .= " Talks "
        if $self->param('entry_type')
        and $self->param('entry_type') eq 'talk';
    $title .= " Publications and talks" if !$self->param('entry_type');

    $title .= " of team '" . $self->param('team') . "'"
        if defined $self->param('team');
    $title .= " of author '" . $self->param('author') . "'"
        if defined $self->param('author');
    $title .= " labeled as '" . $display_tag_name . "'"
        if defined $display_tag_name;
    $title .= " of type '" . $self->param('bibtex_type') . "'"
        if defined $self->param('bibtex_type');
    $title .= " published in year '" . $self->param('year') . "'"
        if defined $self->param('year');

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
        hash_our_type_to_entries
    => $hash_our_type_to_entries,
        hash_our_type_to_description => $hash_our_type_to_description,
        keys                      => $keys_ref,
        navbar                    => $navbar_html,
        show_title                => $show_title,
        title                     => $title,
        switch_link               => $switchlink
    );
    $self->res->headers->header( 'Access-Control-Allow-Origin' => '*' );


    my $html = $self->render_to_string( template => 'publications/landing_obj' );
    $self->render( data => $html );

    # $self->render( template => 'publications/landing_obj' );
}
############################################################################################################
1;
