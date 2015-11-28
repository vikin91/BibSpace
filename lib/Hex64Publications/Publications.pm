package Hex64Publications::Publications;

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

use Hex64Publications::Core;
use Hex64Publications::Set;

use Set::Scalar;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::UserAgent;
use Mojo::Log;
use EntryObj;
use TagObj;


####################################################################################
sub get_back_url {
    my $self = shift;
    my $back_url = shift;
    return '/publications' if !defined $back_url or $back_url eq '' or $back_url eq $self->req->url->to_abs;
}
####################################################################################
sub isTalk {  # stupid code repetition!
    my $self = shift;
    my $obj = shift;
    return $obj->isTalk();
}
####################################################################################
sub fixMonths {
    say "CALL: fixMonths ";
    my $self = shift;
    my $back_url = $self->param('back_url');
    $back_url = $self->get_back_url($back_url);

    my @objs = EntryObj->getAll($self->app->db);
    for my $o (@objs){
            my $entry = new Text::BibTeX::Entry();
            $entry->parse_s($o->{bib});

            after_edit_process_month($self->app->db, $entry);

            #check
            # if($entry->exists('month')){
            #     my $month_str = $entry->get('month');
            #     my $month_numeric = get_month_numeric($month_str);

            #     say "ENTRY $o->{id}  MONTH_STR $month_str MONTH_INT $month_numeric" if $month_numeric > 12 or $month_numeric == 0;
            # }

    }
    $self->redirect_to($back_url);
}
####################################################################################
sub fixEntryType {
    say "CALL: fixEntryType ";
    my $self = shift;
    my $back_url = $self->param('back_url');
    $back_url = $self->get_back_url($back_url);

    my @objs = EntryObj->getAll($self->app->db);
    for my $o (@objs){
        $o->fixEntryTypeBasedOnTag($self->app->db);
    }

    # $self->write_log("Cleaning ugly bibtex fields for all entries");
    # $self->helper_clean_ugly_bibtex_fileds_for_all_entries();
    # $self->write_log("Cleaning ugly bibtex fields for all entries has finished");
    $self->redirect_to($back_url);
}
####################################################################################
sub unhide {
    my $self = shift;
    my $id = $self->param('id');
    my $back_url = $self->param('back_url');
    my $dbh = $self->app->db;

    $back_url = $self->get_back_url($back_url);

    my $obj = EntryObj->new({id => $id});
    $obj->initFromDB($dbh);
    $obj->unhide($dbh);

    $self->redirect_to($back_url);
};

####################################################################################
sub hide {
    my $self = shift;
    my $id = $self->param('id');
    my $back_url = $self->param('back_url');
    my $dbh = $self->app->db;

    $back_url = $self->get_back_url($back_url);

    my $obj = EntryObj->new({id => $id});
    $obj->initFromDB($dbh);
    $obj->hide($dbh);

    $self->redirect_to($back_url);
};
####################################################################################
sub toggle_hide {
    my $self = shift;
    my $id = $self->param('id');
    my $back_url = $self->param('back_url');
    my $dbh = $self->app->db;

    $back_url = $self->get_back_url($back_url);

    my $obj = EntryObj->new({id => $id});
    $obj->initFromDB($dbh);
    $obj->toggle_hide($dbh);

    $self->redirect_to($back_url);
};
####################################################################################
sub make_paper {
    my $self = shift;
    my $id = $self->param('id');
    my $back_url = $self->param('back_url');
    my $dbh = $self->app->db;

    $back_url = $self->get_back_url($back_url);

    my $obj = EntryObj->new({id => $id});
    $obj->initFromDB($dbh);
    $obj->makePaper($dbh);

    $self->redirect_to($back_url);
};
####################################################################################
sub make_talk {
    my $self = shift;
    my $id = $self->param('id');
    my $back_url = $self->param('back_url');
    my $dbh = $self->app->db;

    $back_url = $self->get_back_url($back_url);

    my $obj = EntryObj->new({id => $id});
    $obj->initFromDB($dbh);
    $obj->makeTalk($dbh);

    $self->redirect_to($back_url);
};
####################################################################################
sub metalist {
	say "CALL: metalist ";
    my $self = shift;

    my @ids_arr = get_all_non_hidden_entry_ids($self->app->db);
    $self->stash(ids => \@ids_arr);

    $self->render(template => 'publications/metalist'); 
}

####################################################################################

sub meta {
	say "CALL: meta ";
    my $self = shift;
    my $id = $self->param('id');



    # FETCHING DATA FROM DB
    my $dbh = $self->app->db;
    my $sth = $dbh->prepare( "SELECT DISTINCT id, hidden, bibtex_key, bib, html
        FROM Entry 
        WHERE id = ? AND hidden=0" );  
    $sth->execute($id);

    my $bib = "";
    while(my $row = $sth->fetchrow_hashref()) {
        $bib = $row->{bib};
    }

    $self->render(text => 'Cannot find entry id: '.$id) if $bib eq "";
    return if $bib eq "";

    # PARSING BIBTEX

    my $entry_str = $bib;
    my $entry = new Text::BibTeX::Entry();
    $entry->parse_s($entry_str);
    $self->render(text => 'Cannot parse BibTeX code for this entry! Entry id: '.$id) unless $entry->parse_ok;
    return unless $entry->parse_ok;

    # EXTRACTING IMPORTANT FIELDS

    # TITLE
    my $title = $entry->get('title') || '';
    $title =~ s/\{//g;
    $title =~ s/\}//g;

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
    
    my $month = undef;
    $month = $entry->get('month') if $entry->exists('month');
    
    my $days = undef;
    $days = $entry->get('day') if $entry->exists('day');
    my @day = split("--", $days) if defined $days;
    my $first_day = $day[0] if defined $days;

    my $citation_publication_date = $year;
    # $citation_publication_date .= "/".$month if defined $month;
    # $citation_publication_date .= "/".$first_day if defined $first_day and defined $days;;

    # ABSTRACT
    my $abstract = $entry->get('abstract') || "This paper has no abstract. The title is: ".$citation_title;
    $abstract =~ s/\{//g;
    $abstract =~ s/\}//g;

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
        $citation_conference_title = $entry->get('booktitle')
    }


    # TECH REPORTS AND THESES

    my $citation_dissertation_institution;
    my $citation_technical_report_institution;
    my $citation_technical_report_number;

    if($type eq "mastersthesis" or $type eq "phdthesis"){
        $citation_dissertation_institution = $entry->get('school') if $entry->exists('school');
    }

    if($type eq "techreport"){
        $citation_technical_report_institution = $entry->get('institution') if $entry->exists('institution');
        $citation_technical_report_number = $entry->get('number') if $entry->exists('number');
        $citation_technical_report_number = $entry->get('type') if $entry->exists('type');
    }


    # PDF URL 
    my $citation_pdf_url = $entry->get('pdf') if $entry->exists('pdf');
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

    $self->render(template => 'publications/meta');  
    
 }
####################################################################################
sub all_recently_added {
    say "CALL: all_recently_added "; 
    my $self = shift;
    my $num = $self->param('num') || 10;
    my $dbh = $self->app->db;

    $self->write_log("Displaying recently added entries num $num");

    my $qry = "SELECT DISTINCT id, bibtex_key, creation_time FROM Entry ORDER BY creation_time DESC LIMIT ?";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($num); 

    my @array;
    while(my $row = $sth->fetchrow_hashref()) {
        my $eid = $row->{id};
        push @array, $eid;
    }

    my @objs = get_publications_core_from_array($self, \@array, 0);

    $self->stash(objs => \@objs);
    $self->render(template => 'publications/all');  
}
####################################################################################

