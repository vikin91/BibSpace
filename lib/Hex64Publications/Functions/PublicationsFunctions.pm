package Hex64Publications::Functions::PublicationsFunctions;

use Hex64Publications::Controller::Core;

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
    get_html_for_entry_id
    assign_entry_to_existing_authors_no_add
    postprocess_updated_entry
    after_edit_process_month
    after_edit_process_authors
    generate_html_for_key
    generate_html_for_id
    getPublicationsByFilter
    get_html_for_bib
    tune_html
    create_user_id
    );

our $bibtex2html_tmp_dir = "./tmp";

##########################################################################
sub get_html_for_entry_id{
   my $dbh = shift;
   my $eid = shift;

   my $eobj = $dbh->resultset('Entry')->search({'id' => $eid})->first;

   my $html = $eobj->html;
   my $key = $eobj->bibtex_key;
   my $type = $eobj->bibtex_type;


   return nohtml($key, $type) unless defined $html;
   return $html;
}
##################################################################
sub assign_entry_to_existing_authors_no_add{
    my $dbh = shift;
    my $entry = shift;
    

    my $entry_key = $entry->key;
    my $key = $entry->key;
    my $eid = $dbh->resultset('Entry')->search({ bibtex_key => $entry_key })->get_column('id')->first || 0;

    $dbh->resultset('EntryToAuthor')->search({ entry_id => $eid })->delete_all;   
    

    my @names;
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
        my $uid = create_user_id($name);
        my $aid = $dbh->resultset('Author')->search({ uid => $uid })->get_column('id')->first || 0;
        my $mid = $dbh->resultset('Author')->search({ id => $aid })->get_column('master_id')->first || 0;

        if(defined $mid and $mid != 0){ #added 5.05.2015 - may skip some authors!
            $dbh->resultset('EntryToAuthor')->find_or_create({author_id => $mid, entry_id => $eid});  
            # my $sth3 = $dbh->prepare('INSERT IGNORE INTO Entry_to_Author(author_id, entry_id) VALUES(?, ?)');
        }
    }
    # $dbh->commit; #end transaction
}
##################################################################
sub postprocess_updated_entry{
    say "CALL: PublicationsFunctions::postprocess_updated_entry";  # procesing an entry that was edited - allows to change bibtex key - eid remains untouched
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

    $dbh->resultset('Entry')->search({ id => $eid })->update({
            title => $title, 
            bibtex_key => $key, 
            bib => $content,
            year => $year,
            bibtex_type => $type,
            abstract => $abstract,
            need_html_regen => 1,
            creation_time => \"current_timestamp",
            modified_time => \"current_timestamp"
            });

    $exit_code = 1;
    after_edit_process_authors($dbh, $entry);
    # after_edit_process_tags($dbh, $entry); 
    generate_html_for_key($dbh, $key);
    after_edit_process_month($dbh, $entry);

    my ($html, $htmlbib) = get_html_for_bib($content, $key);
    $preview_html = $html;

    return $exit_code, $preview_html;
};

##########################################################################################

sub after_edit_process_month{

    my $dbh = shift;
    my $entry = shift;

    my $entry_key = $entry->key;
    my $key = $entry_key;
    my $eid = $dbh->resultset('Entry')->search({ bibtex_key => $entry_key })->get_column('id')->first || 0;


    if($entry->exists('month')){
        my $month_str = $entry->get('month');
        my $month_numeric = get_month_numeric($month_str);
        $dbh->resultset('Entry')->search({ id => $eid })->update({month => $month_numeric, sort_month => $month_numeric});
    }
};
##################################################################

