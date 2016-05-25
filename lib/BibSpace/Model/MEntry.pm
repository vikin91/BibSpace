#package BibSpace::Model::MEntry;

# use strict;
# use warnings;
# use BibSpace::Controller::Core;

# use Data::Dumper;
# use utf8;
# use Text::BibTeX; # parsing bib files
# use DateTime;
# use File::Slurp;
# use Time::Piece;
# use 5.010; #because of ~~
use DBI;
# use Moose;


package MEntry;
    use Moose;

    has 'id' => (is => 'rw');
    has 'bibtex_key' => (is => 'rw');

    sub all {
        my $self = shift;
        my $dbh = shift;

        my $qry = "SELECT DISTINCT id, 
                    hidden, 
                    bibtex_key, 
                    entry_type, 
                    bibtex_type, 
                    bib, 
                    html, 
                    modified_time, 
                    creation_time, 
                    month, 
                    sort_month
                FROM Entry";
        my @objs;
        my $sth = $dbh->prepare( $qry );  
        $sth->execute(); 

        while(my $row = $sth->fetchrow_hashref()) {
            my $obj = MEntry->new(id => $row->{id}, bibtex_key => $row->{bibtex_key});
                            #     year => $row->{year},
                            #     month => $row->{month},
                            #     hidden => $row->{hidden},
                            #     sort_month => $row->{sort_month},
                            #     bibtex_type => $row->{bibtex_type},
                            #     entry_type => $row->{entry_type},
                            #     bib => $row->{bib},
                            #     html => $row->{html},
                            #     ctime => $row->{creation_time},
                            #     mtime => $row->{modified_time},
                            # });
            push @objs, $obj;
        }
        return @objs;
    }

    sub get {
        my $self = shift;
        my $dbh = shift;
        my $id = shift;

        my $qry = "SELECT DISTINCT id, 
                    hidden, 
                    bibtex_key, 
                    entry_type, 
                    bibtex_type, 
                    bib, 
                    html, 
                    modified_time, 
                    creation_time, 
                    month, 
                    sort_month
                FROM Entry
                WHERE id = ?";

        my $sth = $dbh->prepare( $qry );  
        $sth->execute($self->{id}); 
        my $row = $sth->fetchrow_hashref();

        $self->id($id);
        $self->bibtex_key($row->{bibtex_key});
  }




# sub new
# {
#     my ($class, $args) = @_;
#     my $self = {id    => $args->{id}+0,
#         entry_type  => $args->{entry_type} || 'paper',
#         bibtex_key  => $args->{bibtex_key},
#         bibtex_type  => $args->{bibtex_type},
#         hidden  => $args->{hidden} || 0,
#         bib  => $args->{bib},
#         html => $args->{html} || "no HTML",
#         mtime  => $args->{mtime} || 0,
#         ctime  => $args->{ctime} || 0,
#         year  => $args->{year} || 0,
#         month  => $args->{month} || 0,
#         sort_month  => $args->{sort_month} || 0
#     };
#     return bless $self, $class;
# }
# ########################################################################################################################
# sub initFromDB{
#     my $self = shift;
#     my $dbh = shift;

#     my $qry = "SELECT DISTINCT id, hidden, bibtex_key, entry_type, bibtex_type, bib, html, modified_time, creation_time, month, sort_month
#                FROM Entry
#                WHERE id = ?";

#     my $sth = $dbh->prepare( $qry );  
#     $sth->execute($self->{id});  

  
#     my $row = $sth->fetchrow_hashref();
#     $self->{bibtex_key} = $row->{bibtex_key};
#     $self->{year} = $row->{year};
#     $self->{month} = $row->{month} || 0;
#     $self->{hidden}  = $row->{hidden} || 0;
#     $self->{sort_month} = $row->{sort_month} || 0;
#     $self->{bibtex_type} = $row->{bibtex_type} || "";
#     $self->{entry_type} = $row->{entry_type} || "paper";
#     $self->{bib} = $row->{bib} || "";
#     $self->{html} = $row->{html} || "nohtml";
#     $self->{ctime} = $row->{creation_time} || 0;
#     $self->{mtime} = $row->{modified_time} || 0;



# }
# ########################################################################################################################
# sub getByBibtexKey{
#     my $self = shift;
#     my $dbh = shift;
#     my $bibtex_key = shift;

#     my $qry = "SELECT DISTINCT id, bibtex_key
#                FROM Entry
#                WHERE bibtex_key = ?";

#     my $sth = $dbh->prepare( $qry );  
#     $sth->execute($bibtex_key);  

  
#     my $row = $sth->fetchrow_hashref();
#     my $obj = BibSpace::Functions::EntryObj->new({id => $row->{id}});
#     $obj->initFromDB($dbh);