sub all_recently_modified {
	say "CALL: all_recently_modified ";
    my $self = shift;
    my $num = $self->param('num') || 10;
    my $dbh = $self->app->db;

    $self->write_log("Displaying recently modified entries num $num");

    my $qry = "SELECT DISTINCT id, bibtex_key, modified_time FROM Entry ORDER BY modified_time DESC LIMIT ?";

    my $sth = $dbh->prepare( $qry );  
    $sth->execute($num); 

    my @array;
    while(my $row = $sth->fetchrow_hashref()) {
        my $eid = $row->{id};
        push @array, $eid;
    }


    my @objs = get_publications_core_from_array($self, \@array, 0);
    $self->stash(objs => \@objs);
    $self->render(template => 'publications/all');  
}
####################################################################################
sub all_with_pdf_on_sdq{
    say "CALL: all_with_pdf_on_sdq ";
    my $self = shift;
    my $num = $self->param('num') || 10;
    my $dbh = $self->app->db;

    $self->write_log("Displaying papers with pdfs on sdq server");


    my $qry = "SELECT id from Entry WHERE html_bib LIKE ?";

    my $sth = $dbh->prepare( $qry );  
    $sth->execute("%sdqweb%"); 

    my @array;
    while(my $row = $sth->fetchrow_hashref()) {
        my $eid = $row->{id};
        push @array, $eid;
    }

    my $msg = "This list contains papers that have pdfs on the sdqweb server. Please use this list to move pdfs to our server - this improves the performance.";

    my @objs = get_publications_core_from_array($self, \@array);
    $self->stash(objs => \@objs, msg => $msg);
    $self->render(template => 'publications/all');  
}
####################################################################################
sub all_without_tag {
	say "CALL: all_without_tag ";
    my $self = shift;
    my $tagtype = $self->param('tagtype') || 1;
    my $dbh = $self->app->db;

    $self->write_log("Displaying papers without any tag of type $tagtype");

    my $qry = "SELECT DISTINCT id, bibtex_key 
                FROM Entry 
                WHERE entry_type = 'paper' 
                AND id NOT IN (
                    SELECT DISTINCT entry_id 
                    FROM Entry_to_Tag
                    LEFT JOIN Tag ON Tag.id = Entry_to_Tag.tag_id
                    WHERE Tag.type = ?)
                    ORDER BY year DESC";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($tagtype); 

    my @array;
    while(my $row = $sth->fetchrow_hashref()) {
      my $eid = $row->{id};
      push @array, $eid;
    }

    my $msg = "This list contains papers with no tags (of type $tagtype) assigned. Use this list to tag the untagged papers! ";


    my @objs = get_publications_core_from_array($self, \@array);
    $self->stash(objs => \@objs, msg => $msg);
    $self->render(template => 'publications/all');  
}
####################################################################################
sub all_without_tag_for_author {
	say "CALL: all_without_tag_for_author ";
    my $self = shift;
    my $dbh = $self->app->db;
    my $author = $self->param('author');
    my $tagtype = $self->param('tagtype');
    my $aid = -1;

    my $mid = get_master_id_for_master($dbh, $author) || -1;
    if($mid == -1){ #no such master. Assume, that author id was given
        $aid = $author;
    }
    else{
        $aid = $mid;
    }
    
    
    my $str = "Displaying papers without any tag of type $tagtype for author id $aid";
    $self->write_log($str);
    say $str;

    my $qry = "SELECT DISTINCT id, bibtex_key, year, sort_month
                FROM Entry 
                LEFT JOIN Entry_to_Author ON Entry.id = Entry_to_Author.entry_id 
                WHERE Entry_to_Author.author_id = ?
                AND entry_type='paper'
                AND id NOT IN (
                    SELECT DISTINCT entry_id 
                    FROM Entry_to_Tag
                    LEFT JOIN Tag ON Tag.id = Entry_to_Tag.tag_id
                    WHERE Tag.type = ?)
                ORDER BY year, sort_month DESC";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($aid, $tagtype); 

    my @array;
    while(my $row = $sth->fetchrow_hashref()) {
        my $eid = $row->{id};
        push @array, $eid;
    }

    my $msg = "This list contains papers with no tags (of type $tagtype) assigned. Use this list to tag the untagged papers! ";


    my @objs = get_publications_core_from_array($self, \@array);
    $self->stash(objs => \@objs, msg => $msg);

    $self->render(template => 'publications/all');  
}
####################################################################################
sub all_without_author {
	say "CALL: all_without_author "; 
 say "all_without_author ";
    my $self = shift;
    my $dbh = $self->app->db;

    $self->write_log("Displaying papers without any author");

    my $qry = "SELECT DISTINCT id, bibtex_key FROM Entry WHERE id NOT IN (SELECT DISTINCT entry_id FROM Entry_to_Author)";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute(); 

    my @array;
    while(my $row = $sth->fetchrow_hashref()) {
        my $eid = $row->{id};
        push @array, $eid;
    }

    my $msg = "This list contains papers, that are currently not assigned to any of authors. 
            This doesn't mean that they don't have authors. 
            Maybe some authors of the papers need to have their user ids corrected? 
            Even if this list is empty, some author might need have their user ids adjusted!";


    my @objs = get_publications_core_from_array($self, \@array);
    $self->stash(objs => \@objs, msg => $msg);
    $self->render(template => 'publications/all');  
}

####################################################################################
sub show_unrelated_to_team{
	say "CALL: show_unrelated_to_team"; 
    my $self = shift;
    my $team_id = $self->param('teamid');

    $self->write_log("Displaying entries unrealted to team with it $team_id");
    
    my $dbh = $self->app->db;
    my $back_url = $self->param('back_url') || '/types';


    my $set_all_papers = get_set_of_all_papers($self);
    my $set_of_related_to_team = get_set_of_papers_for_all_authors_of_team_id($self, $team_id);    
    my $end_set = $set_all_papers - $set_of_related_to_team;


    my @objs = get_publications_core_from_set($self, $end_set);

    my $msg = "This list contains papers, that are: 
        <ul>
            <li>Not assigned to the team ".get_team_for_id($dbh,$team_id)."</li>
            <li>Not assigned to any author (former or actual) of the team ".get_team_for_id($dbh,$team_id)."</li>
        </ul>";

    $self->stash(objs => \@objs, msg => $msg);
    $self->render(template => 'publications/all'); 
}
####################################################################################
sub all_without_missing_month{
    my $self = shift;
    my $back_url = $self->param('back_url');
    $back_url = '/publications' if $back_url eq $self->req->url->to_abs or $back_url eq '';
    $self->write_log("Displaying entries without month");
    
    my @objs = ();
    my @all_objs = EntryObj->getAll($self->app->db);
    for my $o (@all_objs){
        if($o->{month} < 1 or $o->{month} > 12){
            push @objs, $o;
        }
    }

    my $msg = "<p>This list contains entries with missing BibTeX field 'month'. Add this data to get the proper chronological sorting.</p> ";

    $self->stash(objs => \@objs, msg => $msg);
    $self->render(template => 'publications/all'); 
}
####################################################################################
sub all_candidates_to_delete{
	say "CALL: all_candidates_to_delete";
    my $self = shift;

    $self->write_log("Displaying entries that are candidates_to_delete");

    my $set_all_papers = get_set_of_all_papers($self);
    my $end_set = $set_all_papers;

    # print "A1 ", $end_set, "\n";

    my $set_of_all_teams = get_set_of_all_teams($self);

    foreach my $teamid($set_of_all_teams->members){
        my $set_of_papers_related_to_team = get_set_of_papers_for_all_authors_of_team_id($self, $teamid);
        $end_set = $end_set - $set_of_papers_related_to_team;
    }

    # print "A2 ", $end_set, "\n";

    $end_set = $end_set - get_set_of_papers_with_exceptions($self);
    # print "A3 ", $end_set, "\n";
    $end_set = $end_set - get_set_of_tagged_papers($self);
    # print "A4 ", $end_set, "\n";

    my @objs = get_publications_core_from_set($self, $end_set);

    my $msg = "<p>This list contains papers, that are:</p> 
        <ul>
            <li>Not assigned to any team AND</li>
            <li>have exactly 0 tags AND</li>
            <li>not assigned to any author that is (or was) a member of any team AND </li>
            <li>have exactly 0 exceptions assigned.</li>
        </ul>

        <p>Such entries may wanted to be removed form the system or serve as a help with configuration.</p>";


    $self->stash(objs => \@objs, msg => $msg);
    $self->render(template => 'publications/all'); 
}
####################################################################################