sub after_edit_process_authors{
    my $dbh = shift;
    my $entry = shift;

    my $entry_key = $entry->key;
    my $key = $entry->key;
    my $eid = $dbh->resultset('Entry')->search({ bibtex_key => $entry_key })->get_column('id')->first || 0;

    if ($eid > 0){
        $dbh->resultset('EntryToAuthor')->search({ entry_id => $eid })->delete_all;    
    }

    my @names;

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

    # authors need to be added to have their ids!!
    for my $name (@names){
        my $uid = create_user_id($name);
        my $aid = $dbh->resultset('Author')->search({ uid => $uid })->get_column('id')->first || 0;

        if($aid == 0){
            $dbh->resultset('Author')->find_or_create({uid => $uid, master => $uid});  
            $aid = $dbh->resultset('Author')->search({ uid => $uid })->get_column('id')->first || 0;
        }


        my $mid = $dbh->resultset('Author')->search({ id => $aid })->get_column('master_id')->first || $aid;
        # if author was not in the uid2muid config, then mid = aid
        $dbh->resultset('Author')->search({ id => $aid })->update({master_id => $mid});
    }

    assign_entry_to_existing_authors_no_add($dbh, $entry);

    # for my $name (@names){
    #     my $uid = create_user_id($name);
    #     my $aid = $dbh->resultset('Author')->search({ uid => $uid })->get_column('id')->first || 0;
    #     my $mid = $dbh->resultset('Author')->search({ id => $aid })->get_column('master_id')->first || 0;

    #     if(defined $mid and $mid != -1){ #added 5.05.2015 - may skip some authors!
    #         $dbh->resultset('EntryToAuthor')->find_or_create({author_id => $mid, entry_id => $eid});  
    #         # my $sth3 = $dbh->prepare('INSERT IGNORE INTO Entry_to_Author(author_id, entry_id) VALUES(?, ?)');
    #     }
    # }
}
################################################################################
################################################################################
sub generate_html_for_key{
   my $dbh = shift;
   my $key = shift;

   my $eid = $dbh->resultset('Entry')->search({ bibtex_key => $key })->get_column('id')->first || 0;
   return generate_html_for_id($dbh, $eid);
};

################################################################################
sub generate_html_for_id{
   my $dbh = shift;
   my $eid = shift;

   my $rs = $dbh->resultset('Entry')->search({ id => $eid });
   my $bibtex_key = $rs->get_column('bibtex_key')->first;
   my $bib = $rs->get_column('bib')->first;
    
   my ($html, $htmlbib) = get_html_for_bib($bib, $bibtex_key);

   # this triggers: modified_time=CURRENT_TIMESTAMP  # minor severity

   $dbh->resultset('Entry')->search({ id => $eid })->update({
            html => $html, 
            html_bib => $htmlbib, 
            need_html_regen => 0
            });
};
########################################################################################################################