#     return $obj;

# }
# ########################################################################################################################
# sub isHidden{
#     my $self = shift;
#     # say "id $self->{id} isHidden $self->{hidden}";
#     return $self->{hidden};
# }
# ########################################################################################################################
# sub do_toggle_hide{
#     say "CALL: EntryObj: do_toggle_hide";
#     my $self = shift;
#     my $dbh = shift;

#     $self->initFromDB($dbh);
    
#     # say "toggling hide of id $self->{id}";
#     my $h = $self->isHidden();
#     # say "h $h";

#     if($h == 1){
#         # say "unhiding (h $h)";
#         $self->unhide($dbh);
#     }
#     else{
#         # say "hiding (h $h)";
#         $self->hide($dbh);   
#     }
# }
# ########################################################################################################################
# sub hide{
#     my $self = shift;
#     my $dbh = shift;

#     # say "hiding id $self->{id}";

#     my $qry = "UPDATE Entry SET hidden=1 WHERE id = ?";
#     my $sth = $dbh->prepare( $qry );  
#     $sth->execute($self->{id});     
#     $self->{hidden} = 1;
# }
# ########################################################################################################################
# sub unhide{
#     my $self = shift;
#     my $dbh = shift;

#     # say "unhiding id $self->{id}";

#     my $qry = "UPDATE Entry SET hidden=0 WHERE id = ?";
#     my $sth = $dbh->prepare( $qry );  
#     $sth->execute($self->{id});     
#     $self->{hidden} = 0;
# }
# ########################################################################################################################
# sub isTalk{
#     my $self = shift;
#     if( $self->{entry_type} eq 'talk'){
#         return 1;
#     }
#     return 0;
# }
# ########################################################################################################################
# sub isTalkBasedOnDB{
#     my $self = shift;
#     my $dbh = shift;

#     my $qry = "SELECT entry_type FROM Entry WHERE id = ?";
#     my $sth = $dbh->prepare( $qry );  
#     $sth->execute($self->{id});  

#     my $row = $sth->fetchrow_hashref();
#     if( $row->{entry_type} eq 'talk'){
#         return 1;
#     }
#     return 0;
# }
# ########################################################################################################################
# sub isTalkBasedOnTag{
#     my $self = shift;
#     my $dbh = shift;
#     return $self->hasTag($dbh, "Talks");
# }
# ########################################################################################################################
# sub makeTalk{
#     my $self = shift;
#     my $dbh = shift;

#     my $qry = "UPDATE Entry SET entry_type='talk' WHERE id = ?";
#     my $sth = $dbh->prepare( $qry );  
#     $sth->execute($self->{id});     
# }
# ########################################################################################################################
# sub makePaper{
#     my $self = shift;
#     my $dbh = shift;

#     my $qry = "UPDATE Entry SET entry_type='paper' WHERE id = ?";
#     my $sth = $dbh->prepare( $qry );  
#     $sth->execute($self->{id});     
# }
# ########################################################################################################################
# sub fixEntryTypeBasedOnTag{
#     my $self = shift;
#     my $dbh = shift;

#     #todo: could be otpimized to minimize db calls

#     if($self->isTalkBasedOnTag($dbh) and $self->isTalkBasedOnDB($dbh)){ 
#         # say "both true: OK";
#         return 0;
#     }
#     elsif($self->isTalkBasedOnTag($dbh) and $self->isTalkBasedOnDB($dbh) ==0 ){
#         # say "tag true, DB false. Should write to DB";
#         $self->makeTalk($dbh); 
#         return 1;
#     } 
#     elsif($self->isTalkBasedOnTag($dbh)==0 and $self->isTalkBasedOnDB($dbh) ){
#         # say "tag false, DB true. do nothing";
#         return 0;
#     }
#     # say "both false. Do nothing";
#     return 0;
# }
# ########################################################################################################################
# sub setMonth{
#     my $self = shift;
#     my $month = shift;
#     my $dbh = shift;

#     my $qry = "UPDATE Entry SET month=? WHERE id = ?";
#     my $sth = $dbh->prepare( $qry );  
#     $sth->execute($month, $self->{id});     
# }
# ########################################################################################################################
# sub setSortMonth{
#     my $self = shift;
#     my $sort_month = shift;
#     my $dbh = shift;

#     my $qry = "UPDATE Entry SET sort_month=? WHERE id = ?";
#     my $sth = $dbh->prepare( $qry );  
#     $sth->execute($sort_month, $self->{id});     
# }
# ########################################################################################################################
# sub hasTag{
#     my $self = shift;
#     my $dbh = shift;
#     my $tag_to_find = shift;