### THIS IS ONLY TEST FUNCTION TO TEST functionalities provided by sets
sub all_defined_by_set {
	say "CALL: all_defined_by_set ";
    my $self = shift;

    my $set_of_entry_ids = get_set_of_papers_for_all_authors_of_team_id($self, 1);
    $set_of_entry_ids = $set_of_entry_ids - get_set_of_papers_for_team($self, 1);

    #test
    my $all_papers = get_set_of_all_papers($self);
    my $not_relevant_papers = $all_papers - get_set_of_papers_for_all_authors_of_team_id($self, 1);

    $set_of_entry_ids = $not_relevant_papers;

    ### TODO!!! 
    # not_relev = not_relev - tagged
    # not_relev = not_relev - exceptions

    my @objs = get_publications_core_from_set($self, $set_of_entry_ids);




    $self->stash(objs => \@objs);
    $self->render(template => 'publications/all');  
}
####################################################################################

sub all_bibtex {
	say "CALL: all_bibtex ";
	my $self = shift;

	# my ($arr_html, $arr_key, $arr_id, $arr_bib) = get_publications_filter($self);

    # my @objs = get_publications_main($self);
    my @objs = get_publications_main_hashed_args($self, {hidden => 0});

	my $big_str = "<pre>\n";
	foreach my $obj (@objs){
		$big_str .= $obj->{bib};
		$big_str .= "\n";
	}
	$big_str .= "\n</pre>";
	$self->render(text => $big_str);  
	
}
####################################################################################
sub all {
	say "CALL: all ";
    # function called from admin interface
	my $self = shift;


	if ($self->session('user')){
        my @objs = get_publications_main_hashed_args($self, {});
        $self->stash(objs => \@objs);
		$self->render(template => 'publications/all');  
	}
	else{
        return $self->all_read();
	}
}

####################################################################################

sub all_read {
	say "CALL: all_read ";
    my $self = shift;

    # my @objs = get_publications_main($self);

    my @objs = get_publications_main_hashed_args($self, {hidden => 0});
    $self->stash(objs => \@objs);

    $self->render(template => 'publications/all_read');
 }

####################################################################################

sub single {
	say "CALL: single ";
    my $self = shift;
    my $id = $self->param('id');

    my @objs = get_single_publication($self, $id, undef); # undef - hidden=undef - for admin interface
    $self->stash(objs => \@objs);
    $self->render(template => 'publications/all');  
    
 }

####################################################################################

sub single_read {
    say "CALL: single_read ";
    my $self = shift;
    my $id = $self->param('id');

    my @objs = get_single_publication($self, $id, 0); # 0 - hidden=0
    $self->stash(objs => \@objs);
    $self->render(template => 'publications/all_read');
    
 }

############################################################################################################

sub landing_years_obj{
	say "CALL: landing_years_obj";
    my $self = shift;
    my $year = $self->param('year') || undef;
    
    # if you want to list talks+papers by default on the landing_years page, use the following line
    # my $entry_type = $self->param('entry_type') || undef;

    # if you want to list ONLY papers by default on the landing_years page, use the following line
    my $entry_type = $self->param('entry_type') || 'paper';


    my $min_year = $self->get_year_of_oldest_entry || 0;
    my $max_year = $self->current_year;
    if($self->current_month > 8){
        $max_year++;
    }

    if(defined $year){
        $min_year = $year;
        $max_year = $year;
    }

    my %hash_dict;
    my %hash_values;
    my @allkeys = ($min_year..$max_year);
    @allkeys = reverse @allkeys;

    my @objs_arr;
    my @keys;


    foreach my $yr (@allkeys) {
        
        # my @objs = get_publications_main($self, undef, $yr, undef, $entry_type, undef, undef, 0, undef);
        my @objs = get_publications_main_hashed_args($self, {year => $yr, 
                                                                entry_type => $entry_type, 
                                                                visible => 0,
                                                                hidden => 0});
        # delete the year from the @keys array if the year has 0 papers
        if(scalar @objs > 0){
            $hash_dict{$yr} = $yr;
            $hash_values{$yr} = \@objs;
            push @keys, $yr;
        }
    }

    

    # WARNING, it depends on routing! anti-pattern! Correct it some day
    # todo: this code is duplicated! fix it!

    my $url = "/l/p?".$self->req->url->query;
    my $url_msg = "Switch to grouping by types";
    my $switchlink = '<a class="bibtexitem" href="'.$url.'">'.$url_msg.'</a>';

    # NAVBAR
    my $tmp_year = $self->req->url->query->param('year');
    $self->req->url->query->remove('year');
    my $navbar_html = '<a class="bibtexitem" href="'.$self->req->url->path.'?'.$self->req->url->query.'">[show ALL years]</a> ';
    $self->req->url->query->param(year => $tmp_year) if defined $tmp_year and $tmp_year ne "";

    my $tmp_type = $self->req->url->query->param('bibtex_type');
    $self->req->url->query->remove('bibtex_type');
    $navbar_html .= '<a class="bibtexitem" href="'.$self->req->url->path.'?'.$self->req->url->query.'">[show ALL types]</a> ';
    $navbar_html .= '<br/>';
    $self->req->url->query->param(bibtex_type => $tmp_type) if defined $tmp_type and $tmp_type ne "";

    foreach my $key (reverse sort @keys) {

        $self->req->url->query->param(year => $key);
        $navbar_html .= '<a class="bibtexitem" href="'.$self->req->url->path.'?'.$self->req->url->query.'">';
        $navbar_html .= '['.$hash_dict{$key}.']';
        $navbar_html .= '</a> ';
    }

    return $self->display_landing(\%hash_values, \%hash_dict, \@keys, $switchlink, $navbar_html);
}