sub getPublicationsByFilter{
    
    my $dbh = shift;

    my $mid = shift;
    my $year = shift;
    my $bibtex_type = shift;
    my $entry_type = shift;
    my $tagid = shift;
    my $teamid = shift;
    my $visible = shift || 0;
    my $permalink = shift;
    my $hidden = shift;

    say "   =====
            mid $mid
            year $year
            bibtex_type $bibtex_type
            entry_type $entry_type
            tagid $tagid
            teamid $teamid
            visible $visible
            permalink $permalink
            hidden $hidden
    ";

    # search({ 
    #     'hidden' => $hidden,
    #     'display' => 1
    # })


    # __PACKAGE__->many_to_many("authors", "entry_to_authors", "author");
    my $rs = $dbh->resultset('Entry')->search(
    {},
    { 
        join => {   'exceptions_entry_to_teams' => 'team',
                    'entry_to_authors' => {'author' => 'author_to_teams'}, 
                    'entries_to_tag' => 'tag',
                    # 'bibtex_type' => 'OurType_to_Type.bibtex_type'
                    }, 
        # columns => [{ 'd_year' => { distinct => 'me.bibtex_key' } }, 'hidden', 'id', 'bibtex_type', 'entry_type', 'year', 'month', 'sort_month', 'modified_time', 'creation_time'],
        columns => [{ 'bibtex_key' => { distinct => 'me.bibtex_key' } }, 
        'id', 'entry_type', 'bibtex_type', 'bib', 'html', 'html_bib', 'abstract', 'title', 'hidden', 'year', 'month', 'sort_month', 'teams_str', 'people_str', 'tags_str', 'creation_time', 'modified_time', 'need_html_regen'],
        order_by => { '-desc' => [qw/year sort_month creation_time modified_time/] }
        # order_by => {'-asc' => ['bibtex_key'] },
    });


    $rs = $rs->search({'hidden' => $hidden}) if defined $hidden;
    $rs = $rs->search({'display' => 1}) if defined $visible and $visible eq '1';
    $rs = $rs->search({'Author.master_id' => $mid}) if defined $mid;
    $rs = $rs->search({'year' => $year}) if defined $year;
    $rs = $rs->search({'OurType_to_Type.our_type' => $bibtex_type}) if defined $bibtex_type;
    $rs = $rs->search({'entry_type' => $entry_type}) if defined $entry_type;

    # # (Exceptions_Entry_to_Team.team_id=? ) OR (Author_to_Team.team_id=? AND start <= Entry.year  AND (stop >= Entry.year OR stop = 0))
    $rs = $rs->search({
        '-or' => [
            'exceptions_entry_to_teams.team_id' => $teamid,
            '-and' => [
                'author_to_teams.team_id' => $teamid,
                'author_to_teams.start' => {'<=', \'me.year'},
                '-or' => [
                    'author_to_teams.stop' => 0,
                    'author_to_teams.stop' => {'>=', \'me.year'},
                ]
            ]
        ]
    }) if defined $teamid;
    
    # $rs = $rs->search({
    #     '-and' => [
    #         'author_to_teams.team_id' => $teamid,
    #         'author_to_teams.start' => {'<=', 'me.year'},
    #     ]
    # }) if defined $teamid;

    $rs = $rs->search({'Entry_to_Tag.tag_id' => {'like', $tagid} }) if defined $tagid;
    $rs = $rs->search({'Tag.permalink' => {'like', $permalink} }) if defined $permalink;

    my @arr = $rs->all;


    # ORDER BY Entry.year DESC, Entry.sort_month DESC, Entry.creation_time DESC, Entry.modified_time DESC, Entry.bibtex_key ASC

    # my @params;

    # my $qry = "SELECT DISTINCT Entry.bibtex_key, Entry.hidden, Entry.id, bib, html, Entry.bibtex_type, Entry.entry_type, Entry.year, Entry.month, Entry.sort_month, modified_time, creation_time
    #             FROM Entry
    #             # LEFT JOIN Exceptions_Entry_to_Team  ON Entry.id = Exceptions_Entry_to_Team.entry_id
    #             # LEFT JOIN Entry_to_Author ON Entry.id = Entry_to_Author.entry_id 
    #             # LEFT JOIN Author ON Entry_to_Author.author_id = Author.id 

    #             # LEFT JOIN Author_to_Team ON Entry_to_Author.author_id = Author_to_Team.author_id 
    #             LEFT JOIN OurType_to_Type ON OurType_to_Type.bibtex_type = Entry.bibtex_type 
    #             # LEFT JOIN Entry_to_Tag ON Entry.id = Entry_to_Tag.entry_id 
    #             # LEFT JOIN Tag ON Tag.id = Entry_to_Tag.tag_id 
    #             WHERE Entry.bibtex_key IS NOT NULL ";
    # if(defined $tagid){
    #     push @params, $tagid;
    #     $qry .= "AND Entry_to_Tag.tag_id LIKE ?";
    # }
    # if(defined $permalink){
    #     push @params, $permalink;
    #     $qry .= "AND Tag.permalink LIKE ?";
    # } 
    # $qry .= "ORDER BY Entry.year DESC, Entry.sort_month DESC, Entry.creation_time DESC, Entry.modified_time DESC, Entry.bibtex_key ASC";


    return @arr;
}
########################################################################################################################
################################################################################

sub get_html_for_bib{
   my $bib_str = shift;
   my $key = shift || 'no-bibtex-key';

   # fix for the coding problems with mysql
   $bib_str =~ s/J''urgen/J\\''urgen/g;
   $bib_str =~ s/''a/\\''a/g;
   $bib_str =~ s/''o/\\''o/g;
   $bib_str =~ s/''e/\\''e/g;

   mkdir($bibtex2html_tmp_dir, 0777);

   my $out_file = $bibtex2html_tmp_dir."/out";
   my $outhtml = $out_file.".html";

   my $out_bibhtml = $out_file."_bib.html";
   my $databib = $bibtex2html_tmp_dir."/data.bib";

   open (MYFILE, '>'.$databib);
   print MYFILE $bib_str;
   close (MYFILE); 

   open (my $fh, '>'.$outhtml) or return nohtml($key, '?', $bib_str), $bib_str; #die "cannot touch $outhtml";
   close($fh);
   open ($fh, '>'.$out_bibhtml) or return $bib_str, $bib_str; #die "cannot touch $out_bibhtml";
   close($fh);

    my $cwd = getcwd();

   

   # -nokeys  --- no number in brackets by entry
   # -nodoc   --- dont generate document but a part of it - to omit html head body headers
   # -single  --- does not provide links to pdf, html and bib but merges bib with html output
   my $bibtex2html_command = "bibtex2html -s ".$cwd."/descartes2 -nf slides slides -d -r --revkeys -no-keywords -no-header -nokeys --nodoc  -no-footer -o ".$out_file." $databib >/dev/null";
   # my $tune_html_command = "./tuneSingleHtmlFile.sh out.html";

   # print "COMMAND: $bibtex2html_command\n";
   my $syscommand = "export TMPDIR=".$bibtex2html_tmp_dir." && ".$bibtex2html_command;
   # say "=====\n";
   # say "cwd: ".$cwd."\n";
   # say $syscommand;
   # say "=====\n";
   system($syscommand);
   



   my $html =     read_file($outhtml);
   my $htmlbib =  read_file($out_bibhtml);

   $htmlbib =~ s/<h1>data.bib<\/h1>//g;

   $htmlbib =~ s/<a href="$outhtml#(.*)">(.*)<\/a>/$1/g;
   $htmlbib =~ s/<a href=/<a target="blank" href=/g;

   $html = tune_html($html, $key, $htmlbib);
   

   
   # now the output jest w out.html i out_bib.html

   return $html, $htmlbib;
};

