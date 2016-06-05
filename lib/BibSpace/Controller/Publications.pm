package BibSpace::Controller::Publications;

use Data::Dumper;
use utf8;
use Text::BibTeX; # parsing bib files
use DateTime;
use File::Slurp; # should be replaced in the future
use Path::Tiny;  # for creating directories
use Try::Tiny;
use Time::Piece;
use 5.010; #because of ~~
use strict;
use warnings;
use DBI;

use TeX::Encode;
use Encode;

use BibSpace::Controller::Core;
use BibSpace::Functions::FPublications;
use BibSpace::Model::MEntry;

use BibSpace::Controller::Set;
use BibSpace::Functions::EntryObj;
use BibSpace::Functions::TagObj;

use Set::Scalar;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::UserAgent;
use Mojo::Log;



####################################################################################
sub isTalk {  # stupid code repetition!
    my $self = shift;
    my $obj = shift;
    return $obj->isTalk();
}
# ####################################################################################
# sub fixMonths {
#     say "CALL: fixMonths ";
#     my $self = shift;

#     my @objs = BibSpace::Functions::EntryObj->getAll($self->app->db);
#     my $num_checks = 0;
#     for my $o (@objs){
#         my $entry = new Text::BibTeX::Entry();
#         $entry->parse_s($o->{bib});

#          $num_checks = $num_checks + after_edit_process_month($self->app->db, $entry);
#     }
#     $self->flash(msg => 'Fixing entries month field finished. Num entries checked: '.$num_checks);
#     $self->redirect_to($self->get_referrer);
# }
####################################################################################
sub fixMonths {
    say "CALL: fixMonths ";
    my $self = shift;

    my ($processed_entries, $fixed_entries) = Ffix_months($self->app->db);
    $self->flash(msg => 'Fixing entries month field finished. Num entries checked/fixed: '.$processed_entries."/".$fixed_entries);
    $self->redirect_to($self->get_referrer);
}
####################################################################################
sub fixEntryType {
    say "CALL: fixEntryType ";
    my $self = shift;



    my @objs = BibSpace::Functions::EntryObj->getAll($self->app->db);
    my $num_fixes = 0;
    for my $o (@objs){
        $num_fixes = $num_fixes + $o->fixEntryTypeBasedOnTag($self->app->db);
    }

    $self->flash(msg => 'All entries have now their paper/talk type fixed. Number of fixes: '.$num_fixes);
    $self->redirect_to($self->get_referrer);
}
####################################################################################
sub unhide {
    say "CALL: Publications::unhide";
    my $self = shift;
    my $id = $self->param('id');

    my $dbh = $self->app->db;



    my $obj = BibSpace::Functions::EntryObj->new({id => $id});
    $obj->initFromDB($dbh);
    $obj->unhide($dbh);

    $self->redirect_to($self->get_referrer);
};