############################################################################################################
sub landing_types_obj{
	say "CALL: landing_types_obj";
    my $self = shift;
    my $bibtex_type = $self->param('bibtex_type') || undef;
    my $entry_type = $self->param('entry_type') || undef;

    # say "bibtex_type $bibtex_type";
    # say "entry_type $entry_type";

    my %hash_dict;      # key: bibtex_type (SELECT DISTINCT our_type FROM OurType_to_Type WHERE landing=1 ORDER BY our_type ASC)
                        # value: description of type
    my %hash_values;    # key: bibtex_type
                        # value: ref to array of entry objects

    my @keys;
    my @all_keys = get_types_for_landing_page($self->app->db);

    my @keys_with_papers;

    # shitty ifs

    # include talks only when
    # 1 - entry_type eq talk
    # 2 - both types undefined

    # include only one bibtex type when
    # 1 - bibtex_type defined and entry_type ne talk
    
    # include all bibtex types but no talks
    #

    # include everything
    # 1 - nothing defined

    # only one bibtex type
    if(defined $bibtex_type and (!defined $entry_type or $entry_type eq 'paper')){
        # no talks
        # single bibtex type
        say "OPTION 1 - only one type";
        my $key = $bibtex_type;


        # $args->{author}
        # $args->{year}
        # $args->{bibtex_type}
        # $args->{entry_type}
        # $args->{tag}
        # $args->{team}
        # $args->{visible}
        # $args->{permalink}
        # $args->{hidden}

        # my @paper_objs = get_publications_main($self, undef, undef, $bibtex_type, $entry_type, undef, undef, 0, undef);        
        my @paper_objs = get_publications_main_hashed_args($self, {bibtex_type => $bibtex_type, 
                                                                    entry_type => $entry_type, 
                                                                    visible => 0,
                                                                    hidden => 0});
        if(scalar @paper_objs > 0){
            $hash_dict{$key} = get_type_description($self->app->db, $key);
            $hash_values{$key} = \@paper_objs;
            push @keys_with_papers, $key;
        }
    }
    # only talks
    elsif(defined $entry_type and $entry_type eq 'talk'){
        
        say "OPTION 2 - talks only";
        my $key = 'talk';

        # my @talk_objs = get_publications_main($self, undef, undef, undef, 'talk', undef, undef, 0, undef);
        my @talk_objs = get_publications_main_hashed_args($self, { entry_type => 'talk', 
                                                                    visible => 0,
                                                                    hidden => 0});
        if(scalar @talk_objs > 0){
            $hash_dict{$key} = "Talks";
            $hash_values{$key} = \@talk_objs;
            push @keys_with_papers, $key;
        }
    }
    # all but talks
    elsif(!defined $bibtex_type and defined $entry_type and $entry_type eq 'paper'){
        
        say "OPTION 3 - all but talks";
        @keys = @all_keys;

        foreach my $key (@keys){
            # my @paper_objs = get_publications_main($self, undef, undef, $key, 'paper', undef, undef, 0, undef);        
            my @paper_objs = get_publications_main_hashed_args($self, {bibtex_type => $key, 
                                                                    entry_type => 'paper', 
                                                                    visible => 0,
                                                                    hidden => 0});
            if(scalar @paper_objs > 0){
                $hash_dict{$key} = get_type_description($self->app->db, $key);
                $hash_values{$key} = \@paper_objs;
                push @keys_with_papers, $key;
            }
        }
    }
    # all
    elsif(!defined $entry_type and !defined $bibtex_type){

        say "OPTION 4 - all";
        @keys = @all_keys;

        foreach my $key (@keys){
            # my @paper_objs = get_publications_main($self, undef, undef, $key, 'paper', undef, undef, 0, undef); 
            my @paper_objs = get_publications_main_hashed_args($self, {bibtex_type => $key, 
                                                                    entry_type => 'paper', 
                                                                    visible => 0,
                                                                    hidden => 0});
            if(scalar @paper_objs > 0){
                $hash_dict{$key} = get_type_description($self->app->db, $key);
                $hash_values{$key} = \@paper_objs;
                push @keys_with_papers, $key;
            }
        }
        my $key = 'talk';

        # my @talk_objs = get_publications_main($self, undef, undef, undef, 'talk', undef, undef, 0, undef);
        my @talk_objs = get_publications_main_hashed_args($self, { entry_type => 'talk', 
                                                                    visible => 0,
                                                                    hidden => 0});
        if(scalar @talk_objs > 0){
            $hash_dict{$key} = "Talks";
            $hash_values{$key} = \@talk_objs;
            push @keys_with_papers, $key;
        }
    }
    else{
        say "OPTION 5 - else";
    }

    

    # WARNING, it depends on routing! anti-pattern! Correct it some day
    my $url = "/ly/p?".$self->req->url->query;
    my $url_msg = "Switch to grouping by years";
    my $switchlink = '<a class="bibtexitem" href="'.$url.'">'.$url_msg.'</a>';

    # NAVBAR
    
    my $tmp_year = $self->req->url->query->param('year');
    $self->req->url->query->remove('year');
    my $navbar_html = '<a class="bibtexitem" href="'.$self->req->url->path.'?'.$self->req->url->query.'">[show ALL years]</a> ';
    $self->req->url->query->param(year => $tmp_year) if defined $tmp_year and $tmp_year ne "";

    $self->req->url->query->remove('bibtex_type');
    $self->req->url->query->remove('entry_type');
    $navbar_html .= '<a class="bibtexitem" href="'.$self->req->url->path.'?'.$self->req->url->query.'">[show ALL types]</a> ';
    $navbar_html .= '<br/>';

    foreach my $key (sort @keys_with_papers) {
        # say "key in keys_with_papers: $key";
        
        if($key eq 'talk'){
            $self->req->url->query->remove('bibtex_type');
            $self->req->url->query->param(entry_type => 'talk');
            $navbar_html .= '<a class="bibtexitem" href="'.$self->req->url->path.'?'.$self->req->url->query.'">';
        }
        else{
            $self->req->url->query->remove('entry_type');
            $self->req->url->query->param(bibtex_type => $key);
            $navbar_html .= '<a class="bibtexitem" href="'.$self->req->url->path.'?'.$self->req->url->query.'">';
        }
        $navbar_html .= '['.$hash_dict{$key}.']';
        $navbar_html .= '</a> ';
    }

    # say $navbar_html;

    # hash_values:  key_bibtex_type -> ref_arr_entry_objects
    # hash_dict:    key_bibtex_type -> description of the type
    # keys_with_papers: non-empty -> key_bibtex_type
    return $self->display_landing(\%hash_values, \%hash_dict, \@keys_with_papers, $switchlink, $navbar_html);
}

############################################################################################################
sub display_landing{
    say "CALL: display_landing";
    my $self = shift;
    my $hash_values_ref = shift;
    my $hash_dict_ref = shift;
    my $keys_ref = shift;
    my $switchlink = shift || "";
    my $navbar_html = shift || "";

    my $navbar = $self->param('navbar') || 0;
    my $show_title = $self->param('title') || 0;
    my $show_switch = $self->param('switchlink');

    # if you ommit the switchlink param, assume default = enabled
    # by 0, do not show
    # by 1, do show
    $show_switch = 1 unless defined $show_switch;
    # reset switchlink if show_switch different to 1
    $switchlink = "" unless $show_switch == 1;

    $navbar_html = "" unless $navbar == 1;


    my $permalink = $self->param('permalink');
    my $tag_name = $self->param('tag') || "";
    my $tag_name_for_permalink = TagObj->get_tag_name_for_permalink($self->app->db, $permalink);
    $tag_name = $tag_name_for_permalink unless $tag_name_for_permalink eq -1;
    $tag_name = $permalink if !defined $self->param('tag') and $tag_name_for_permalink eq -1;
    $tag_name =~ s/_+/_/g if defined $tag_name and defined $show_title and $show_title == 1;
    $tag_name =~ s/_/\ /g if defined $tag_name and defined $show_title and $show_title == 1;


    my $title = "";
    $title .= " Publications " if defined $self->param('entry_type') and $self->param('entry_type') eq 'paper';
    $title .= " Talks " if defined $self->param('entry_type') and $self->param('entry_type') eq 'talk';
    $title .= " Publications and talks" if !defined $self->param('entry_type');
    $title .= " of team ".$self->param('team') if defined $self->param('team');
    $title .= " of author ".$self->param('author') if defined $self->param('author');
    $title .= " tagged as ".$tag_name if defined $self->param('tag');
    $title .= " in category ".$tag_name if defined $self->param('permalink');
    $title .= " of type ".$self->param('bibtex_type') if defined $self->param('bibtex_type');
    $title .= " published in year ".$self->param('year') if defined $self->param('year');

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
    $self->stash(hash_values =>$hash_values_ref, hash_dict => $hash_dict_ref, keys => $keys_ref, 
                 navbar => $navbar_html, show_title => $show_title, title => $title, switch_link => $switchlink);
    $self->render(template => 'publications/landing_obj');
}