#     my $tag_id = get_tag_id($dbh, $tag_to_find);
#     if($tag_id == -1){
#         $tag_id = $tag_to_find;
#     }

#     my $qry = "SELECT COUNT(*) FROM Entry_to_Tag WHERE entry_id = ? AND tag_id = ?";
#     my @ary = $dbh->selectrow_array($qry, undef, $self->{id}, $tag_id);  
#     my $key_exists = $ary[0];
#     #my $sth = $dbh->prepare( $qry );  
#     #$sth->execute($self->{id}, $tag_id); 
    

#     return 1 if $key_exists==1;
#     return 0;

# }
# ########################################################################################################################
# ########################################################################################################################
# sub getAll{
#     my $self = shift;
#     my $dbh = shift;

#     my $qry = "SELECT id, hidden, bibtex_key, entry_type, bibtex_type, bib, html, modified_time, creation_time, month, sort_month
#                 FROM Entry 
#                 WHERE bibtex_key IS NOT NULL 
#                 ORDER BY year DESC, sort_month DESC, modified_time ASC";
#     my $sth = $dbh->prepare( $qry );  
#     $sth->execute();  

#     my @objs;

#     while(my $row = $sth->fetchrow_hashref()) {
#         my $obj = BibSpace::Functions::EntryObj->new({id => $row->{id},
#                                 bibtex_key => $row->{bibtex_key},
#                                 year => $row->{year},
#                                 month => $row->{month},
#                                 hidden => $row->{hidden},
#                                 sort_month => $row->{sort_month},
#                                 bibtex_type => $row->{bibtex_type},
#                                 entry_type => $row->{entry_type},
#                                 bib => $row->{bib},
#                                 html => $row->{html},
#                                 ctime => $row->{creation_time},
#                                 mtime => $row->{modified_time},
#                             });
#         push @objs, $obj;
#     }
#     return @objs;
# }
# ########################################################################################################################
# ########################################################################################################################
# sub getFromArray{
#     my $self = shift;
#     my $dbh = shift;
#     my $arr_ref = shift; 
#     my @arr = @{$arr_ref}; 

#     my $sort = shift;
#     $sort = 1 unless defined $sort;

#     my $placeholders = "";
#     my $arr_size = scalar @arr;
#     # say "arr size: $arr_size";
#     # say "arr ".join(" ", @arr);

#     if($arr_size >= 1){
#         $placeholders = "?";
#     }

#     for (2..$arr_size){
#         $placeholders .= ",?";
#     }

#     my @objs;

#     if (scalar @arr == 0){ # if the array is empty, return also empty array of objects. The SQL query below doesnt work for empty arrays
#         return @objs;
#     }

#     if(defined $sort and $sort==1){
#         my $qry = "SELECT id, hidden, bibtex_key, entry_type, bibtex_type, bib, html, modified_time, creation_time, month, sort_month
#                 FROM Entry 
#                 WHERE bibtex_key IS NOT NULL 
#                 AND id IN (".$placeholders.")";
#         if (defined $sort and $sort==1){
#             $qry .= "ORDER BY year DESC, sort_month DESC, modified_time ASC";
#         }
#         my $sth = $dbh->prepare_cached( $qry );  
#         $sth->execute(@arr);  
#         while(my $row = $sth->fetchrow_hashref()) {
#             my $obj = BibSpace::Functions::EntryObj->new({id => $row->{id},
#                                 bibtex_key => $row->{bibtex_key},
#                                 year => $row->{year},
#                                 month => $row->{month},
#                                 hidden => $row->{hidden},
#                                 sort_month => $row->{sort_month},
#                                 bibtex_type => $row->{bibtex_type},
#                                 entry_type => $row->{entry_type},
#                                 bib => $row->{bib},
#                                 html => $row->{html},
#                                 ctime => $row->{creation_time},
#                                 mtime => $row->{modified_time},
#             });
#             push @objs, $obj;
#         }
#     }
#     else{ # TODO: pobieranie po jednym argumencie i dodawanie do tablicy objs krok po kroku aby utrzymac order!


#         my $qry = "SELECT id, hidden, bibtex_key, entry_type, bibtex_type, bib, html, modified_time, creation_time, month, sort_month
#                 FROM Entry 
#                 WHERE bibtex_key IS NOT NULL 
#                 AND id IN (".$placeholders.") ORDER BY CASE id ";

#         my $i = 1;
#         for my $eid (@arr){
#             $qry .= "WHEN $eid THEN $i ";
#             $i=$i+1;
#         }
#         $qry .= "END";
        