####################################################################################
sub hide {
    say "CALL: Publications::hide";
    my $self = shift;
    my $id = $self->param('id');

    my $dbh = $self->app->db;



    my $obj = BibSpace::Functions::EntryObj->new({id => $id});
    $obj->initFromDB($dbh);
    $obj->hide($dbh);

    $self->redirect_to($self->get_referrer);
};
####################################################################################
sub toggle_hide {
    say "CALL: Publications::toggle_hide";
    my $self = shift;
    my $id = $self->param('id');
    my $dbh = $self->app->db;

    my $obj = BibSpace::Functions::EntryObj->new({id => $id});
    $obj->initFromDB($dbh);
    $obj->do_toggle_hide($dbh);


    $self->redirect_to($self->get_referrer);
};
####################################################################################
sub make_paper {
    my $self = shift;
    my $id = $self->param('id');

    my $dbh = $self->app->db;



    my $obj = BibSpace::Functions::EntryObj->new({id => $id});
    $obj->initFromDB($dbh);
    $obj->makePaper($dbh);

    $self->redirect_to($self->get_referrer);
};
####################################################################################
sub make_talk {
    my $self = shift;
    my $id = $self->param('id');

    my $dbh = $self->app->db;



    my $obj = BibSpace::Functions::EntryObj->new({id => $id});
    $obj->initFromDB($dbh);
    $obj->makeTalk($dbh);

    $self->redirect_to($self->get_referrer);
};
####################################################################################
sub metalist {
    say "CALL: metalist ";
    my $self = shift;

    my @ids_arr = ();
    my @pubs = get_publications_main_hashed_args_only($self, {hidden => 0, entry_type=>'paper'});
    for my $entry (@pubs){
        my $eid = $entry->{id};
        push @ids_arr, $eid if defined $eid;
    }

    # my @old_ids_arr = get_all_non_hidden_entry_ids($self->app->db);

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

    my $qry = "SELECT DISTINCT id, bibtex_key, year
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


    $self->write_log("Displaying entries without month");

    my @objs = ();
    my @all_objs = BibSpace::Functions::EntryObj->getAll($self->app->db);
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
    # FIXME! TODO! Catastrophe! use here url_with to fix it!!

    my $url = $self->url_with('lp');
    my $url_msg = "Switch to grouping by types";
    my $switchlink = '<a class="bibtexitem" href="'.$url.'">'.$url_msg.'</a>';


    # NAVBAR
    my $tmp_year = $self->req->url->query->param('year');
    $self->req->url->query->remove('year');
    my $navbar_html = '<a class="bibtexitem" href="'.$self->url_with('current').'">[show ALL years]</a> ';
    $self->req->url->query->param(year => $tmp_year) if defined $tmp_year and $tmp_year ne "";

    my $tmp_type = $self->req->url->query->param('bibtex_type');
    $self->req->url->query->remove('bibtex_type');
    $navbar_html .= '<a class="bibtexitem" href="'.$self->url_with('current').'">[show ALL types]</a> ';
    $navbar_html .= '<br/>';
    $self->req->url->query->param(bibtex_type => $tmp_type) if defined $tmp_type and $tmp_type ne "";

    foreach my $key (reverse sort @keys) {

        $self->req->url->query->param(year => $key);
        $navbar_html .= '<a class="bibtexitem" href="'.$self->url_with('current',bibtex_type=>$tmp_type ).'">';
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



    my $url = $self->url_with('lyp');
    my $url_msg = "Switch to grouping by years";
    my $switchlink = '<a class="bibtexitem" href="'.$url.'">'.$url_msg.'</a>';



    # NAVBAR

    my $tmp_year = $self->req->url->query->param('year');
    $self->req->url->query->remove('year');
    my $navbar_html = '<a class="bibtexitem" href="'.$self->url_with('current').'">[show ALL years]</a> ';
    $self->req->url->query->param(year => $tmp_year) if defined $tmp_year and $tmp_year ne "";

    $self->req->url->query->remove('bibtex_type');
    $self->req->url->query->remove('entry_type');
    $navbar_html .= '<a class="bibtexitem" href="'.$self->url_with('current').'">[show ALL types]</a> ';
    $navbar_html .= '<br/>';

    foreach my $key (sort @keys_with_papers) {
        # say "key in keys_with_papers: $key";

        if($key eq 'talk'){
            $self->req->url->query->remove('bibtex_type');
            $self->req->url->query->param(entry_type => 'talk');
            $navbar_html .= '<a class="bibtexitem" href="'.$self->url_with('current',entry_type=>'talk' ).'">';
        }
        else{
            $self->req->url->query->remove('entry_type');
            $self->req->url->query->param(bibtex_type => $key);
            $navbar_html .= '<a class="bibtexitem" href="'.$self->url_with('current',bibtex_type=>$key ).'">';
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
    my $tag_name_for_permalink = BibSpace::Functions::TagObj->get_tag_name_for_permalink($self->app->db, $permalink);
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
sub remove_attachment{
    my $self = shift;
    my $id = $self->param('id');      # entry ID
    my $filetype = $self->param('filetype') || 'paper';  # paper, slides

    $self->write_log("Removing attachment to download: filetype $filetype, id $id. ");
    say "Removing attachment to download: filetype $filetype, id $id. ";

    my $file_path = get_paper_pdf_path($self, $id, "$filetype");
    say "file_path $file_path";
    my $num_deleted_files = 0;

    if(!defined $file_path or $file_path eq 0){
        $self->write_log("Cannot remove attachment. File does not exist. Filetype $filetype, id $id.");
        $self->flash(msg => "File not found. Cannot remove attachment. Filetype $filetype, id $id.");
        $self->redirect_to($self->get_referrer);
        return;
    }
    else{ # file exists

        $num_deleted_files = $self->remove_attachment_do($id, $filetype);

        if($num_deleted_files > 0){
            generate_html_for_id($self->app->db, $id);
        }

        $self->write_log("$num_deleted_files attachments removed for id $id.");
        $self->flash(msg => "There were $num_deleted_files attachments removed for id $id.");
        $self->redirect_to($self->get_referrer);
    }
}
####################################################################################
sub remove_attachment_do{
    say "CALL: remove_attachment_do";
    my $self = shift;
    my $id = shift;
    my $filetype = shift;

    my $file_path = get_paper_pdf_path($self, $id, "$filetype");
    say "Found paper type $filetype : $file_path";

    my $num_deleted_files = 0;

    if(!defined $file_path or $file_path eq 0){
        return 0;
    }

    try{
        unlink $file_path;
        $num_deleted_files = $num_deleted_files +1;
        say "Deleting attachment file: $file_path";
    }
    catch{};

    # make sure that there is no file
    my $file_path_after_delete = get_paper_pdf_path($self, $id, "$filetype");
    while($file_path_after_delete ne 0){
        say "File deleted but something is left: $file_path_after_delete";
        try{
            unlink $file_path;
            $num_deleted_files = $num_deleted_files +1;
            say "Deleting attachment file: $file_path";
        }
        catch{};
        $file_path_after_delete = get_paper_pdf_path($self, $id, "$filetype");
    }
    # deleted for sure!

    if($filetype eq 'paper'){
        clean_ugly_bibtex_fields($self->app->db, $id, qw(pdf));
    }
    if($filetype eq 'slides'){
        clean_ugly_bibtex_fields($self->app->db, $id, qw(slides));
    }

    return $num_deleted_files;
}
####################################################################################
sub download {
    my $self = shift;
    my $id = $self->param('id');      # entry ID
    my $filetype = $self->param('filetype') || 'paper';  # paper, slides

    $self->write_log("Requesting download: filetype $filetype, id $id. ");


    my $file_path = $self->get_paper_pdf_path($id, "$filetype");
    say "Found paper type $filetype : $file_path";

    if(!defined $file_path or $file_path eq 0){
        $self->write_log("Unsuccessful download filetype $filetype, id $id.");
        $self->render(text => "File not found. Unsuccessful download filetype $filetype, id $id.");
        return;
    }

    my $exists = 0;
    $exists = 1 if -e $file_path;

    if($exists == 1){
        $self->write_log("Serving file $file_path");
        $self->render_file('filepath' => $file_path);
    }
    else{
        $self->redirect_to($self->get_referrer);
    }
}
####################################################################################

sub add_pdf {
	say "CALL: add_pdf ";
    my $self = shift;
    my $id = $self->param('id');
    my $dbh = $self->app->db;


    $self->write_log("Page: add pdf for paper id $id");

    # getting html preview
    my $sth = $dbh->prepare( "SELECT DISTINCT bibtex_key, html, bibtex_type FROM Entry WHERE id = ?" );
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref();
    my $html_preview = $row->{html} || nohtml($row->{bibtex_key}, $row->{bibtex_type});
    my $key = $row->{bibtex_key};
    my $type = $row->{bibtex_type};


    $self->stash(id => $id, bkey=> $key, btype=>$type, preview => $html_preview);
    $self->render(template => 'publications/pdf_upload');
};
####################################################################################
sub add_pdf_post{
	say "CALL: add_pdf_post";
    my $self = shift;
    my $id = $self->param('id') || "unknown";
    my $filetype = $self->param('filetype') || undef;

    my $uploads_directory = $self->config->{upload_dir};
    $uploads_directory =~ s!/*$!/!; # makes sure that there is exactly one / at the end

    my $extension;

    $self->write_log("Saving attachment for paper id $id");


    # Check file size
    if ($self->req->is_limit_exceeded){
        $self->write_log("Saving attachment for paper id $id: limit exceeded!");
        $self->flash(message => "The File is too big and cannot be saved!", msg_type => "danger");
        $self->redirect_to($self->get_referrer);
        return;
    }



    # Process uploaded file
    my $uploaded_file = $self->param('uploaded_file');

    unless ($uploaded_file){
      $self->flash(message => "File upload unsuccessful!", msg_type => "danger");
      $self->write_log("Saving attachment for paper id $id FAILED. Unknown reason");
      $self->redirect_to($self->get_referrer);
    }

    my $size = $uploaded_file->size;
    if ($size == 0){
        $self->flash(message => "No file was selected or file has 0 bytes! Not saving!", msg_type => "danger");
        $self->write_log("Saving attachment for paper id $id FAILED. File size is 0.");
        $self->redirect_to($self->get_referrer);
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

            $directory = "papers/";
            $bibtex_field = "pdf";
        }
        elsif($filetype eq 'slides'){
            $fname_no_ext = "slides-paper-".$id.".";
            $fname = $fname_no_ext.$extension;
            $directory = "slides/";
            $bibtex_field = "slides";
        }
        else{
            $fname_no_ext = "unknown-".$id.".";
            $fname = $fname_no_ext.$extension;
            $directory = "unknown/";

            $bibtex_field = "pdf2";
        }
        try{
            path($uploads_directory.$directory)->mkpath;
        }
        catch{
            warn "Exception: cannot create directory $directory. Msg: $_";
        };

        $file_path = $directory.$fname;

        # remove old file that would match the patterns
        my $old_file = $self->get_paper_pdf_path($id, "$filetype");
        say "old_file: $old_file";
        if($old_file ne 0){
            # old file exists and must be deleted!
            try{
                unlink $old_file;
                say "Deleting $old_file";
            }
            catch{};
        }

        $uploaded_file->move_to($uploads_directory.$file_path); ### WORKS!!!
        my $new_file = $self->get_paper_pdf_path($id, "$filetype");


        my $file_url = $self->url_for('download_publication', filetype => "$filetype", id => $id)->to_abs;
        if($filetype eq 'paper'){ # so that the link looks nicer
            say "Nicing the url for paper";
            say "old file_url $file_url";
            $file_url = $self->url_for('download_publication_pdf', filetype => "paper", id => $id)->to_abs;
            say "file_url $file_url";
        }

        $self->write_log("Saving attachment for paper id $id under: $file_url");
        add_field_to_bibtex_code($self->app->db, $id, $bibtex_field, "$file_url");

        my $msg = "Successfully uploaded the $sizeKB KB file <em>$name</em> as <strong><em>$filetype</em></strong>.
        The file was renamed to: <em>$fname</em>. URL <a href=\"".$file_url."\">$name</a>";

        # my $sth2 = $self->app->db->prepare( "UPDATE Entry SET modified_time=datetime('now', 'localtime') WHERE id =?" );
        my $sth2 = $self->app->db->prepare( "UPDATE Entry SET modified_time=CURRENT_TIMESTAMP WHERE id =?" );

        $sth2->execute($id);
        $sth2->finish();

        generate_html_for_id($self->app->db, $id);

        $self->flash(message => $msg);
        $self->redirect_to($self->get_referrer);
    }
};

####################################################################################
####################################################################################
sub regenerate_html_for_all {
	say "CALL: regenerate_html_for_all ";
  my $self = shift;


  my $dbh = $self->app->db;


  $self->write_log("regenerate_html_for_all is running");

  $self->helper_regenerate_html_for_all();

  $self->write_log("regenerate_html_for_all has finished");

  $self->flash(msg => 'Regeneration of HTML code finished.');
  my $referrer = $self->get_referrer();
    $self->redirect_to($referrer);
};
####################################################################################
sub regenerate_html_for_all_force {
	say "CALL: regenerate_html_for_all_force ";
    my $self = shift;


    my $dbh = $self->app->db;



    $self->write_log("regenerate_html_for_all FORCE is running");

    my @ids = get_all_entry_ids($dbh);
    for my $id (@ids){
      generate_html_for_id($dbh, $id);
    }

    $self->write_log("regenerate_html_for_all FORCE has finished");

    $self->flash(msg => 'Regeneration of HTML code finished.');
    my $referrer = $self->get_referrer();
    $self->redirect_to($referrer);
};
####################################################################################
sub regenerate_html {
	say "CALL: regenerate_html ";
    my $self = shift;
    my $id = $self->param('id');


    my $dbh = $self->app->db;
    generate_html_for_id($dbh, $id);

    my $referrer = $self->get_referrer();
    $self->redirect_to($referrer);
};

####################################################################################

sub delete {
    my $self = shift;
    my $id = $self->param('id');
    warn "deleting this way is not implemented! TODO: remove";
    $self->redirect_to($self->get_referrer);
};

####################################################################################

sub delete_sure {
	say "CALL: delete_sure ";
   my $self = shift;
   my $eid = $self->param('id');

   my $dbh = $self->app->db;

   delete_entry_by_id($dbh, $eid);

   remove_attachment_do($self, $eid, 'paper');
   remove_attachment_do($self, $eid, 'slides');

   $self->write_log("delete_sure entry eid $eid. Entry deleted.");

   $self->redirect_to($self->get_referrer);
};
####################################################################################
sub show_authors_of_entry{
	say "CALL: show_authors_of_entry";
    my $self = shift;
    my $eid = $self->param('id');

    my $dbh = $self->app->db;

    $self->write_log("Showing authors of entry eid $eid");

    my @authors = $self->get_authors_of_entry($eid);

    my $teams_for_paper = get_set_of_teams_for_entry_id($self,$eid);
    my @teams = $teams_for_paper->members;


    my $html_preview = get_html_for_entry_id($dbh, $eid);
    my $key = get_entry_key($dbh, $eid);


    $self->stash(eid => $eid, key => $key, preview => $html_preview,
        author_ids => \@authors, team_ids => \@teams);
    $self->render(template => 'publications/show_authors');
}
####################################################################################
sub manage_exceptions{
	say "CALL: manage_exceptions";
    my $self = shift;
    my $eid = $self->param('id');
    my $dbh = $self->app->db;

    $self->write_log("Manage exceptions of entry eid $eid");

    my $html_preview = get_html_for_entry_id($dbh, $eid);
    my $key = get_entry_key($dbh, $eid);
    my $btype = get_entry_bibtex_type($dbh, $eid);

    my @current_exceptions = get_exceptions_for_entry_id($dbh, $eid);
    my $current_exceptions_set = Set::Scalar->new(@current_exceptions);

    my @authors = $self->get_authors_of_entry($eid);
    my $teams_for_paper = get_set_of_teams_for_entry_id($self,$eid);

    my @teams = $teams_for_paper->members;
    my @unassigned_teams = (get_set_of_all_teams($self) - $teams_for_paper - $current_exceptions_set)->members;


    $self->stash(eid => $eid, key => $key, btype=>$btype, preview => $html_preview,
        author_ids => \@authors, exceptions => \@current_exceptions, team_ids => \@teams, unassigned_teams => \@unassigned_teams);
    $self->render(template => 'publications/manage_exceptions');
}
####################################################################################
sub manage_tags{
	say "CALL: manage_tags";
    my $self = shift;
    my $eid = $self->param('id');

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


  $self->stash(eid => $eid, key => $key, preview => $html_preview,
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
  my $dbh = $self->app->db;

  $self->write_log("Removing tag id $tid from entry eid $eid");

  my $sth = $dbh->prepare( "DELETE FROM Entry_to_Tag WHERE entry_id=? AND tag_id=?");
  $sth->execute($eid, $tid);


  $self->redirect_to($self->get_referrer);

}
####################################################################################

sub add_tag{
    say "CALL: add_tag";
    my $self = shift;
    my $eid = $self->param('eid');
    my $tid = $self->param('tid');
    my $dbh = $self->app->db;

    $self->write_log("Adding tag id $tid to entry eid $eid");

    my $sth = $dbh->prepare( "INSERT INTO Entry_to_Tag(entry_id, tag_id) VALUES (?,?)");
    $sth->execute($eid, $tid);
    $self->redirect_to($self->get_referrer);
}
####################################################################################

sub add_exception{
	say "CALL: add_exception";
    my $self = shift;
    my $eid = $self->param('eid');
    my $tid = $self->param('tid');
    my $dbh = $self->app->db;

    $self->write_log("Adding exception id $tid to entry eid $eid");

    my $sth = $dbh->prepare( "INSERT INTO Exceptions_Entry_to_Team(entry_id, team_id) VALUES (?,?)");
    $sth->execute($eid, $tid);

    $self->redirect_to($self->get_referrer);

}
####################################################################################

sub remove_exception{
	say "CALL: remove_exception";
    my $self = shift;
    my $eid = $self->param('eid');
    my $tid = $self->param('tid');
    my $dbh = $self->app->db;

    $self->write_log("Removing exception id $tid to entry eid $eid");

    my $sth = $dbh->prepare( "DELETE FROM Exceptions_Entry_to_Team WHERE entry_id=? AND team_id=?");
    $sth->execute($eid, $tid);

    $self->redirect_to($self->get_referrer);

}


####################################################################################
################################################################ ADDING ############
####################################################################################

## ADD form
# sub publications_add_get {
#     say "CALL: publications_add_get ";
#     my $self = shift;
#     my %mons = (1=>'January',2=>'February',3=>'March',4=>'April',5=>'May',6=>'June',7=>'July',8=>'August',9 =>'September',10=>'October',11=>'November',12=>'December');

#     my $bib = '@article{key'.get_current_year().',
#         author = {Johny Example},
#         title = {{Selected aspects of some methods}},
#         year = {'.get_current_year().'},
#         month = {'.$mons{get_current_month()}.'},
#         day = {1--31},
#     }';

#     my $msg ="Adding mode</strong> You operate on an unsaved entry!";
#     $self->stash(bib  => $bib, key => '', id => -1, existing_id => '', exit_code => '', msg => $msg, preview => '');
#     return $self->publications_edit_get();

#     # $self->render(template => 'publications/edit_entry');
# };

####################################################################################

## ADD form
sub publications_add_many_get {
    say "CALL: publications_add_many_get ";
    my $self = shift;
    my %mons = (1=>'January',2=>'February',3=>'March',4=>'April',5=>'May',6=>'June',7=>'July',8=>'August',9 =>'September',10=>'October',11=>'November',12=>'December');

    my $bib = '';

    my $msg ="Adding multiple publications at once is <strong>experimental!</strong> <br/> <strong>Adding mode</strong> You operate on an unsaved entry!";

    $self->stash(bib  => $bib, key => '', existing_id => '', exit_code => '', msg => $msg, preview => '');
    $self->render(template => 'publications/add_multiple_entries');
};
############################################################################################################

## Called after every preview or store command issued by ADD_MULTIPLE form
sub post_add_many_store {
    say "CALL: post_add_many_store ";
    my $self = shift;
    my $id = $self->param('id') || undef;
    my $new_bib = $self->param('new_bib');
    my $preview_param = $self->param('preview') || undef;
    # my $check_key =  || undef;
    my $preview = 0;
    my $msg ="<strong>Adding mode</strong> You operate on an unsaved entry!";

    $self->write_log("post_add_many_store add publication with bib $new_bib");

    my $debug_str = "";


    my $dbh = $self->app->db;
    my $html_preview = "";
    my $code = -2;

    my @bibtex_codes = split_bibtex_entries($new_bib);
    my @key_arr = ();

    for my $bibtex_code (@bibtex_codes){
        # $debug_str.="<br>Found code!";

        my $bibtex_key = get_key_from_bibtex_code($bibtex_code);
        $debug_str.="<br>Found key: $bibtex_key";

        push @key_arr, $bibtex_key;
    }

    my @existing_ids = ();
    my @existing_keys = ();

    for my $key (@key_arr){
         my $single_id = Fget_entry_id_for_bibtex_key($dbh, $key);
         if($single_id ne -1){
            push @existing_ids, $single_id;
            push @existing_keys, $key;
            $debug_str.="<br>ID exists: $single_id";
            $debug_str.="<br>KEY exists: $key";
         }

    }

    $debug_str.="<br>==== Processing done. Existing keys: ".@existing_ids." join: ".join(' ', @existing_keys).".";



    my %seen;
    my $are_unique = 0;
    # if size of arr is equal to size of uniq arr
    $are_unique = 1 if uniq(@key_arr)==@key_arr;
    # count how many times a given key appears
    foreach my $value (@key_arr) {
        $seen{$value}++;
    }

    $debug_str.="<br>Checking if input keys are unique: ";
    $debug_str.="Yes!" if $are_unique;
    $debug_str.="No! " unless $are_unique;


    # say "key $key";
    # say "existing_id $existing_id";
    my $param_prev = $self->param('preview') || "";
    my $param_save = $self->param('save') || "";



    if (@existing_ids) {  # if the array is not empty
        $msg = $debug_str."<br/>"."<strong>The following keys exist already in the system: ".join(', ', @existing_keys)."</strong>";

        $self->stash(bib  => $new_bib, existing_id => 0, key => '', msg =>$msg, exit_code => $code, preview => $html_preview);
        $self->render(template => 'publications/add_multiple_entries');
        return;
    }

    if ($are_unique == 0) {  # if the array is not empty
        $debug_str.="<br/>"."Some bibtex keys in the input are not unique. Please correct the input.";
        foreach my $key ( keys %seen ){
            $debug_str.="<br/>"."Bibtex key: $key exists ".$seen{$key}." times!" if $seen{$key} > 1;
        }

        $msg = $debug_str;

        $self->stash(bib  => $new_bib, existing_id => 0, key => '', msg =>$msg, exit_code => $code, preview => $html_preview);
        $self->render(template => 'publications/add_multiple_entries');
        return;
    }

    $debug_str.="<br>Entries ready to add! Starting.";

    $msg = "";
    # here assume that the codes in array @bibtex_codes are ready to add
    for my $single_code (@bibtex_codes){
        my $entry = new Text::BibTeX::Entry;
        $entry->parse_s($single_code);

        $debug_str.="<br>====== Entry ";
        $debug_str.="<br>"."Parse ok? ".$entry->parse_ok;
        $debug_str.="<br>"."Do you wanted to save? ";
        $debug_str.="YES" if defined $self->param('save');
        $debug_str.="NO, just checking" unless defined $self->param('save');

        $debug_str.="<br>"."Entry has key: ".$entry->key;

        if($entry->parse_ok and defined $self->param('save')){
            $debug_str.="<br>"."Adding!";

            my $single_key = $entry->key;
            my $bib_html;
            ($html_preview, $bib_html) = Fget_html_preview($single_code);

            # ($code, $html_preview) = postprocess_edited_entry($dbh, $single_code, 0);  #FIXME: added entry is strange!
            $code = postprocess_changed_entry($dbh, $single_code, -1);  #old FIXME: added entry is strange!

            my $added_id = Fget_entry_id_for_bibtex_key($dbh, $single_key);

            $debug_str.="<br>"."Added key $single_key as id $added_id successfully!<br/>";
            $msg .= "Added key $single_key as id $added_id successfully!<br/>";
        }
    }

    say "after bibtex codes loop";

    $self->stash(bib  => $new_bib, existing_id => 0, key => '', msg =>$msg.$debug_str, exit_code => $code, preview => $html_preview);
    $self->render(template => 'publications/add_multiple_entries');
};
####################################################################################
sub split_bibtex_entries{
    say "CALL: split_bibtex_entries";
    my $input = shift;

    my @bibtex_codes = ();
    $input =~ s/^\s+|\s+$//g;
    $input =~ s/^\t//g;

    for my $b_code (split /@/, $input){
        next unless length($b_code) > 10;
        my $entry_code = "@".$b_code;

        my $entry = new Text::BibTeX::Entry;
        $entry->parse_s($entry_code);
        if($entry->parse_ok){
            push @bibtex_codes, $entry_code;
        }
    }

    return @bibtex_codes;
}
####################################################################################
############################################################################################################


####################################################################################
sub get_adding_editing_message_for_error_code {
    my $self = shift;
    my $exit_code = shift;
    my $existing_id = shift || -1;

    if($exit_code eq '-1'){
        return "You have bibtex errors! Not saving!";
    }
    elsif($exit_code eq '-2'){
        return 'Displaying preview';
    }
    elsif($exit_code eq '0'){
        return 'Entry added successfully';
    }
    elsif($exit_code eq '1'){
        return 'Entry updated successfully';
    }
    elsif($exit_code eq '2'){
        return 'The proposed key is OK.';
    }
    elsif($exit_code eq '3'){
        return 'The proposed key exists already in DB under ID <button class="btn btn-danger btn-xs" tooltip="Entry ID"> <span class="glyphicon glyphicon-barcode"></span> '.$existing_id.'</button>.
                    <br>
                    <a class="btn btn-info btn-xs" href="'.$self->url_for('publicationsgetid', id=>$existing_id).'" target="_blank"><span class="glyphicon glyphicon-search"></span>Show me the existing entry ID '.$existing_id.' in a new window</a>
                    <br>
                    Entry has not been saved. Please pick another BibTeX key.';
    }
    elsif(defined $exit_code and $exit_code ne ''){
        return "Unknown exit code: $exit_code";
    }

};

####################################################################################
################################################################ EDITING ###########
####################################################################################
sub publications_edit_get {
  say "CALL: publications_edit_get ";
  my $self = shift;
  my $id = $self->param('id') || -1;
  $self->write_log("Editing publication entry id $id");

  my $dbh = $self->app->db;

  my $msg = "";
  my $e_dummy = MEntry->new();

  ######## adding new
  if($id < 0){ 
    my %mons = (1=>'January',2=>'February',3=>'March',4=>'April',5=>'May',6=>'June',7=>'July',8=>'August',9 =>'September',10=>'October',11=>'November',12=>'December');

    my $bib = '@article{key'.get_current_year().',
        author = {Johny Example},
        title = {{Selected aspects of some methods}},
        year = {'.get_current_year().'},
        month = {'.$mons{get_current_month()}.'},
        day = {1--31},
    }';
    $e_dummy->{bib} = $bib;

    $msg ="Adding mode</strong> You operate on an unsaved entry!";
    
    # $self->stash(bib  => $bib, key => '', id => -1, existing_id => '', exit_code => '', msg => $msg, preview => '');
    # return $self->publications_edit_get();
  }
  ######## editing existing
  else{ 
    $e_dummy->get($dbh, $id);
  }

  $e_dummy->populate_from_bib();

  # compatibility with old code
  my $obj = BibSpace::Functions::EntryObj->new();
        
  $obj->{bib} = $e_dummy->{bib};
  $obj->{key} = $e_dummy->{bibtex_key};
  my ($html, $htmlbib) = Fget_html_preview($e_dummy->{bib});  
  $obj->{html} = $html;
  $obj->{id} = $id;
  say "CALL: publications_edit_get rendering!";

  $self->stash(bib  => $obj->{bib}, entry_obj => $obj, id => $id, key => $obj->{key}, existing_id => '', exit_code => '',
                msg => $msg, preview => $html);
  $self->render(template => 'publications/edit_entry');
};
############################################################################################################
sub post_add_edit_store {
  say "CALL: post_add_edit_store ";
  my $self = shift;
  my $id = $self->param('id') || -1;
  my $new_bib = $self->param('new_bib');
  my $param_prev = $self->param('preview');
  my $param_save = $self->param('save');
  my $param_check_key = $self->param('check_key');
  my $dbh = $self->app->db;

  ##################################################
  my $method = $self->req->method;
  say ">>>>>>> method: $method";
  ##################################################
  if($method eq 'GET'){

    return $self->publications_edit_get();
  }
  ##################################################
  elsif($method eq 'POST'){

    $self->write_log("Post_add_edit_store: adding/editing publication entry id $id");

    # option 1 $id undef ===> adding

    # error codes
    # -1 You have bibtex errors! Not saving!";
    # -2 Displaying preview';
    # 0 Entry added successfully';
    # 1 Entry updated successfully';
    # 2 The proposed key is OK.
    # 3 Proposed key exists already - HTML message

    my $key = -1;
    $key = get_key_from_bibtex_code($new_bib) if defined $new_bib;
    $new_bib =~ s/^\s+|\s+$//g;
    $new_bib =~ s/^\t//g;

    my $existing_id = Fget_entry_id_for_bibtex_key($dbh, $key);

    my $code = -2;
    if(defined $key and $key eq '-1'){   # generate bibtex errors
        $code = -1;

        my $msg = get_adding_editing_message_for_error_code($self, $code, $existing_id);
        say ">>> rendering bibtex errors";
        $self->stash(bib  => $new_bib, key => $key, existing_id => '', id=>$id, msg => $msg, exit_code => $code, preview => '');
        $self->render(template => 'publications/edit_entry');
        return;
    }
    # code free from BibTeX errors

    # watch out! $id >0 but $existing_id = -1 ==> change of bibtex key!!
    # now check if the key exists
    say "Checking for existing bibtex key";
    if(defined $self->param('check_key') or
       ($id > 0 and $existing_id != $id) or
       ($id < 1 and $existing_id > 0))
    {
      say "Checking for existing bibtex key: inside id $id existing_id $existing_id";
      if($existing_id == -1){
            $code = 2;
        }
        elsif($existing_id > 0){
            $code = 3;
        }

      my $msg = get_adding_editing_message_for_error_code($self, $code, $existing_id);
      my ($html, $htmlbib) = Fget_html_preview($new_bib);

      if($existing_id > 0){ # we are not changing the bibtex key
        say ">>> rendering check key";
        $self->stash(bib  => $new_bib, id => $id, existing_id => $existing_id, key => $key, msg =>$msg, exit_code => $code, preview => $html);
        $self->render(template => 'publications/edit_entry');
        return;
      }
      
    }
    say "Checking for existing bibtex key: done";
    # here you need to be sure that the key is okay and you can proceed

    if(defined $param_prev){

      my $obj = BibSpace::Functions::EntryObj->new({id => $id});
      $obj->initFromDB($dbh) if defined $id;
      $obj->{bib} = $new_bib;
      $obj->{key} = $key;

      $code = -2; # Dipslaying previev
      $code = 3 if $existing_id > 0; # generate key-exists msg
      $code = -2 if $existing_id > 0 and $id > 0; # displaying preview
      
      my ($html, $htmlbib) = Fget_html_preview($new_bib);  
      $obj->{html} = $html;
      my $msg = get_adding_editing_message_for_error_code($self, $code, $existing_id);
      say ">>> rendering param prev";
      $self->stash(bib  => $new_bib, entry_obj => $obj, id=>$id, key => $key, existing_id => $existing_id, msg => $msg, exit_code => $code, preview => $html);
      $self->render(template => 'publications/edit_entry');
      return;
    }
    if(defined $param_save){

      if(($id > 0 and $existing_id==$id) or ($id > 0 and $existing_id==-1)){ # this is editing

        my $obj = BibSpace::Functions::EntryObj->new({id => $id});
        $obj->initFromDB($dbh) if defined $id;
        $obj->{bib} = $new_bib;
        $obj->{key} = $key;

        $code = postprocess_changed_entry($dbh, $new_bib, $id);
        my ($html, $htmlbib) = Fget_html_preview($new_bib);  
        $id = Fget_entry_id_for_bibtex_key($dbh, $key);
        $obj->{html} = $html;
        $obj->{id} = $id;

        $code = 1;
        my $msg = get_adding_editing_message_for_error_code($self, $code, $existing_id);

        say ">>> rendering param save edit";
        $self->stash(bib  => $new_bib, entry_obj => $obj, id=>$id, key => $key, existing_id => '', msg => $msg, exit_code => $code, preview => $html);
        $self->render(template => 'publications/edit_entry');
        return;
      }
      else{ # this is adding

        $code = postprocess_changed_entry($dbh, $new_bib, -1);
        $id = Fget_entry_id_for_bibtex_key($dbh, $key);
        my ($html, $htmlbib) = Fget_html_preview($new_bib);
        $code = 0;
        my $msg = get_adding_editing_message_for_error_code($self, $code, $existing_id);

        my $obj = BibSpace::Functions::EntryObj->new({id => $id});
        $obj->initFromDB($dbh) if defined $id;

        say ">>> rendering param save add";
        # $self->redirect_to($self->url_for('edit_publication', id=>$id));
        $self->stash(bib  => $new_bib, entry_obj => $obj, id=>$id, key => $key, existing_id => '', msg => $msg, exit_code => $code, preview => $html);
        $self->render(template => 'publications/edit_entry');
        return;
      }
    }
  } # elsif($method eq 'POST'){
  else{
    $self->render(text => "Such route does not exist", status => 404);
  }
};
##################################################################
sub get_key_from_bibtex_code{
	say "CALL: get_key_from_bibtex_code";
  my $code = shift;
  my $entry = new Text::BibTeX::Entry();
  $entry->parse_s($code);
  return -1 unless $entry->parse_ok;
  return $entry->key;
}
##################################################################
sub postprocess_changed_entry{  # don't care if edited or updated
    my $dbh = shift;
    my $entry_str = shift;
    my $eid = shift; # remains unchanged

    say "@@@@@@@@@ CALL postprocess_changed_entry. eid $eid";

    my $entry = new Text::BibTeX::Entry();
    $entry->parse_s($entry_str);
    return -1 unless $entry->parse_ok;  # exit code -1 = bibtex errors

    my $exit_code = -2;

    my $e = MEntry->new();

    if(defined $eid and $eid > 0){ # we update entry

        $e->get($dbh, $eid);
        $e->{bib} = $entry_str;
        $e->populate_from_bib();

        $e->save($dbh); # optional

        $exit_code = $e->postprocess_updated($dbh); # this saves

        return 1; # updated OK
    }
    else{ # we add entry
        $e->{bib} = $entry_str;
        $e->populate_from_bib();
        
        $e->save($dbh); # optional
        
        $exit_code = $e->postprocess_updated($dbh); # this saves
        

        $exit_code = 0; # added OK

        return $exit_code;
    }
};

##########################################################################################




####################################################################################
sub clean_ugly_bibtex {
	say "CALL: clean_ugly_bibtex ";
    my $self = shift;

    my $dbh = $self->app->db;


    $self->write_log("Cleaning ugly bibtex fields for all entries");

    $self->helper_clean_ugly_bibtex_fields_for_all_entries();

    $self->write_log("Cleaning ugly bibtex fields for all entries has finished");

    $self->flash(msg => 'All entries have now their Bibtex cleaned.');


    $self->redirect_to($self->get_referrer);
};

####################################################################################






####################################################################################

# ## SPECIAL FUNCTION
# # replaces all bibtex entries to serve the /publications/donwload/type/id instaed of the file path

sub replace_urls_to_file_serving_function{
    say "CALL: replace_urls_to_file_serving_function";

    ##
    # http://127.0.0.1:3000/publications/download/paper/4/pdf

    my $self = shift;
    my $dbh = $self->app->db;


    my @all_entries = BibSpace::Functions::EntryObj->getAll($dbh);

    my $str = "";

    for my $e (@all_entries){

        my $url_pdf = $self->url_for('download_publication_pdf', filetype => 'paper', id => $e->{id})->to_abs;
        my $url_slides = $self->url_for('download_publication', filetype => 'slides', id => $e->{id})->to_abs;



        # check if the entry has pdf
        my $pdf_path = $self->get_paper_pdf_path($e->{id}, "paper");
        if($pdf_path ne 0){ # this means that file exists locally
            if(has_bibtex_field($dbh, $e->{id}, "pdf")){
                add_field_to_bibtex_code($dbh, $e->{id}, "pdf", "$url_pdf");
                $str .= "id $e->{id}, PDF: ".$url_pdf;
                $str .= '<br/>';
            }
        }
        my $slides_path = $self->get_paper_pdf_path($e->{id}, "slides");
        if($slides_path ne 0){ # this means that file exists locally
            if(has_bibtex_field($dbh, $e->{id}, "slides")){
                add_field_to_bibtex_code($dbh, $e->{id}, "slides", "$url_slides");
                $str .= "id $e->{id}, SLI: ".$url_slides;
                $str .= '<br/>';
            }
        }
    }

    $self->flash(msg => 'The following urls are now fixed: <br/>'.$str);
    $self->redirect_to($self->get_referrer);
};
####################################################################################
sub get_paper_pdf_path{
    my $self = shift;
    my $id = shift;
    my $type = shift || "paper";

    my $upload_dir = $self->config->{upload_dir};
    $upload_dir =~ s!/*$!/!; # makes sure that there is exactly one / at the end

    my $filequery = "";
    $filequery .= "paper-".$id."."  if $type eq "paper";
    $filequery .= "slides-paper-".$id."."  if $type eq "slides";

    my $directory = $upload_dir;
    $directory .= "papers/" if $type eq "paper";
    $directory .= "slides/" if $type eq "slides";
    my $filename = undef;


    # make sure that the directories exist
    try{
        path($directory)->mkpath;
    }
    catch{
        warn "Exception: cannot create directory $directory. Msg: $_";
    };


    opendir(DIR, $directory) or die "Cannot open directory $directory :".$!;
    while (my $file = readdir(DIR)) {

        # Use a regular expression to ignore files beginning with a period
        next if ($file =~ m/^\./);
        if ($file =~ /^$filequery.*/){  # filequery contains the dot!
            say "get_paper_pdf_path MATCH $file $filequery";
            $filename = $file;
        }
    }
    closedir(DIR);
    if(!defined $filename){
        return 0;
    }

    my $file_path = $directory.$filename;
    return $file_path;
};


1;