####################################################################################

sub add_pdf {
	say "CALL: add_pdf ";
    my $self = shift;
    my $id = $self->param('id');
    my $back_url = $self->param('back_url') || '/publications';
    # my $msg = $self->param('message') || '';
    my $dbh = $self->app->db;
    $back_url = '/publications' if $back_url eq $self->req->url->to_abs;

    $self->write_log("Page: add pdf for paper id $id");

    # getting html preview
    my $sth = $dbh->prepare( "SELECT DISTINCT bibtex_key, html, bibtex_type FROM Entry WHERE id = ?" );  
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref();
    my $html_preview = $row->{html} || nohtml($row->{bibtex_key}, $row->{bibtex_type});
    my $key = $row->{bibtex_key};


    $self->stash(id => $id, preview => $html_preview, back_url => $back_url);
    $self->render(template => 'publications/pdf_upload');
};
####################################################################################
sub add_pdf_post{
	say "CALL: add_pdf_post";
    my $self = shift;
    my $id = $self->param('id') || "unknown";
    my $back_url = $self->param('back_url') || '/publications';
    my $filetype = $self->param('filetype') || undef;

    my $extension;

    $self->write_log("Saving attachment for paper id $id");


    # Check file size
    if ($self->req->is_limit_exceeded){
        $self->write_log("Saving attachment for paper id $id: limit exceeded!");
        $self->flash(back_url => $back_url, message => "The File is too big and cannot be saved!", msg_type => "danger");
        $self->redirect_to($back_url);
        return;
    }

    

    # Process uploaded file
    my $uploaded_file = $self->param('uploaded_file');

    unless ($uploaded_file){
      $self->flash(back_url => $back_url, message => "File upload unsuccessfull!", msg_type => "danger");
      $self->write_log("Saving attachment for paper id $id FAILED. Unknown reason");
      $self->redirect_to($back_url);
    }

    my $size = $uploaded_file->size;
    if ($size == 0){
        $self->flash(back_url => $back_url, message => "No file was selected or file has 0 bytes! Not saving!", msg_type => "danger");
        $self->write_log("Saving attachment for paper id $id FAILED. Filesize is 0");
        $self->redirect_to($back_url);   
    }
    else{
        my $sizeKB = int($size / 1024);
        my $name = $uploaded_file->filename;

        my @dot_arr = split(/\./, $name);
        my $arr_size = scalar @dot_arr;
        $extension = $dot_arr[$arr_size-1];

        my $fname;
        my $fname_no_ext;
        my $file_path;
        my $bibtex_field;
        my $directory;


        if($filetype eq 'paper'){
            $fname_no_ext = "paper-".$id.".";
            $fname = $fname_no_ext.$extension;
          
            $directory = "uploads/papers/";
            $bibtex_field = "pdf";
        }
        elsif($filetype eq 'slides'){
            $fname_no_ext = "slides-paper-".$id.".";
            $fname = $fname_no_ext.$extension;
            $directory = "uploads/slides/";
            $bibtex_field = "slides";
        }
        else{
            $fname_no_ext = "unknown-".$id.".";
            $fname = $fname_no_ext.$extension;
            $directory = "uploads/unknown/";

            $bibtex_field = "pdf2";
        }
        $file_path = $directory.$fname;

        # rm uploads/papers/paper-651.*
        my $cmd = "rm public/$directory"."$fname_no_ext"."*";
        # say $cmd;
        # system($cmd);


      
        $uploaded_file->move_to("public/".$file_path); ### WORKS!!!

        ### TODO Feb 2015: move $self->req->url->base to a parameter!!
        my $file_url = $self->req->url->base."/pa/".$file_path;

        $self->write_log("Saving attachment for paper id $id under: $file_url");

        add_field_to_bibtex_code($self->app->db, $id, $bibtex_field, $file_url);

        my $msg = "Thanks for uploading $sizeKB KB file <em>$name</em> as <strong><em>$filetype</em></strong>. The file was renamed to: <em>$fname</em>. URL <a href=\"".$file_url."\">$name</a>";

        # my $sth2 = $self->app->db->prepare( "UPDATE Entry SET modified_time=datetime('now', 'localtime') WHERE id =?" );  
        my $sth2 = $self->app->db->prepare( "UPDATE Entry SET modified_time=CURRENT_TIMESTAMP WHERE id =?" );  
        
        $sth2->execute($id);
        $sth2->finish();

        generate_html_for_id($self->app->db, $id);

        $self->flash(back_url => $back_url, message => $msg);
        $self->redirect_to($back_url);
    }
};

####################################################################################
####################################################################################
sub regenerate_html_for_all {
	say "CALL: regenerate_html_for_all ";
  my $self = shift;
  my $back_url = $self->param('back_url');

  my $dbh = $self->app->db;
  $back_url = $self->get_back_url($back_url);

  $self->write_log("regenerate_html_for_all is running");

  $self->helper_regenerate_html_for_all();

  $self->write_log("regenerate_html_for_all has finished");

  $self->redirect_to($back_url);
};
####################################################################################
sub regenerate_html_for_all_force {
	say "CALL: regenerate_html_for_all_force ";
    my $self = shift;
    my $back_url = $self->param('back_url');

    my $dbh = $self->app->db;
    
    $back_url = $self->get_back_url($back_url);

    $self->write_log("regenerate_html_for_all FORCE is running");

    my @ids = get_all_entry_ids($dbh);
    for my $id (@ids){
      generate_html_for_id($dbh, $id);
    }

    $self->write_log("regenerate_html_for_all FORCE has finished");
    $self->redirect_to($back_url);
};
####################################################################################
sub regenerate_html {
	say "CALL: regenerate_html ";
    my $self = shift;
    my $id = $self->param('id');
    my $back_url = $self->param('back_url');

    my $dbh = $self->app->db;

$back_url = $self->get_back_url($back_url);

    generate_html_for_id($dbh, $id);
    $self->redirect_to($back_url);
};

####################################################################################