################################################################################

sub tune_html{
   my $s = shift;
   my $key = shift;
   my $htmlbib = shift || "";

   # my $DIR="/var/www/html/publications-new";
   # my $DIRBASE="/var/www/html/";
   # #edit those two above always together!
   # my $WEBPAGEPREFIX="http://sdqweb.ipd.kit.edu/";
   # my $WEBPAGEPREFIXLONG="http://sdqweb.ipd.kit.edu/publications";

   # BASH CODE:
   # # replace links
   # sed -e s_"$DIR"_"$WEBPAGEPREFIXLONG"_g $FILE > $TMP && mv -f $TMP $FILE
   # # changes /var/www/html/publications-new to http://sdqweb.ipd.kit.edu/publications_new
   # $s =~ s/"$DIR"/"$WEBPAGEPREFIXLONG"/g;

   $s =~ s/out_bib.html#(.*)/\/publications\/get\/bibtex\/$1/g;
   
   # FROM .pdf">.pdf</a>&nbsp;]
   # TO   .pdf" target="blank">.pdf</a>&nbsp;]
   # $s =~ s/.pdf">/.pdf" target="blank">/g;


   $s =~ s/>.pdf<\/a>/ target="blank">.pdf<\/a>/g;
   $s =~ s/>slides<\/a>/ target="blank">slides<\/a>/g;
   $s =~ s/>http<\/a>/ target="blank">http<\/a>/g;
   $s =~ s/>.http<\/a>/ target="blank">http<\/a>/g;
   $s =~ s/>DOI<\/a>/ target="blank">DOI<\/a>/g;

   $s =~ s/<a (.*)>bib<\/a>/BIB_LINK_ID/g;
   
   

   # # for old system use:
   # #for x in `find $DIR -name "*.html"`;do sed 's_\[\&nbsp;<a href=\"_\[\&nbsp;<a href=\"http:\/\/sdqweb.ipd.kit.edu\/publications\/_g' $x > $TMP; mv $TMP $x; done

   # # replace &lt; and &gt; b< '<' and '>' in Samuel's files.
   # sed 's_\&lt;_<_g' $FILE > $TMP && mv -f $TMP $FILE
   # sed 's_\&gt;_>_g' $FILE > $TMP && mv -f $TMP $FILE
   $s =~ s/\&lt;/</g;
   $s =~ s/\&gt;/>/g;


   # ### insert JavaScript hrefs to show/hide abstracts on click ###
   # #replaces every newline command with <NeueZeile> to insert the Abstract link in the next step properly 
   # perl -p -i -e "s/\n/<NeueZeile>/g" $FILE
   $s =~ s/\n/<NeueZeile>/g;

   # #inserts the link to javascript
   # sed 's_\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">_\&nbsp;\|\&nbsp;<a href=\"javascript:showAbstract(this);\" onclick=\"showAbstract(this)\">Abstract</a><noscript> (JavaScript required!)</noscript>\&nbsp;\]<div style=\"display:none;\"><blockquote id=\"abstractBQ\">_g' $FILE > $TMP && mv -f $TMP $FILE
   # sed 's_</font></blockquote><NeueZeile><p>_</blockquote></div>_g' $FILE > $TMP && mv -f $TMP $FILE
   # $s =~ s/\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">/\&nbsp;\|\&nbsp;<a href=\"javascript:showAbstract(this);\" onclick=\"showAbstract(this)\">Abstract<\/a><noscript> (JavaScript required!)<\/noscript>\&nbsp;\]<div style=\"display:none;\"><blockquote id=\"abstractBQ\">/g;

   
   #$s =~ s/\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">/\&nbsp;\|\&nbsp;<a class="abstract-a" onclick=\"showAbstract(\'$key\')\">Abstract<\/a>\&nbsp; \]<div id=\"$key\" style=\"display:none;\"><blockquote id=\"abstractBQ\">/g;
   $s =~ s/\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">/\&nbsp;\|\&nbsp;<a class="abstract-a" onclick=\"showAbstract(\'$key\')\">Abstract<\/a>\&nbsp; \] <div id=\"$key\" style=\"display:none;\"><blockquote id=\"abstractBQ\" style=\"text-align: justify;\">/g;
   $s =~ s/<\/font><\/blockquote><NeueZeile><p>/<\/blockquote><\/div>/g;

   #inserting bib DIV marker
   $s =~ s/\]/\] BIB_DIV_ID/g;

   $key =~ s/\./_/g;   

   # handling BIB_DIV_ID marker
   $s =~ s/BIB_DIV_ID/<div id="bib-of-$key" class="inline-bib" style=\"display:none;\">$htmlbib<\/div>/g;
   # handling BIB_LINK_ID marker
   $s =~ s/BIB_LINK_ID/<a class="abstract-a" onclick=\"showAbstract(\'bib-of-$key\')\">bib<\/a>/g;

   # #undo the <NeueZeile> insertions
   # perl -p -i -e "s/<NeueZeile>/\n/g" $FILE
   $s =~ s/<NeueZeile>/\n/g;
   
   $s =~ s/(\s)\s+/$1/g;  # !!! TEST

   $s =~ s/<p>//g;
   $s =~ s/<\/p>//g;


   $s;
}

