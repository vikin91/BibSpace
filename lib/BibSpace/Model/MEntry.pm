#package BibSpace::Model::MEntry;

use strict;
use warnings;

use BibSpace::Controller::Core;
# use BibSpace::Functions::FPublications; # there should be really no call to this module. All calls should be moved to a new module
use BibSpace::Functions::TagTypeObj;

use Data::Dumper;
# use utf8;
# use Text::BibTeX; # parsing bib files
# use DateTime;
# use File::Slurp;
# use Time::Piece;
use 5.010; #because of ~~ and say
use DBI;
# use Moose;


package MEntry;
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
   has 'hidden' => (is => 'rw'); 
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
    sub all {
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
    sub get {
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

        $self->id($id);
        $self->entry_type($row->{entry_type});
        $self->bibtex_key($row->{bibtex_key});
        $self->bibtex_type($row->{bibtex_type});
        $self->bib($row->{bib});
        $self->html($row->{html});
        $self->html_bib($row->{html_bib});
        $self->abstract($row->{abstract});
        $self->title($row->{title});
        $self->hidden($row->{hidden});
        $self->year($row->{year});
        $self->month($row->{month});
        $self->sort_month($row->{sort_month});
        $self->teams_str($row->{teams_str});
        $self->people_str($row->{people_str});
        $self->tags_str($row->{tags_str});
        $self->creation_time($row->{creation_time});
        $self->modified_time($row->{modified_time});
        $self->need_html_regen($row->{need_html_regen});
  }
####################################################################################
sub update {
  my $self = shift;
  my $dbh = shift;

  my $result = "";

  say "@@@@@@@@@ CALL MEntry update";

  # say "MEntry update. filed id value: ".$self->{id};
  # say "MEntry update. filed entry_type value: ".$self->{entry_type};
  # say "MEntry update. filed bibtex_key value: ".$self->{bibtex_key};
  # say "MEntry update. filed bibtex_type value: ".$self->{bibtex_type};
  # say "MEntry update. filed bib value: ".$self->{bib};
  # say "MEntry update. filed html value: ".$self->{html};
  # say "MEntry update. filed html_bib value: ".$self->{html_bib};
  # say "MEntry update. filed abstract value: ".$self->{abstract};
  # say "MEntry update. filed title value: ".$self->{title};
  # say "MEntry update. filed hidden value: ".$self->{hidden};
  # say "MEntry update. filed year value: ".$self->{year};
  # say "MEntry update. filed month value: ".$self->{month};
  # say "MEntry update. filed sort_month value: ".$self->{sort_month};
  # say "MEntry update. filed teams_str value: ".$self->{teams_str};
  # say "MEntry update. filed people_str value: ".$self->{people_str};
  # say "MEntry update. filed tags_str value: ".$self->{tags_str};
  # say "MEntry update. filed creation_time value: ".$self->{creation_time};
  # say "MEntry update. filed modified_time value: ".$self->{modified_time};
  # say "MEntry update. filed need_html_regen value: ".$self->{need_html_regen};

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

  say "@@@@@@@@@ END CALL MEntry update: ".$result;
  return $result;
}
####################################################################################
sub store {
  my $self = shift;
  my $dbh = shift;

  my $result = "";

  say "@@@@@@@@@ CALL MEntry store";

  # say "MEntry store. filed id value: ".$self->{id};
  # say "MEntry store. filed entry_type value: ".$self->{entry_type};
  # say "MEntry store. filed bibtex_key value: ".$self->{bibtex_key};
  # say "MEntry store. filed bibtex_type value: ".$self->{bibtex_type};
  # say "MEntry store. filed bib value: ".$self->{bib};
  # say "MEntry store. filed html value: ".$self->{html};
  # say "MEntry store. filed html_bib value: ".$self->{html_bib};
  # say "MEntry store. filed abstract value: ".$self->{abstract};
  # say "MEntry store. filed title value: ".$self->{title};
  # say "MEntry store. filed hidden value: ".$self->{hidden};
  # say "MEntry store. filed year value: ".$self->{year};
  # say "MEntry store. filed month value: ".$self->{month};
  # say "MEntry store. filed sort_month value: ".$self->{sort_month};
  # say "MEntry store. filed teams_str value: ".$self->{teams_str};
  # say "MEntry store. filed people_str value: ".$self->{people_str};
  # say "MEntry store. filed tags_str value: ".$self->{tags_str};
  # say "MEntry store. filed creation_time value: ".$self->{creation_time};
  # say "MEntry store. filed modified_time value: ".$self->{modified_time};
  # say "MEntry store. filed need_html_regen value: ".$self->{need_html_regen};

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
  $sth->finish();
  return $inserted_id; #or $result;
}
####################################################################################
sub save {
  my $self = shift;
  my $dbh = shift;

  my $result = "";


  if(!defined $self->{id}){
    return $self->store($dbh);
  }
  else{
    return $self->update($dbh);
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
sub bibtex_has {
    # returns 1 if bibtex of this entry has filed
    my $self = shift;
    my $bibtex_field = shift;
    my $this_bib = $self->{bib};

    my $bibtex_entry = new Text::BibTeX::Entry();
    $bibtex_entry->parse_s($this_bib);
    return $bibtex_entry->exists($bibtex_field);
};
####################################################################################
sub get_bibtex_field_value {
    # returns 1 if bibtex of this entry has filed
    my $self = shift;
    my $bibtex_field = shift;
    my $this_bib = $self->{bib};

    if($self->bibtex_has($bibtex_field)){
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

    if($self->bibtex_has('month')){
        my $month_str = $bibtex_entry->get('month');
        my $month_numeric = BibSpace::Controller::Core::get_month_numeric($month_str);

        # say "call Mentry->fix_month: changing $month_str to $month_numeric";

        $self->{month} = $month_numeric;
        $self->{sort_month} = $month_numeric;
        $num_fixes = 1;
    }
    return $num_fixes;
}
####################################################################################
sub postprocess_updated {
    my $self = shift;
    my $dbh = shift;

    say "@@@@@@@@@ CALL MEntry postprocess_updated";

    # TODO: after_edit_process_tags($dbh, $entry);
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
        $sth0->execute($uid, $uid) if $aid eq '-1';
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

1;