sub delete {
	say "CALL: delete ";
    my $self = shift;
    my $id = $self->param('id');
    my $back_url = $self->param('back_url');

    $self->write_log("Delete entry eid $id. (delete_sure should follow) ");

    my $dbh = $self->app->db;
    my $sth = $dbh->prepare( "SELECT DISTINCT key, html, bibtex_type
      FROM Entry 
      WHERE id = ?" );  
   $sth->execute($id);

   my $row = $sth->fetchrow_hashref();
   my $html_preview = $row->{html} || nohtml($row->{bibtex_key}, $row->{bibtex_type});
   my $bibtex_key = $row->{bibtex_key};
  


  $self->stash(key => $bibtex_key, id => $id, preview => $html_preview, back_url => $back_url);
  $self->render(template => 'publications/sure_delete');
};

####################################################################################

sub delete_sure {
	say "CALL: delete_sure ";
   my $self = shift;
   my $eid = $self->param('id');
   my $back_url = $self->param('back_url');

   if( !defined $back_url or $back_url =~ /get\/$eid/){
      $back_url = "/publications";
   }

   my $dbh = $self->app->db;

   delete_entry_by_id($dbh, $eid);
   $self->write_log("delete_sure entry eid $eid. Entry deleted.");

   $self->redirect_to($back_url);
};
####################################################################################
sub show_authors_of_entry{
	say "CALL: show_authors_of_entry";
    my $self = shift;
    my $eid = $self->param('id');
    my $back_url = $self->param('back_url') || "/publications";
    my $dbh = $self->app->db;

    $self->write_log("Showing authors of entry eid $eid");

    my @authors = $self->get_authors_of_entry($eid);

    my $teams_for_paper = get_set_of_teams_for_entry_id($self,$eid);
    my @teams = $teams_for_paper->members;


    my $html_preview = get_html_for_entry_id($dbh, $eid);
    my $key = get_entry_key($dbh, $eid);


    $self->stash(eid => $eid, key => $key, back_url => $back_url, preview => $html_preview, 
        author_ids => \@authors, team_ids => \@teams);
    $self->render(template => 'publications/show_authors');
}
####################################################################################
sub manage_exceptions{
	say "CALL: manage_exceptions";
    my $self = shift;
    my $eid = $self->param('id');
    my $back_url = $self->param('back_url') || "/publications";
    my $dbh = $self->app->db;

    $self->write_log("Manage exceptions of entry eid $eid");

    my @authors = $self->get_authors_of_entry($eid);

    my $teams_for_paper = get_set_of_teams_for_entry_id($self,$eid);

    my @teams = $teams_for_paper->members;
    my @unassigned_teams = (get_set_of_all_teams($self) - $teams_for_paper)->members;

    my $html_preview = get_html_for_entry_id($dbh, $eid);
    my $key = get_entry_key($dbh, $eid);

    my @exceptions = get_exceptions_for_entry_id($dbh, $eid);
   
    $self->stash(eid => $eid, key => $key, back_url => $back_url, preview => $html_preview, 
        author_ids => \@authors, exceptions => \@exceptions, team_ids => \@teams, unassigned_teams => \@unassigned_teams);
    $self->render(template => 'publications/manage_exceptions');
}
####################################################################################
sub manage_tags{
	say "CALL: manage_tags";
    my $self = shift;
    my $eid = $self->param('id');
    my $back_url = $self->param('back_url') || "/publications";
    my $dbh = $self->app->db;

    $self->write_log("Manage tags of entry eid $eid");

    my ($all_tags_arrref, $all_ids_arrref, $all_parents_arrref) = get_all_tags($dbh);
    my ($tags_arrref, $ids_arrref, $parents_arrref) = get_tags_for_entry($dbh, $eid);

    # my @unassigned_tags_ids = get_ids_arr_of_unassigned_tags($self, $eid);  #problem with sorting!

    my @unassigned_tags_ids;

    for my $t (@$all_ids_arrref){
        if (!grep( /^$t$/, @$ids_arrref)){
            push @unassigned_tags_ids, $t;
        }
    }

  my $html_preview = get_html_for_entry_id($dbh, $eid);
  my $key = get_entry_key($dbh, $eid);

    
  $self->stash(eid => $eid, key => $key, back_url => $back_url, preview => $html_preview, 
        tags  => $tags_arrref, ids => $ids_arrref, parents => $parents_arrref, 
        all_tags  => $all_tags_arrref, unassigned_tag_ids => \@unassigned_tags_ids, 
        all_ids => $all_ids_arrref, all_parents => $all_parents_arrref);
  $self->render(template => 'publications/manage_tags');
}
####################################################################################

sub remove_tag{
	say "CALL: remove_tag";
  my $self = shift;
  my $eid = $self->param('eid');
  my $tid = $self->param('tid');
  my $back_url = $self->param('back_url') || "/publications";
  my $dbh = $self->app->db;

  $self->write_log("Removing tag id $tid from entry eid $eid");

  my $sth = $dbh->prepare( "DELETE FROM Entry_to_Tag WHERE entry_id=? AND tag_id=?");
  $sth->execute($eid, $tid);


  $self->redirect_to($back_url);

}
####################################################################################

sub add_tag{
    say "CALL: add_tag";
    my $self = shift;
    my $eid = $self->param('eid');
    my $tid = $self->param('tid');
    my $back_url = $self->param('back_url') || "/publications";
    my $dbh = $self->app->db;

    $self->write_log("Adding tag id $tid to entry eid $eid");

    my $sth = $dbh->prepare( "INSERT INTO Entry_to_Tag(entry_id, tag_id) VALUES (?,?)");
    $sth->execute($eid, $tid);
    $self->redirect_to($back_url);

}
####################################################################################

sub add_exception{
	say "CALL: add_exception";
    my $self = shift;
    my $eid = $self->param('eid');
    my $tid = $self->param('tid');
    my $back_url = $self->param('back_url') || "/publications";
    my $dbh = $self->app->db;

    $self->write_log("Adding exception id $tid to entry eid $eid");

    my $sth = $dbh->prepare( "INSERT INTO Exceptions_Entry_to_Team(entry_id, team_id) VALUES (?,?)");
    $sth->execute($eid, $tid);

    $self->redirect_to($back_url);

}
####################################################################################

sub remove_exception{
	say "CALL: remove_exception";
    my $self = shift;
    my $eid = $self->param('eid');
    my $tid = $self->param('tid');
    my $back_url = $self->param('back_url') || "/publications";
    my $dbh = $self->app->db;

    $self->write_log("Removing exception id $tid to entry eid $eid");

    my $sth = $dbh->prepare( "DELETE FROM Exceptions_Entry_to_Team WHERE entry_id=? AND team_id=?");
    $sth->execute($eid, $tid);

    $self->redirect_to($back_url);

}


####################################################################################
################################################################ ADDING ############
####################################################################################

## ADD form
sub get_add {
    say "CALL: get_add ";
    my $self = shift;
    my %mons = (1=>'January',2=>'February',3=>'March',4=>'April',5=>'May',6=>'June',7=>'July',8=>'August',9 =>'September',10=>'October',11=>'November',12=>'December');

   
   
my $bib = '@article{key'.get_current_year().',
    author = {Johny Example},
    title = {{Selected aspects of some methods}},
    year = {'.get_current_year().'},
    month = {'.$mons{get_current_month()}.'},
    day = {1--31},
}';

   

   $self->stash(bib  => $bib, key => '', existing_id => '', exit_code => '', msg => '', preview => '');
   $self->render(template => 'publications/add_entry');
};
############################################################################################################