################################################################################
sub create_user_id {
   my ($name) = @_;

   my @first_arr = $name->part('first');
   my $first = join(' ', @first_arr);
   #print "$first\n";

   my @von_arr = $name->part ('von');
   my $von = $von_arr[0];
   #print "$von\n" if defined $von;

   my @last_arr = $name->part ('last');
   my $last = $last_arr[0];
   #print "$last\n";

   my @jr_arr = $name->part ('jr');
   my $jr = $jr_arr[0];
   #print "$jr\n";
   
   my $userID;
   $userID.=$von if defined $von;
   $userID.=$last;
   $userID.=$first if defined $first;
   $userID.=$jr if defined $jr;

   $userID =~ s/\\k\{a\}/a/g;   # makes \k{a} -> a
   $userID =~ s/\\l/l/g;   # makes \l -> l
   $userID =~ s/\\r\{u\}/u/g;   # makes \r{u} -> u # FIXME: make sure that the letter is caught
   # $userID =~ s/\\r{u}/u/g;   # makes \r{u} -> u # the same but not escaped 

   $userID =~ s/\{(.)\}/$1/g;   # makes {x} -> x
   $userID =~ s/\{\\\"(.)\}/$1e/g;   # makes {\"x} -> xe
   $userID =~ s/\{\"(.)\}/$1e/g;   # makes {"x} -> xe
   $userID =~ s/\\\"(.)/$1e/g;   # makes \"{x} -> xe
   $userID =~ s/\{\\\'(.)\}/$1/g;   # makes {\'x} -> x
   $userID =~ s/\\\'(.)/$1/g;   # makes \'x -> x
   $userID =~ s/\'\'(.)/$1/g;   # makes ''x -> x
   $userID =~ s/\"(.)/$1e/g;   # makes "x -> xe
   $userID =~ s/\{\\ss\}/ss/g;   # makes {\ss}-> ss
   $userID =~ s/\{(.*)\}/$1/g;   # makes {abc..def}-> abc..def
   $userID =~ s/\\\^(.)(.)/$1$2/g;   # makes \^xx-> xx
   # I am not sure if the next one is necessary
   $userID =~ s/\\\^(.)/$1/g;   # makes \^x-> x 
   $userID =~ s/\\\~(.)/$1/g;   # makes \~x-> x
   $userID =~ s/\\//g;   # removes \ 

   $userID =~ s/\{//g;   # removes {
   $userID =~ s/\}//g;   # removes }

   $userID =~ s/\(.*\)//g;   # removes everything between the brackets and the brackets also
   
   # print "$userID \n";
   return $userID;
}


1;