#         my $sth = $dbh->prepare_cached($qry);
#         $sth->execute(@arr); 

#         while(my $row = $sth->fetchrow_hashref()) {
#             my $obj = BibSpace::Functions::EntryObj->new({id => $row->{id},
#                                 bibtex_key => $row->{bibtex_key},
#                                 year => $row->{year},
#                                 month => $row->{month},
#                                 hidden => $row->{hidden},
#                                 sort_month => $row->{sort_month},
#                                 bibtex_type => $row->{bibtex_type},
#                                 entry_type => $row->{entry_type},
#                                 bib => $row->{bib},
#                                 html => $row->{html},
#                                 ctime => $row->{creation_time},
#                                 mtime => $row->{modified_time},
#             });
#             push @objs, $obj;
#         }

#     }
#     return @objs;
# }
# ########################################################################################################################
# ########################################################################################################################


# sub getByFilter{
#     my $self = shift;
#     my $dbh = shift;

#     my $mid = shift;
#     my $year = shift;
#     my $bibtex_type = shift;
#     my $entry_type = shift;
#     my $tagid = shift;
#     my $teamid = shift;
#     my $visible = shift || 0;
#     my $permalink = shift;
#     my $hidden = shift;

#     # say "   mid $mid
#     #         year $year
#     #         bibtex_type $bibtex_type
#     #         entry_type $entry_type
#     #         tagid $tagid
#     #         teamid $teamid
#     #         visible $visible
#     #         permalink $permalink
#     #         hidden $hidden
#     # ";

#     my @params;

#     my $qry = "SELECT DISTINCT Entry.bibtex_key, Entry.hidden, Entry.id, bib, html, Entry.bibtex_type, Entry.entry_type, Entry.year, Entry.month, Entry.sort_month, modified_time, creation_time
#                 FROM Entry
#                 LEFT JOIN Exceptions_Entry_to_Team  ON Entry.id = Exceptions_Entry_to_Team.entry_id
#                 LEFT JOIN Entry_to_Author ON Entry.id = Entry_to_Author.entry_id 
#                 LEFT JOIN Author ON Entry_to_Author.author_id = Author.id 
#                 LEFT JOIN Author_to_Team ON Entry_to_Author.author_id = Author_to_Team.author_id 
#                 LEFT JOIN OurType_to_Type ON OurType_to_Type.bibtex_type = Entry.bibtex_type 
#                 LEFT JOIN Entry_to_Tag ON Entry.id = Entry_to_Tag.entry_id 
#                 LEFT JOIN Tag ON Tag.id = Entry_to_Tag.tag_id 
#                 WHERE Entry.bibtex_key IS NOT NULL ";
#     if(defined $hidden){
#         push @params, $hidden;
#         $qry .= "AND Entry.hidden=? ";
#     }
#     if(defined $visible and $visible eq '1'){
#         $qry .= "AND Author.display=1 ";
#     }
#     if(defined $mid){
#         push @params, $mid;
#         $qry .= "AND Entry_to_Author.author_id=? ";
#     }
#     if(defined $year){
#         push @params, $year;
#         $qry .= "AND Entry.year=? ";
#     }
#     if(defined $bibtex_type){
#         push @params, $bibtex_type;
#         $qry .= "AND OurType_to_Type.our_type=? ";
#     }
#     if(defined $entry_type){
#         push @params, $entry_type;
#         $qry .= "AND Entry.entry_type=? ";
#     }
#     if(defined $teamid){
#         push @params, $teamid;
#         push @params, $teamid;
#         # push @params, $teamid;
#         # $qry .= "AND Exceptions_Entry_to_Team.team_id=?  ";
#         $qry .= "AND ((Exceptions_Entry_to_Team.team_id=? ) OR (Author_to_Team.team_id=? AND start <= Entry.year  AND (stop >= Entry.year OR stop = 0))) ";
#     }
#     if(defined $tagid){
#         push @params, $tagid;
#         $qry .= "AND Entry_to_Tag.tag_id LIKE ?";
#     }
#     if(defined $permalink){
#         push @params, $permalink;
#         $qry .= "AND Tag.permalink LIKE ?";
#     } 
#     $qry .= "ORDER BY Entry.year DESC, Entry.sort_month DESC, Entry.creation_time DESC, Entry.modified_time DESC, Entry.bibtex_key ASC";

#     # print $qry."\n";

#     my $sth = $dbh->prepare_cached( $qry );  
#     $sth->execute(@params); 

#     my @objs;