## Called after every preview or store command issued by EDIT or ADD form
sub post_add_store {
	say "CALL: post_add_store ";
  my $self = shift;
  my $id = $self->param('id') || undef;
  my $new_bib = $self->param('new_bib');
  my $preview_param = $self->param('preview') || undef;
  # my $check_key =  || undef;
  my $preview = 0;

  $self->write_log("Post_add_store add publication with bib $new_bib");


  if(defined $id){
      $self->redirect_to('/publications/edit/'.$id);
      return;
  }

  my $dbh = $self->app->db;
  my $html_preview = "";
  my $code = -2;
  my $key = -1;
  $key = get_key_from_bibtex_code($new_bib) if defined $new_bib;

  $new_bib =~ s/^\s+|\s+$//g;
  $new_bib =~ s/^\t//g;

  my $exisitng_id = get_entry_id($dbh, $key);

  # say "key $key";
  # say "exisitng_id $exisitng_id";
  my $param_prev = $self->param('preview') || "";
  my $param_save = $self->param('save') || "";

  # say "preview $param_prev";
  # say "save $param_save";

  if(defined $key and $key =~ /^[+-]?\d+$/ and $key == -1){   # generate bibtex errors

      $code = -1;

      $self->stash(bib  => $new_bib, key => $key, existing_id => '', msg => '', exit_code => $code, preview => $html_preview);
      $self->render(template => 'publications/add_entry');
      return;
  }

  if(defined $self->param('preview')){

      my ($html, $htmlbib) = get_html_for_bib($new_bib, $key);
      $html_preview = $html;

      if($exisitng_id > 0 ){
          $code = 3; # generate key-exists msg
      }

      $self->stash(bib  => $new_bib, key => $key, existing_id => $exisitng_id, msg => '', exit_code => $code, preview => $html_preview);
      $self->render(template => 'publications/add_entry');
      return;
  }
  if(defined $self->param('save')){

      if($exisitng_id == -1){
          ($code, $html_preview) = postprocess_edited_entry($dbh, $new_bib, 0);
          $id = get_entry_id($dbh, $key);  
          $self->redirect_to('/publications/edit/'.$id);
          return;
      }
  }

  $code = 3;  # beause once the kay is bad, it is bad as long as $exisitng_id is -1

  if(defined $self->param('check_key')){
      if($exisitng_id == -1){
          $code = 2;
      }
      elsif($exisitng_id > 0){
          $code = 3;
      }
  }

  
  $self->stash(bib  => $new_bib, existing_id => $exisitng_id, key => $key, msg => '', exit_code => $code, preview => $html_preview);
  $self->render(template => 'publications/add_entry');

};

####################################################################################
################################################################ EDITING ###########
####################################################################################


## EDIT form
sub get_edit {
	say "CALL: get_edit ";
   my $self = shift;
   my $id = $self->param('id');
   my $back_url = $self->param('back_url') || "/publications";
   
   $self->write_log("Editing publication entry id $id");
   
   my $dbh = $self->app->db;



   # my $sth = $dbh->prepare( "SELECT DISTINCT bibtex_key, bib 
   #    FROM Entry 
   #    WHERE id = ?" );  
   # $sth->execute($id);

   # my $row = $sth->fetchrow_hashref();

   # # say "entry id $id has key $key";

   # $sth->finish;

   my $obj = EntryObj->new({id => $id});
   $obj->initFromDB($dbh);
   my $bib = $obj->{bib};
   my $key = $obj->{bibtex_key};


   $self->stash(bib  => $bib, entry_obj => $obj, id => $id, key => $key, existing_id => '', exit_code => '', msg => '', preview => '', back_url => $back_url);
   $self->render(template => 'publications/edit_entry');
};
############################################################################################################

## Called after every preview or store command issued by EDIT or ADD form
sub post_edit_store {
	say "CALL: post_edit_store ";
  my $self = shift;
  my $id = $self->param('id') || undef;
  my $new_bib = $self->param('new_bib');
  my $preview_param = $self->param('preview') || undef;
  # my $check_key =  || undef;
  my $preview = 0;

  $self->write_log("Post_edit_store: editing publication entry id $id");


  my $dbh = $self->app->db;
  my $html_preview = "";
  my $code = -2;
  my $key = -1;
  $key = get_key_from_bibtex_code($new_bib) if defined $new_bib;

  $new_bib =~ s/^\s+|\s+$//g;
  $new_bib =~ s/^\t//g;

  my $param_prev = $self->param('preview') || "";
  my $param_save = $self->param('save') || "";

  my $obj = EntryObj->new({id => $id});
  $obj->initFromDB($dbh) if defined $id;
  $obj->{bib} = $new_bib;
  $obj->{key} = $key;

  # say "preview $param_prev";
  # say "save $param_save";

  if(defined $key and $key =~ /^[+-]?\d+$/ and $key == -1){   # generate bibtex errors
    
      $code = -1;

      $self->stash(bib  => $new_bib, entry_obj => $obj, key => $key, existing_id => '', msg => '', exit_code => $code, preview => $html_preview);
      $self->render(template => 'publications/edit_entry');
      return;
  }

  my $exisitng_id = get_entry_id($dbh, $key);

  if($exisitng_id > 0 and $exisitng_id ne $id){   # there is another entry with this key

      $code = 3; # generate key-exists msg
      
      $self->stash(bib  => $new_bib, entry_obj => $obj, key => $key, existing_id => $exisitng_id, msg => '', exit_code => $code, preview => $html_preview);
      $self->render(template => 'publications/edit_entry');
      return;
  }

  if(defined $self->param('preview')){

      my ($html, $htmlbib) = get_html_for_bib($new_bib, $key);
      $obj->{html} = $html;
      $html_preview = $html;
      $self->stash(bib  => $new_bib, entry_obj => $obj, key => $key, existing_id => '', msg => '', exit_code => $code, preview => $html_preview);
      $self->render(template => 'publications/edit_entry');
      return;
  }
  if(defined $self->param('save')){


      ($code, $html_preview) = postprocess_updated_entry($dbh, $new_bib, $id);
      $id = get_entry_id($dbh, $key);  
      $obj->{html} = $html_preview;
      $obj->{id} = $id;
      $self->stash(bib  => $new_bib, entry_obj => $obj, key => $key, existing_id => '', msg => '', exit_code => $code, preview => $html_preview);
      $self->render(template => 'publications/edit_entry');
      return;
  }

};







############################################################################################################


##########################################
sub get_key_from_bibtex_code{
	say "CALL: get_key_from_bibtex_code";
  my $code = shift;
  my $entry = new Text::BibTeX::Entry();
  $entry->parse_s($code);
  return -1 unless $entry->parse_ok;
  return $entry->key;
}
##########################################

sub after_edit_check_entry{
	say "CALL: after_edit_check_entry";
   my $dbh = shift;
   my $entry_str = shift;

   my $entry = new Text::BibTeX::Entry();
   $entry->parse_s($entry_str);

   # $self->write_log("Running after_edit_check_entry for bib: $entry_str");

   return -1 unless $entry->parse_ok;

   my $exit_code = -2;
   # 0 adding ok
   # -1 parse error
   # 1 updating ok

   ######### AUTHORS

   my $key = $entry->key;
     
   my $year = $entry->get('year');
   my $title = $entry->get('title') || '';
   my $abstract = $entry->get('abstract') || undef;
   my $content = $entry->print_s;
   my $type = $entry->type;

   my @ary = $dbh->selectrow_array("SELECT COUNT(*) FROM Entries WHERE bibtex_key = ?", undef, $entry->key);  
   my $key_exists = $ary[0];

    if($key_exists==0){
        $exit_code = 0;
    }
    else{
         $exit_code = 1;
    }

   return $exit_code;
};

