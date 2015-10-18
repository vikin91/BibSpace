package AdminApi::Tags;

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

use AdminApi::Core;
use TagCloudClass;
use TagObj;
use TagTypeObj;
use AdminApi::Set;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;



####################################################################################
### NOT USED!
sub prepare_db{
    my $self = shift;
    my $dbh = $self->app->db;

    $dbh->do("CREATE TABLE IF NOT EXISTS TagType(
        name TEXT,
        comment TEXT,
        id INTEGER PRIMARY KEY
        )");

    $dbh->do("ALTER TABLE Tag RENAME TO Tag2");
    $dbh->do("ALTER TABLE Tag ADD COLUMN permalink TEXT");

    $dbh->do("CREATE TABLE Tag(
            name TEXT NOT NULL,
            id INTEGER PRIMARY KEY,
            type INTEGER DEFAULT 1,
            permalink TEXT,
            FOREIGN KEY(type) REFERENCES TagType(id),
            UNIQUE(name) ON CONFLICT IGNORE
        );");

    $dbh->do("INSERT INTO Tag (id, name)
                SELECT id, name
                FROM Tag2");

    $dbh->do("DROP TABLE Tag2");
}

####################################################################################

sub index {
    my $self = shift;
    my $dbh = $self->app->db;
    my $letter = $self->param('letter') || '%';
    my $type = $self->param('type') || 1;

    if($letter ne '%'){
        $letter.='%';
    }

    my @objs = TagObj->getAllwLetter($dbh, $type, $letter);
    my @letters_arr = get_first_letters($self, $type);

    $self->stash(otags => \@objs, type => $type, letters_arr => \@letters_arr);

    $self->render(template => 'tags/tags');
}

####################################################################################
sub get_first_letters{
    my $self = shift;
    my $dbh = $self->app->db;
    my $type = shift || 1;

    my $sth = $dbh->prepare( "SELECT DISTINCT substr(name, 0, 2) as let FROM Tag WHERE type=? ORDER BY let ASC" ); 
    $sth->execute($type); 
    my @letters;
    while(my $row = $sth->fetchrow_hashref()) {
      my $letter = $row->{let} || "*";
      push @letters, uc($letter);
    }

    return @letters;
}
####################################################################################
sub add_tags_from_string {
    my $self = shift;
    my $tags_to_add = shift;
    my $type = shift || 1;
    my $dbh = $self->app->db;

    my @tag_ids;
    my @tags_arr;

    say "call: add_tags_from_string";

    say "tags_to_add $tags_to_add";

    if(defined $tags_to_add){

        my @pre_tags_arr = split(';', $tags_to_add);
        

        foreach my $tag(@pre_tags_arr){
            $tag = clean_tag_name($tag);

            if(defined $tag and $tag ne '' and length($tag)>0){
               push @tags_arr, $tag if defined $tag;
               $self->write_log("Adding new tag ->".$tag."<-");
            }
        }

        

        foreach my $tag (@tags_arr) {
            my $qry = 'INSERT INTO Tag(name, type) VALUES (?,?)';
            my $sth = $dbh->prepare( $qry );  
            $sth->execute($tag,$type); 
            $sth->finish();
        } 
        
    
        foreach my $tag(@tags_arr){
            my $sth2 = $dbh->prepare( "SELECT id FROM Tag WHERE name=? AND type=?" );  
            $sth2->execute($tag, $type);
            my $row = $sth2->fetchrow_hashref();
            my $id = $row->{id} || -1;
            push @tag_ids, $id if $id > -1;
            $sth2->finish();
        }
   }

   return @tag_ids;

}
####################################################################################
sub add {
    my $self = shift;
    my $dbh = $self->app->db;
    my $type = $self->param('type') || 1;

    $self->render(template => 'tags/add', type => $type);
}

####################################################################################
sub add_post {
    my $self = shift;

    my $dbh = $self->app->db;
    my $type = $self->param('type') || 1;

    my $tags_to_add = $self->param('new_tag');
    my @tag_ids = add_tags_from_string($self, $tags_to_add, $type);

    if(scalar @tag_ids >0 ){
        $self->flash(msg  => "The following tags (of type $type) were added successfully: <i>$tags_to_add</i> , ids: <i>".join(", ",@tag_ids)."</i>");
    }
    $self->write_log("tags added: $tags_to_add, ids: ".join(", ",@tag_ids));
    $self->redirect_to("/tags/$type");
    # $self->render(template => 'tags/add');
}

####################################################################################

sub add_and_assign {
    my $self = shift;
    my $tags_to_add = $self->param('new_tag');
    my $eid = $self->param('eid');
    my $type = $self->param('type') || 1;
    my $dbh = $self->app->db;

    my @tag_ids = add_tags_from_string($self, $tags_to_add);

    foreach my $tag_id (@tag_ids){
        say "Want to assing tag (type $type) id $tag_id to entry eid $eid";
        my $sth = $dbh->prepare( "INSERT INTO Entry_to_Tag(entry_id, tag_id) VALUES (?,?)");
        $sth->execute($eid, $tag_id) if defined $eid and $eid > 0 and defined $tag_id and $tag_id > 0;
    }

    my $back_url = $self->param('back_url') || "/publications/manage_tags/$eid";
    $self->redirect_to($back_url);
}

####################################################################################

sub edit {
    my $self = shift;
    my $dbh = $self->app->db;
    my $tagid = $self->param('id');

    # the tag as it is stored in the db
    my $tobj = TagObj->new({id => $tagid});
    $tobj->initFromDB($dbh);

    
    my $new_tag = $self->param('new_tag') || undef;
    my $new_permalink = $self->param('new_permalink') || undef;
    my $new_type = $self->param('new_type') || undef;
    my $saved = 0;

    $new_tag = $tobj->{name} unless defined $self->param('new_tag');
    $new_permalink = $tobj->{permalink} unless defined $self->param('new_permalink');
    $new_type = $tobj->{type} unless defined $self->param('new_type');

    if(defined $new_tag or defined $new_permalink or defined $new_type){

        # there is POST-data for editing
        $new_tag = clean_tag_name($new_tag);

        my $qry = 'UPDATE Tag SET name = ?, permalink=?, type=? WHERE id=?';
        my $sth = $dbh->prepare( $qry );  

        ###  TODO! finish make sure it works!!

        $sth->execute($new_tag, $new_permalink, $new_type, $tagid);
        $saved = 1;
    }

    $tobj->initFromDB($dbh) if $saved == 1;

    
    
    # # my $qry = "SELECT DISTINCT id, name, substr(name, 0, 2) as let FROM Tag WHERE name NOT NULL AND id = ? ";
    # my $qry = "SELECT DISTINCT id, name
    #          FROM Tag WHERE id = ?";

    # my $sth = $dbh->prepare( $qry );  
    # $sth->execute($tagid);  
    # my $row = $sth->fetchrow_hashref();
    # my $tag = $row->{name};

    $self->stash(tagobj  => $tobj, saved  => $saved);
    $self->render(template => 'tags/edit');
   
}

####################################################################################
sub get_authors_for_tag_read{
    my $self = shift;
    my $dbh = $self->app->db;
    my $tag_id = $self->param('tid');
    my $team = $self->param('team');

    my $tag = get_tag_name_for_id($dbh, $tag_id);
    if($tag == -1){
        $tag = $tag_id;
        $tag_id = get_tag_id($dbh, $tag);
    }

    my $team_id = get_team_id($dbh, $team);
    if( $team_id == -1 ){
        $team_id = $team;
    }

    my @authors = get_author_ids_for_tag_id($self, $tag_id);
    @authors = get_author_ids_for_tag_id_and_team($self, $tag_id, $team_id);

    $self->stash(tag => $tag, tag_id => $tag_id, author_ids  => \@authors);
    $self->render(template => 'tags/authors_having_tag_read');
}
####################################################################################
sub get_tags_for_author_read{

    my $self = shift;
    my $user = $self->param('aid');
    my $maid = $user;

    my $dbh = $self->app->db;
    $maid = get_master_id_for_master($dbh, $user);
    if($maid == -1){
        #user input is already master id! using the user's input
        $maid = $user;
    }

    my ($tag_ids_arr_ref, $tags_arr_ref) = get_tags_for_author($self, $maid);

    ### here list of objects should be created


    my @TCarr;

    my $i = 0;
    foreach my $tag_id (@$tag_ids_arr_ref){
        my $tag = $$tags_arr_ref[$i];

        my $name = $tag;
        $name =~ s/_/\ /g;

        my $set = get_set_of_papers_for_author_and_tag($self, $maid, $tag_id);
        my $count =  scalar $set->members;

        my $url = "/ly/p?author=".get_master_for_id($self->app->db, $maid)."&tag=".$tag."&title=1&navbar=1";
        
        my $obj = new TagCloudClass($tag);
        $obj->setURL($url);
        $obj->setCount($count);
        $obj->setName($name);

        push @TCarr, $obj;
        $i++;
    }

    my @sorted = reverse sort { $a->getCount() <=> $b->getCount()} @TCarr;

    ### old code

    $self->stash(tags => $tags_arr_ref, tag_ids => $tag_ids_arr_ref, author_id  => $maid, tcarr => \@sorted);
    $self->render(template => 'tags/author_tags_read');

}
####################################################################################
sub get_tags_for_team_read{
    my $self = shift;
    my $team = $self->param('tid');
    my $tid = $team;

    my $dbh = $self->app->db;
    $tid = get_team_id($dbh, $team); 
    if($tid == -1){
        #user input is already team id! using the user's input
        $tid = $team;
    }

    my ($tag_ids_arr_ref, $tags_arr_ref) = get_tags_for_team($self, $tid, 1);

    ### here list of objects should be created


    my @TCarr;

    my $i = 0;
    foreach my $tag_id (@$tag_ids_arr_ref){
        my $tag = $$tags_arr_ref[$i];

        my $name = $tag;
        $name =~ s/_/\ /g;

        my $set = get_set_of_papers_for_team_and_tag($self, $tid, $tag_id);
        my $count =  scalar $set->members;

        my $url = "/ly/p?team=".get_team_for_id($self->app->db, $tid)."&tag=".$tag."&title=1&navbar=1";
        
        my $obj = new TagCloudClass($tag);
        $obj->setURL($url);
        $obj->setCount($count);
        $obj->setName($name);

        push @TCarr, $obj;
        $i++;
    }

    my @sorted = reverse sort { $a->getCount() <=> $b->getCount()} @TCarr;

    ### old code

    $self->stash(tags => $tags_arr_ref, tag_ids => $tag_ids_arr_ref, author_id  => $team, tcarr => \@sorted);
    $self->render(template => 'tags/author_tags_read');

}
####################################################################################
sub get_authors_for_tag{
    my $self = shift;
    my $dbh = $self->app->db;
    my $tag_id = $self->param('tid');

    my $tag = get_tag_name_for_id($dbh, $tag_id);

    my @authors = get_author_ids_for_tag_id($self, $tag_id);

    $self->stash(tag => $tag, tag_id => $tag_id, author_ids  => \@authors);
    $self->render(template => 'tags/authors_having_tag');
}
####################################################################################

sub delete {
    my $self = shift;
    my $dbh = $self->app->db;

    my $tag_to_delete = $self->param('id_to_delete');
    my $type = $self->param('type') || 1;

    say $tag_to_delete;

    if(defined $tag_to_delete){

        $self->write_log("Deleting tag id: $tag_to_delete.");

        my $sth = $dbh->prepare( 'DELETE FROM Tag WHERE id=?' );  
        $sth->execute($tag_to_delete); 


        my $sth2 = $dbh->prepare( 'DELETE FROM Entry_to_Tag WHERE tag_id=?' );  
        $sth2->execute($tag_to_delete);
    }

    my $back_url = $self->param('back_url') || "/tags";
    $self->redirect_to($back_url);
}


1;