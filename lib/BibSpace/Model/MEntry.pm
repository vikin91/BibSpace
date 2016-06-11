#package BibSpace::Model::MEntry;

use strict;
use warnings;

# use BibSpace::Functions::FPublications; # there should be really no call to this module. All calls should be moved to a new module






package MEntry;
    use Data::Dumper;
    use utf8;
    use Text::BibTeX; # parsing bib files
    use 5.010; #because of ~~ and say
    use DBI;
    use Moose;

   has 'id' => (is => 'rw'); 
   has 'entry_type' => (is => 'rw', default => 'paper'); 
   has 'bibtex_key' => (is => 'rw');
   has 'bibtex_type' => (is => 'rw');
   has 'bib' => (is => 'rw', isa => 'Str'); 
   has 'html' => (is => 'rw'); 
   has 'html_bib' => (is => 'rw'); 
   has 'abstract' => (is => 'rw'); 
   has 'title' => (is => 'rw'); 
   has 'hidden' => (is => 'rw', default => 0); 
   has 'year' => (is => 'rw'); 
   has 'month' => (is => 'rw'); 
   has 'sort_month' => (is => 'rw'); 
   has 'teams_str' => (is => 'rw'); 
   has 'people_str' => (is => 'rw'); 
   has 'tags_str' => (is => 'rw'); 
   has 'creation_time' => (is => 'rw'); 
   has 'modified_time' => (is => 'rw'); 
   has 'need_html_regen' => (is => 'rw', default => '1'); 

####################################################################################
    sub static_all {
        my $self = shift;
        my $dbh = shift;

        my $qry = "SELECT DISTINCT id,
                    entry_type,
                    bibtex_key,
                    bibtex_type,
                    bib,
                    html,
                    html_bib,
                    abstract,
                    title,
                    hidden,
                    year,
                    month,
                    sort_month,
                    teams_str,
                    people_str,
                    tags_str,
                    creation_time,
                    modified_time,
                    need_html_regen
                FROM Entry";
        my @objs;
        my $sth = $dbh->prepare( $qry );
        $sth->execute();

        while(my $row = $sth->fetchrow_hashref()) {
            my $obj = MEntry->new(
                                  id => $row->{id},
                                  entry_type => $row->{entry_type},
                                  bibtex_key => $row->{bibtex_key},
                                  bibtex_type => $row->{bibtex_type},
                                  bib => $row->{bib},
                                  html => $row->{html},
                                  html_bib => $row->{html_bib},
                                  abstract => $row->{abstract},
                                  title => $row->{title},
                                  hidden => $row->{hidden},
                                  year => $row->{year},
                                  month => $row->{month},
                                  sort_month => $row->{sort_month},
                                  teams_str => $row->{teams_str},
                                  people_str => $row->{people_str},
                                  tags_str => $row->{tags_str},
                                  creation_time => $row->{creation_time},
                                  modified_time => $row->{modified_time},
                                  need_html_regen => $row->{need_html_regen},
                            );
            push @objs, $obj;
        }
        return @objs;
    }