##################################################################
sub postprocess_updated_entry{
	say "CALL: postprocess_updated_entry";  # procesing an entry that was edited - allows to change bibtex key - eid remains untouched
    ### TODO: cannot use log because there is no $self-object!
    my $dbh = shift;
    my $entry_str = shift;
    my $eid = shift; # remains unchanged

    my $preview_html = "";

    # $self->write_log("Postprocessing updated entry with id $eid");

    my $entry = new Text::BibTeX::Entry();
    $entry->parse_s($entry_str);

    return -1 unless $entry->parse_ok;

    my $exit_code = -2;
    # -1 parse error
    # 1 updating ok

    ######### AUTHORS

    my $key = $entry->key;


    my $year = $entry->get('year');
    my $title = $entry->get('title') || '';
    my $abstract = $entry->get('abstract') || undef;
    my $content = $entry->print_s;
    my $type = $entry->type;

    my $sth2 = $dbh->prepare( "UPDATE Entry SET title=?, bibtex_key=?, bib=?, year=?, bibtex_type=?, abstract=?, need_html_regen = 1, modified_time=CURRENT_TIMESTAMP WHERE id =?" );  
    $sth2->execute($title, $key, $content, $year, $type, $abstract, $eid);
    $sth2->finish();
    $exit_code = 1;
    after_edit_process_authors($dbh, $entry);
    # after_edit_process_tags($dbh, $entry); 
    generate_html_for_key($dbh, $key);
    after_edit_process_month($dbh, $entry);

    my ($html, $htmlbib) = get_html_for_bib($content, $key);
    $preview_html = $html;

    return $exit_code, $preview_html;
};
##################################################################

sub postprocess_edited_entry{
	say "CALL: postprocess_edited_entry";
    ### TODO: cannot use log because there is no $self-object!
    my $dbh = shift;
    my $entry_str = shift;
    my $preview = shift;

    my $preview_html = "";

    # $self->write_log("Postprocessing edited entry with id $eid");

    my $entry = new Text::BibTeX::Entry();
    $entry->parse_s($entry_str);

    return -1 unless $entry->parse_ok;

    my $exit_code = -2;
    # 0 adding ok
    # -1 parse error
    # 1 updating ok

    ######### AUTHORS

    my $key = $entry->key;

    my $eid = get_entry_id($dbh, $key);

    my $year = $entry->get('year');
    my $title = $entry->get('title') || '';
    my $abstract = $entry->get('abstract') || undef;
    my $content = $entry->print_s;
    my $type = $entry->type;

    my @ary = $dbh->selectrow_array("SELECT COUNT(*) FROM Entry WHERE bibtex_key = ?", undef, $entry->key);  
    my $key_exists = $ary[0];

    if(!$preview and $key_exists==0){
        my $sth2 = $dbh->prepare( "INSERT INTO Entry(title, bibtex_key, bib, year, bibtex_type, abstract, creation_time, modified_time) VALUES(?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)" );  
        $sth2->execute($title, $key, $content, $year, $type, $abstract);
        $sth2->finish();
        $exit_code = 0;

    }
    elsif(!$preview){ 
         my $sth2 = $dbh->prepare( "UPDATE Entry SET title=?, bibtex_key=?, bib=?, year=?, bibtex_type=?, abstract=?, modified_time=CURRENT_TIMESTAMP WHERE id =?" );  
         $sth2->execute($title, $key, $content, $year, $type, $abstract, $eid);
         $sth2->finish();
         $exit_code = 1;
    }

    if(!$preview){
        after_edit_process_authors($dbh, $entry);
        after_edit_process_tags($dbh, $entry); 
        generate_html_for_key($dbh, $key);
        after_edit_process_month($dbh, $entry);

        # $exit_code = "Your entry has been added, but please note: TODO: adjust those methods: after_edit_process_authors and after_edit_process_tags!";
    }
    else{
      my ($html, $htmlbib) = get_html_for_bib($content, $key);
      $preview_html = $html;
    }

  

   return $exit_code, $preview_html;
};






##########################################################################################

sub after_edit_process_month{

    my $dbh = shift;
    my $entry = shift;

    my $entry_key = $entry->key;
    my $key = $entry_key;
    my $eid = get_entry_id($dbh, $entry_key);


    if($entry->exists('month')){
        my $month_str = $entry->get('month');
        my $month_numeric = get_month_numeric($month_str);

        
        my $obj = EntryObj->new({id => $eid});
        $obj->initFromDB($dbh);
        $obj->setMonth($month_numeric, $dbh);
        $obj->setSortMonth($month_numeric, $dbh);
    }
};

##########################################################################################

sub after_edit_process_tags{
	say "CALL: after_edit_process_tags";
    ### TODO: cannot use log because there is no $self-object!
  my $dbh = shift;
  my $entry = shift;

  my $entry_key = $entry->key;
  my $key = $entry_key;
  my $eid = get_entry_id($dbh, $entry_key);

  # $self->write_log("Postprocessing TAGS of updated entry with id $eid");
  

  # this would delete all tags by editing an entry!!
  
  # my $sth = $dbh->prepare('DELETE FROM Entry_to_Tag WHERE entry_id = ?');
  # $sth->execute($eid);
   
   

  if($entry->exists('tags')){
      my $tags_str = $entry->get('tags');
      $tags_str =~ s/\,/;/g if defined $tags_str;
      $tags_str =~ s/^\s+|\s+$//g if defined $tags_str;

      
      my @tags = split(';', $tags_str) if defined $tags_str;

      for my $tag (@tags){
         $tag =~ s/^\s+|\s+$//g;
         $tag =~ s/\ /_/g if defined $tag;

         

         # $dbh->do("REPLACE INTO Tags VALUES($tag)");
         my $sth3 = $dbh->prepare( "INSERT IGNORE INTO Tag(name) VALUES(?)" );  
         $sth3->execute($tag);
         my $tagid2 = get_tag_id($dbh, $tag);

         # $dbh->do("INSERT INTO Entry_to_Tag(entry, tag) VALUES($entry_key, $tag)");
         $sth3 = $dbh->prepare( "INSERT IGNORE INTO Entry_to_Tag(entry_id, tag_id) VALUES(?, ?)" );  
         $sth3->execute($eid, $tagid2);
      }

  }
}


####################################################################################
sub clean_ugly_bibtex {
	say "CALL: clean_ugly_bibtex ";
    my $self = shift;
    my $back_url = $self->param('back_url');
    my $dbh = $self->app->db;
    $back_url = $self->get_back_url($back_url);

    $self->write_log("Cleaning ugly bibtex fields for all entries");

    $self->helper_clean_ugly_bibtex_fileds_for_all_entries();

    $self->write_log("Cleaning ugly bibtex fields for all entries has finished");

    $self->redirect_to($back_url);
};

####################################################################################






####################################################################################

## SPECIAL FUNCTION
# if pdf exists locally, change the bibtex code to point to the local file

sub special_map_pdf_to_local_file{
    say "CALL: special_map_pdf_to_local_file";
    my $self = shift;
    my $id = $self->param('id');
    
    my $fname = "paper-".$id.".pdf";
    my $directory = "uploads/papers/";
    my $bibtex_field = "pdf";

    # $fname_no_ext = "slides-paper-".$id.".";
    # $fname = $fname_no_ext.$extension;
    # $directory = "uploads/slides/";
    # $bibtex_field = "slides";

    my $file_path = $directory.$fname;

    say $file_path;

    my $exists = 0;
    $exists = 1 if -e "public/".$file_path;

    say "exists $exists";

    my $file_url = $self->req->url->base."".$file_path;
    say $file_url;

    if($exists == 1){
        add_field_to_bibtex_code($self->app->db, $id, $bibtex_field, $file_url);    
        generate_html_for_id($self->app->db, $id);
    }
    

    my $msg = "Processing id $id. EXISTS $exists. bibtex_filed $bibtex_field. file_url $file_url, FILE_PATH $file_path.";

    $self->render(text => $msg);
};

####################################################################################


1;