#     while(my $row = $sth->fetchrow_hashref()) {
#         my $obj = BibSpace::Functions::EntryObj->new({id => $row->{id},
#                             bibtex_key => $row->{bibtex_key},
#                             year => $row->{year},
#                             month => $row->{month},
#                             hidden => $row->{hidden},
#                             sort_month => $row->{sort_month},
#                             bibtex_type => $row->{bibtex_type},
#                             entry_type => $row->{entry_type},
#                             bib => $row->{bib},
#                             html => $row->{html},
#                             ctime => $row->{creation_time},
#                             mtime => $row->{modified_time},
#         });
#         push @objs, $obj;
#     }

#     return @objs;
# }
# ########################################################################################################################
# ########################################################################################################################


# sub getByFilterNoTalks{
#     my $self = shift;
#     my $dbh = shift;

#     my $mid = shift;
#     my $year = shift;
#     my $type = shift;
#     my $tagid = shift;
#     my $teamid = shift;
#     my $visible = shift || 0;
#     my $permalink = shift;
#     my $hidden = shift;

#     my @params;
#     # AND Tag.name <> 'Talks' 
#     my $qry = "SELECT DISTINCT Entry.bibtex_key, Entry.hidden, Entry.id, bib, html, Entry.bibtex_type, Entry.entry_type, Entry.year, Entry.month, Entry.sort_month, modified_time, creation_time
#                 FROM Entry
#                 LEFT JOIN Exceptions_Entry_to_Team  ON Entry.id = Exceptions_Entry_to_Team.entry_id
#                 LEFT JOIN Entry_to_Author ON Entry.id = Entry_to_Author.entry_id 
#                 LEFT JOIN Author ON Entry_to_Author.author_id = Author.id 
#                 LEFT JOIN Author_to_Team ON Entry_to_Author.author_id = Author_to_Team.author_id 
#                 LEFT JOIN OurType_to_Type ON OurType_to_Type.bibtex_type = Entry.bibtex_type 
#                 LEFT JOIN Entry_to_Tag ON Entry.id = Entry_to_Tag.entry_id 
#                 LEFT JOIN Tag ON Tag.id = Entry_to_Tag.tag_id 
#                 WHERE Entry.bibtex_key IS NOT NULL 
#                 AND Entry.entry_type == 'paper' ";
#     if(defined $hidden){
#         push @params, $hidden;
#         $qry .= "AND Entry.hidden=? ";
#     }
#     if(defined $visible and $visible eq '1'){
#         $qry .= "AND Author.display=1 ";
#     }
#     if(defined $mid){
#         push @params, $mid;
#         $qry .= "AND Entry_to_Author.author_id=? ";
#     }
#     if(defined $year){
#         push @params, $year;
#         $qry .= "AND Entry.year=? ";
#     }
#     if(defined $type){
#         push @params, $type;
#         $qry .= "AND OurType_to_Type.our_type=? ";
#     }
#     if(defined $teamid){
#         push @params, $teamid;
#         push @params, $teamid;
#         # push @params, $teamid;
#         # $qry .= "AND Exceptions_Entry_to_Team.team_id=?  ";
#         $qry .= "AND ((Exceptions_Entry_to_Team.team_id=? ) OR (Author_to_Team.team_id=? AND start <= Entry.year  AND (stop >= Entry.year OR stop = 0))) ";
#     }
#     if(defined $tagid){
#         push @params, $tagid;
#         $qry .= "AND Entry_to_Tag.tag_id LIKE ?";
#     }
#     if(defined $permalink){
#         push @params, $permalink;
#         $qry .= "AND Tag.permalink LIKE ?";
#     } 
#     $qry .= "ORDER BY Entry.year DESC, Entry.sort_month DESC, Entry.creation_time DESC, Entry.modified_time DESC, Entry.bibtex_key ASC";

#     # print $qry."\n";

#     my $sth = $dbh->prepare_cached( $qry );  
#     $sth->execute(@params); 

#     my @objs;

#     while(my $row = $sth->fetchrow_hashref()) {
#         my $obj = BibSpace::Functions::EntryObj->new({id => $row->{id},
#                             bibtex_key => $row->{bibtex_key},
#                             year => $row->{year},
#                             month => $row->{month},
#                             hidden => $row->{hidden},
#                             sort_month => $row->{sort_month},
#                             bibtex_type => $row->{bibtex_type},
#                             entry_type => $row->{entry_type},
#                             bib => $row->{bib},
#                             html => $row->{html},
#                             ctime => $row->{creation_time},
#                             mtime => $row->{modified_time},
#         });
#         push @objs, $obj;
#     }

#     return @objs;
# }

########################################################################################################################

1;