####################################################################################
sub static_get {
  my $self = shift;
  my $dbh = shift;
  my $id = shift;

  my $qry = "SELECT DISTINCT id,
              entry_type,
              bibtex_key,
              bibtex_type,
              bib,
              html,
              html_bib,
              abstract,
              title,
              hidden,
              year,
              month,
              sort_month,
              teams_str,
              people_str,
              tags_str,
              creation_time,
              modified_time,
              need_html_regen
          FROM Entry
          WHERE id = ?";

  my $sth = $dbh->prepare( $qry );
  $sth->execute($id);
  my $row = $sth->fetchrow_hashref();

  if(!defined $row){
    return undef;
  }

  my $e = MEntry->new();
  $e->{id} = $id;
  $e->{entry_type} = $row->{entry_type};
  $e->{bibtex_key} = $row->{bibtex_key};
  $e->{bibtex_type} = $row->{bibtex_type};
  $e->{bib} = $row->{bib};
  $e->{html} = $row->{html};
  $e->{html_bib} = $row->{html_bib};
  $e->{abstract} = $row->{abstract};
  $e->{title} = $row->{title};
  $e->{hidden} = $row->{hidden};
  $e->{year} = $row->{year};
  $e->{month} = $row->{month};
  $e->{sort_month} = $row->{sort_month};
  $e->{teams_str} = $row->{teams_str};
  $e->{people_str} = $row->{people_str};
  $e->{tags_str} = $row->{tags_str};
  $e->{creation_time} = $row->{creation_time};
  $e->{modified_time} = $row->{modified_time};
  $e->{need_html_regen} = $row->{need_html_regen};
  return $e;
}
####################################################################################
sub update {
  my $self = shift;
  my $dbh = shift;

  my $result = "";


  if(!defined $self->{id}){
      say "Cannot update. Entry id not set. The entry may not exist in the DB. Returning -1";
      return -1;
  }

  my $qry = "UPDATE Entry SET
                entry_type=?,
                bibtex_key=?,
                bibtex_type=?,
                bib=?,
                html=?,
                html_bib=?,
                abstract=?,
                title=?,
                hidden=?,
                year=?,
                month=?,
                sort_month=?,
                teams_str=?,
                people_str=?,
                tags_str=?,
                creation_time=?,
                modified_time=CURRENT_TIMESTAMP,
                need_html_regen=?
            WHERE id = ?";
  my $sth = $dbh->prepare( $qry );
  $result = $sth->execute(
            $self->{entry_type},
            $self->{bibtex_key},
            $self->{bibtex_type},
            $self->{bib},
            $self->{html},
            $self->{html_bib},
            $self->{abstract},
            $self->{title},
            $self->{hidden},
            $self->{year},
            $self->{month},
            $self->{sort_month},
            $self->{teams_str},
            $self->{people_str},
            $self->{tags_str},
            $self->{creation_time},
            # $self->{modified_time},
            $self->{need_html_regen},
            $self->{id}
            );
  $sth->finish();
  return $result;
}
####################################################################################
sub insert {
  my $self = shift;
  my $dbh = shift;

  my $result = "";


  my $qry = "
    INSERT INTO Entry(
    entry_type,
    bibtex_key,
    bibtex_type,
    bib,
    html,
    html_bib,
    abstract,
    title,
    hidden,
    year,
    month,
    sort_month,
    teams_str,
    people_str,
    tags_str,
    creation_time,
    modified_time,
    need_html_regen
    ) 
    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,?);";
    my $sth = $dbh->prepare( $qry );
    $result = $sth->execute(
            $self->{entry_type},
            $self->{bibtex_key},
            $self->{bibtex_type},
            $self->{bib},
            $self->{html},
            $self->{html_bib},
            $self->{abstract},
            $self->{title},
            $self->{hidden},
            $self->{year},
            $self->{month},
            $self->{sort_month},
            $self->{teams_str},
            $self->{people_str},
            $self->{tags_str},
            # $self->{creation_time},
            # $self->{modified_time},
            $self->{need_html_regen},
            );
  my $inserted_id = $dbh->last_insert_id('', '', 'Entry', '');
  $self->{id} = $inserted_id;
  # say "Mentry insert. inserted_id = $inserted_id";
  $sth->finish();
  return $inserted_id; #or $result;
}
####################################################################################
sub save {
  my $self = shift;
  my $dbh = shift;

  my $result = "";


  if(!defined $self->{id} or $self->{id} <= 0){
    my $inserted_id = $self->insert($dbh);
    $self->{id} = $inserted_id;
    # say "Mentry save: inserting. inserted_id = ".$self->{id};
    return $inserted_id;
  }
  elsif(defined $self->{id} and $self->{id} > 0){
    # say "Mentry save: updating ID = ".$self->{id};
    return $self->update($dbh);
  }
  else{
    warn "Mentry save: cannot either insert nor update :( ID = ".$self->{id};
  }
}
####################################################################################
sub delete {
  my $self = shift;
  my $dbh = shift;


  my $qry = "DELETE FROM Entry WHERE id=?;";
  my $sth = $dbh->prepare( $qry );
  my $result = $sth->execute($self->{id});

  return $result;
}
####################################################################################
sub is_hidden {
  my $self = shift;
  return $self->{hidden} == 1;
}; 
####################################################################################
sub hide {
  my $self = shift;
  my $dbh = shift;

  $self->{hidden} = 1;
  $self->save($dbh);
}; 
####################################################################################
sub unhide {
  my $self = shift;
  my $dbh = shift;

  $self->{hidden} = 0;
  $self->save($dbh);
}; 
####################################################################################
sub toggle_hide {
  my $self = shift;
  my $dbh = shift;

  if($self->{hidden} == 1){
    $self->unhide($dbh);
  }
  else{
    $self->hide($dbh); 
  }
}; 
####################################################################################
sub make_paper {
  my $self = shift;
  my $dbh = shift;

  $self->{entry_type} = 'paper';
  $self->save($dbh);
}; 
####################################################################################
sub is_paper {
  my $self = shift;
  return 1 if $self->{entry_type} eq 'paper';
  return 0;
}; 
####################################################################################
sub make_talk {
  my $self = shift;
  my $dbh = shift;

  $self->{entry_type} = 'talk';
  $self->save($dbh);
}; 
####################################################################################
sub is_talk {
  my $self = shift;
  return 1 if $self->{entry_type} eq 'talk';
  return 0;
}; 
####################################################################################
sub populate_from_bib {
  my $self = shift;

  my $this_bib = $self->{bib};

  if(defined $this_bib and $this_bib ne ''){
    my $bibtex_entry = new Text::BibTeX::Entry();
    $bibtex_entry->parse_s($this_bib);

    $self->{bibtex_key} = $bibtex_entry->key;
    $self->{year} = $bibtex_entry->get('year');
    $self->{title} = $bibtex_entry->get('title') || '';
    $self->{abstract} = $bibtex_entry->get('abstract') || undef;
    $self->{bibtex_type} = $bibtex_entry->type;
    return 1;
  }
  return 0;
};  
####################################################################################
sub bibtex_has_field {
    # returns 1 if bibtex of this entry has filed
    my $self = shift;
    my $bibtex_field = shift;
    my $this_bib = $self->{bib};

    my $bibtex_entry = new Text::BibTeX::Entry();
    $bibtex_entry->parse_s($this_bib);
    return 1 if $bibtex_entry->exists($bibtex_field);
    return 0;
};
####################################################################################
sub get_bibtex_field_value {
  # returns 1 if bibtex of this entry has filed
  my $self = shift;
  my $bibtex_field = shift;
  my $this_bib = $self->{bib};

  if($self->bibtex_has_field($bibtex_field)){
    my $bibtex_entry = new Text::BibTeX::Entry();
    $bibtex_entry->parse_s($this_bib);
    return $bibtex_entry->get($bibtex_field);
  }
  return undef;
};
####################################################################################
sub fix_month {
  # returns 1 if has fixed an entry
  my $self = shift;
  # say "call Mentry->fix_month";

  my $this_bib = $self->{bib};
  # say "call Mentry->fix_month: input bib: $this_bib";

  my $bibtex_entry = new Text::BibTeX::Entry();
  $bibtex_entry->parse_s($self->{bib});

  my $num_fixes = 0;

  if($self->bibtex_has_field('month')){
    my $month_str = $bibtex_entry->get('month');
    my $month_numeric = BibSpace::Controller::Core::get_month_numeric($month_str);

    # say "call Mentry->fix_month: changing $month_str to $month_numeric";

    $self->{month} = $month_numeric;
    $self->{sort_month} = $month_numeric;
    $num_fixes = 1;
  }
  return $num_fixes;
}
########################################################################################################################
sub is_talk_in_DB{
  my $self = shift;
  my $dbh = shift;

  my $db_e = MEntry->static_get($dbh, $self->{id});
  if( $db_e->{entry_type} eq 'talk'){
    return 1;
  }
  return 0;
}
########################################################################################################################
sub is_talk_in_tag{
  my $self = shift;
  my $dbh = shift;
  my $sum = $self->hasTag($dbh, "Talks") + $self->hasTag($dbh, "Talk") + $self->hasTag($dbh, "talks") + $self->hasTag($dbh, "talk");
  return 1 if $sum >0;
  return 0;
}
########################################################################################################################
sub fix_entry_type_based_on_tag{
  my $self = shift;
  my $dbh = shift;

  my $is_talk_db = $self->is_talk_in_DB($dbh);
  my $is_talk_tag = $self->is_talk_in_tag($dbh);

  if($is_talk_tag and $is_talk_db){ 
      # say "both true: OK";
      return 0;
  }
  elsif($is_talk_tag and $is_talk_db ==0 ){
      # say "tag true, DB false. Should write to DB";
      $self->make_talk($dbh); 
      return 1;
  } 
  elsif($is_talk_tag==0 and $is_talk_db ){
      # say "tag false, DB true. do nothing";
      return 0;
  }
  # say "both false. Do nothing";
  return 0;
}
####################################################################################
sub postprocess_updated {
  my $self = shift;
  my $dbh = shift;

  $self->process_tags($dbh);
  my $populated = $self->populate_from_bib();
  

  $self->process_authors($dbh);
  $self->fix_month($dbh);
  my ($html, $htmlbib) = $self->generate_html();

  $self->save($dbh);
  

  my $exit_code = 1; # TODO: old code!
  return $exit_code;
}
####################################################################################
sub generate_html {
  my $self = shift;

  $self->populate_from_bib();
    
  my ($html, $htmlbib) = BibSpace::Controller::Core::get_html_for_bib($self->{bib}, $self->{bibtex_key});
  $self->{html} = $html;
  $self->{html_bib} = $htmlbib;

  return ($html, $htmlbib);
}
####################################################################################
sub process_authors { #was Core::after_edit_process_authors
  say "CALL MEntry process_authors";
    my $self = shift;
    my $dbh = shift;

    $self->populate_from_bib();

    my $bibtex_entry = new Text::BibTeX::Entry();
    $bibtex_entry->parse_s($self->{bib});
  
    my $entry_key = $self->{bibtex_key};

    my $num_authors_created = 0;

    my $sth = undef;
    $sth = $dbh->prepare('DELETE FROM Entry_to_Author WHERE entry_id = ?');
    $sth->execute($self->{id}) if defined $self->{id} and $self->{id} > 0; 

    my @names;

    if($bibtex_entry->exists('author')){
      my @authors = $bibtex_entry->split('author');
      my (@n) = $bibtex_entry->names('author');
      @names = @n;
    }
    elsif($bibtex_entry->exists('editor')){
      my @authors = $bibtex_entry->split('editor');
      my (@n) = $bibtex_entry->names('editor');
      @names = @n;
    }

    # authors need to be added to have their ids!!
    for my $name (@names){
      my $uid = BibSpace::Controller::Core::create_user_id($name);

      my $aid = BibSpace::Controller::Core::get_author_id_for_uid($dbh, $uid);

      # say "\t pre! entry $eid -> uid $uid, aid $aid";

      if($aid eq '-1'){ # there is no such author
        $num_authors_created = $num_authors_created + 1;
        my $sth0 = $dbh->prepare('INSERT INTO Author(uid, master) VALUES(?, ?)');
        $sth0->execute($uid, $uid);
      }
      

      $aid = BibSpace::Controller::Core::get_author_id_for_uid($dbh, $uid);
      my $mid = BibSpace::Controller::Core::get_master_id_for_author_id($dbh, $aid);

      # if author was not in the uid2muid config, then mid = aid
      if($mid eq -1){
         $mid = $aid;
      }
      
      # say "\t pre2! entry $eid -> uid $uid, aid $aid, mid $mid";

      my $sth2 = $dbh->prepare('UPDATE Author SET master_id=? WHERE id=?');
      $sth2->execute($mid, $aid);


    }

    for my $name (@names){
      my $uid = BibSpace::Controller::Core::create_user_id($name);
      my $aid = BibSpace::Controller::Core::get_author_id_for_uid($dbh, $uid);
      my $mid = BibSpace::Controller::Core::get_master_id_for_author_id($dbh, $aid);       #there tables are not filled yet!!

      if(defined $mid and $mid != -1){ #added 5.05.2015 - may skip some authors!
        my $sth3 = $dbh->prepare('INSERT IGNORE INTO Entry_to_Author(author_id, entry_id) VALUES(?, ?)');
        $sth3->execute($mid, $self->{id});
      }
    }
    return $num_authors_created;
}
####################################################################################
sub process_tags { #was Core::after_edit_process_tags
  say "CALL MEntry process_tags";
  my $self = shift;
  my $dbh = shift;

  $self->populate_from_bib();

  my $bibtex_entry = new Text::BibTeX::Entry();
  $bibtex_entry->parse_s($self->{bib});

  my $entry_key = $self->{bibtex_key};
  my $eid = BibSpace::Functions::FPublications::Fget_entry_id_for_bibtex_key($dbh, $entry_key);
  my $num_tags_added = 0;

  if($bibtex_entry->exists('tags')){
    my $tags_str = $bibtex_entry->get('tags');
    $tags_str =~ s/\,/;/g if defined $tags_str;
    $tags_str =~ s/^\s+|\s+$//g if defined $tags_str;


    my @tags = ();
    @tags = split(';', $tags_str) if defined $tags_str;

    for my $tag (@tags){
       $tag =~ s/^\s+|\s+$//g;
       $tag =~ s/\ /_/g if defined $tag;
       # say "MEntry process_tags: processing $tag";


       my $tt_obj = BibSpace::Functions::TagTypeObj->getByName($dbh,"Imported");
       my $tt_id = $tt_obj->{id};

       if(!defined $tt_obj->{id}){
          my $sth4 = $dbh->prepare( "INSERT IGNORE INTO TagType(name, comment) VALUES(?,?)" );
          $sth4->execute("Imported", "Tags Imported from Bibtex");
          $tt_obj = BibSpace::Functions::TagTypeObj->getByName($dbh, "Imported");
          $tt_id = $tt_obj->{id};
       }



       # $dbh->do("REPLACE INTO Tags VALUES($tag)");
       my $sth3 = $dbh->prepare( "INSERT IGNORE INTO Tag(name, type) VALUES(?,?)" );
       $sth3->execute($tag, $tt_obj->{id});
       $num_tags_added = $num_tags_added + $sth3->rows;
       my $tagid2 = BibSpace::Controller::Core::get_tag_id($dbh, $tag);

       # $dbh->do("INSERT INTO Entry_to_Tag(entry, tag) VALUES($entry_key, $tag)");
       $sth3 = $dbh->prepare( "INSERT IGNORE INTO Entry_to_Tag(entry_id, tag_id) VALUES(?, ?)" );
       $sth3->execute($eid, $tagid2);
    }
  }
  return $num_tags_added;
};
####################################################################################
sub sort_by_year_month_modified_time {
  # $a and $b exist and are MEntry objects
  $a->{year} <=> $b->{year} or
  $a->{sort_month} <=> $b->{sort_month} or
  $a->{month} <=> $b->{month} or
  $a->{id} <=> $b->{id};
  # $a->{modified_time} <=> $b->{modified_time}; # needs an extra lib, so we just compare ids as approximation
}
####################################################################################
sub static_get_from_id_array {
  my $self = shift;
  my $dbh = shift;
  my $input_id_arr_ref = shift; 
  my $keep_order = shift // 0; # if set to 1, it keeps the order of the output_arr exactly as in the input_id_arr


  my @input_id_arr = @$input_id_arr_ref;

  unless(grep {defined($_)} @input_id_arr){ # if array is empty
    say "MEntry->static_get_from_id_array array is empty";
    return ();
  }

  my $sort = 1 if $keep_order == 0 or !defined $keep_order;
  my @output_arr = ();

  # the performance here can be optimized 
  for my $wanted_id (@input_id_arr){
    my $e = MEntry->static_get($dbh, $wanted_id);
    push @output_arr, $e;
  }

  # say "static_get_from_id_array output1: ".Dumper \@output_arr;

  if($keep_order == 0){
    return sort sort_by_year_month_modified_time @output_arr;
  }
  return @output_arr;
};
####################################################################################
####################################################################################
sub static_get_filter{
    my $self = shift;
    my $dbh = shift;

    my $master_id = shift;
    my $year = shift;
    my $bibtex_type = shift;
    my $entry_type = shift;
    my $tagid = shift;
    my $teamid = shift;
    my $visible = shift || 0;
    my $permalink = shift;
    my $hidden = shift;

    # say "   master_id $master_id
    #         year $year
    #         bibtex_type $bibtex_type
    #         entry_type $entry_type
    #         tagid $tagid
    #         teamid $teamid
    #         visible $visible
    #         permalink $permalink
    #         hidden $hidden
    # ";

    my @params;

    my $qry = "SELECT DISTINCT  Entry.bibtex_key, 
                                Entry.hidden, 
                                Entry.id, 
                                Entry.bib, 
                                Entry.html, 
                                Entry.bibtex_type, 
                                Entry.entry_type, 
                                Entry.year, 
                                Entry.month, 
                                Entry.sort_month, 
                                Entry.modified_time, 
                                Entry.creation_time
                FROM Entry
                LEFT JOIN Exceptions_Entry_to_Team  ON Entry.id = Exceptions_Entry_to_Team.entry_id
                LEFT JOIN Entry_to_Author ON Entry.id = Entry_to_Author.entry_id 
                LEFT JOIN Author ON Entry_to_Author.author_id = Author.id 
                LEFT JOIN Author_to_Team ON Entry_to_Author.author_id = Author_to_Team.author_id 
                LEFT JOIN OurType_to_Type ON OurType_to_Type.bibtex_type = Entry.bibtex_type 
                LEFT JOIN Entry_to_Tag ON Entry.id = Entry_to_Tag.entry_id 
                LEFT JOIN Tag ON Tag.id = Entry_to_Tag.tag_id 
                WHERE Entry.bibtex_key IS NOT NULL ";
  if(defined $hidden){
    push @params, $hidden;
    $qry .= "AND Entry.hidden=? ";
  }
  if(defined $visible and $visible eq '1'){
    $qry .= "AND Author.display=1 ";
  }
  if(defined $master_id){
    push @params, $master_id;
    $qry .= "AND Entry_to_Author.author_id=? ";
  }
  if(defined $year){
    push @params, $year;
    $qry .= "AND Entry.year=? ";
  }
  if(defined $bibtex_type){
    push @params, $bibtex_type;
    $qry .= "AND OurType_to_Type.our_type=? ";
  }
  if(defined $entry_type){
    push @params, $entry_type;
    $qry .= "AND Entry.entry_type=? ";
  }
  if(defined $teamid){
    push @params, $teamid;
    push @params, $teamid;
    # push @params, $teamid;
    # $qry .= "AND Exceptions_Entry_to_Team.team_id=?  ";
    $qry .= "AND ((Exceptions_Entry_to_Team.team_id=? ) OR (Author_to_Team.team_id=? AND start <= Entry.year  AND (stop >= Entry.year OR stop = 0))) ";
  }
  if(defined $tagid){
    push @params, $tagid;
    $qry .= "AND Entry_to_Tag.tag_id LIKE ?";
  }
  if(defined $permalink){
    push @params, $permalink;
    $qry .= "AND Tag.permalink LIKE ?";
  } 
  $qry .= "ORDER BY Entry.year DESC, Entry.sort_month DESC, Entry.creation_time DESC, Entry.modified_time DESC, Entry.bibtex_key ASC";

  # print $qry."\n";

  my $sth = $dbh->prepare_cached( $qry );  
  $sth->execute(@params); 

  my @objs;

  while(my $row = $sth->fetchrow_hashref()) {
    my $obj = MEntry->new(
                id => $row->{id},
                entry_type => $row->{entry_type},
                bibtex_key => $row->{bibtex_key},
                bibtex_type => $row->{bibtex_type},
                bib => $row->{bib},
                html => $row->{html},
                html_bib => $row->{html_bib},
                abstract => $row->{abstract},
                title => $row->{title},
                hidden => $row->{hidden},
                year => $row->{year},
                month => $row->{month},
                sort_month => $row->{sort_month},
                teams_str => $row->{teams_str},
                people_str => $row->{people_str},
                tags_str => $row->{tags_str},
                creation_time => $row->{creation_time},
                modified_time => $row->{modified_time},
                need_html_regen => $row->{need_html_regen});
    push @objs, $obj;
  }
  return @objs;
}
####################################################################################
sub hasTag{
    my $self = shift;
    my $dbh = shift;
    my $tag_to_find = shift;

    my $tag_id = BibSpace::Controller::Core::get_tag_id($dbh, $tag_to_find);
    if($tag_id == -1){
        $tag_id = $tag_to_find;
    }

    my $qry = "SELECT COUNT(*) FROM Entry_to_Tag WHERE entry_id = ? AND tag_id = ?";
    my @ary = $dbh->selectrow_array($qry, undef, $self->{id}, $tag_id);  
    my $key_exists = $ary[0];
    #my $sth = $dbh->prepare( $qry );  
    #$sth->execute($self->{id}, $tag_id); 
    

    return 1 if $key_exists==1;
    return 0;

}
####################################################################################
1;
