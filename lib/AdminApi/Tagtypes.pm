package AdminApi::Tagtypes;

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
use TagTypeObj;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;


####################################################################################
sub index{
    my $self = shift;
    my $dbh = $self->db;

    my @objs = TagTypeObj->getAll($dbh);

    $self->render(template => 'tagtypes/tagtypes', tto => \@objs);
}



####################################################################################
sub add{
    my $self = shift;
    my $dbh = $self->db;


    $self->render(template => 'tagtypes/add');
}

####################################################################################
sub add_post{
    my $self = shift;
    my $dbh = $self->db;
    my $name = $self->param('new_name');
    my $comment = $self->param('new_comment');

    my $qry = 'INSERT INTO Tagtype(name, comment) VALUES (?,?)';
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($name, $comment); 
    
    $self->redirect_to("/tagtypes");
}

####################################################################################
sub delete{
    my $self = shift;
    my $dbh = $self->db;
    my $id = $self->param('id');

    if($id == 1 or $id == 2){
        $self->redirect_to("/tagtypes");
        return;        
    }

    my $qry = 'DELETE FROM Tag WHERE type=?';
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($id); 

    my $qry2 = 'DELETE FROM Tagtype WHERE id=?';
    my $sth2 = $dbh->prepare( $qry2 );  
    $sth2->execute($id); 

    $self->redirect_to("/tagtypes");
}

####################################################################################
sub edit{
    my $self = shift;
    my $dbh = $self->db;
    my $id = $self->param('id');

    my $name = $self->param('new_name');
    my $comment = $self->param('new_comment');
    my $saved = 0;

    if(defined $name and defined $comment){
        my $qry = 'UPDATE Tagtype SET name=?, comment=? WHERE id=?';
        my $sth = $dbh->prepare( $qry );  
        $sth->execute($name, $comment, $id); 
        $saved = 1;
    }

    my $obj = TagTypeObj->new();
    $obj = $obj->getById($dbh, $id);


    $self->stash(id => $id, obj => $obj, saved  => $saved);
    $self->render(template => 'tagtypes/edit');

}




# ####################################################################################
# ####################################################################################
# ####################################################################################

# sub get_first_letters{
#     my $self = shift;
#     my $dbh = $self->db;
#     my $type = shift || 1;

#     my $sth = $dbh->prepare( "SELECT DISTINCT substr(name, 0, 2) as let FROM Tag WHERE type=? ORDER BY let ASC" ); 
#     $sth->execute($type); 
#     my @letters;
#     while(my $row = $sth->fetchrow_hashref()) {
#       my $letter = $row->{let} || "*";
#       push @letters, uc($letter);
#     }

#     return @letters;
# }
# ####################################################################################
# sub add_tags_from_string {
#     my $self = shift;
#     my $tags_to_add = shift;
#     my $type = shift || 1;
#     my $dbh = $self->db;

#     my @tag_ids;
#     my @tags_arr;

#     if(defined $tags_to_add){

#         my @pre_tags_arr = split(';', $tags_to_add);
        

#         foreach my $tag(@pre_tags_arr){
#             $tag = clean_tag_name($tag);

#             if(defined $tag and $tag ne '' and length($tag)>0){
#                push @tags_arr, $tag if defined $tag;
#                $self->write_log("Adding new tag ->".$tag."<-");
#             }
#         }

        

#         foreach my $tag (@tags_arr) {
#             my $qry = 'INSERT INTO Tag(name, type) VALUES (?,?)';
#             my $sth = $dbh->prepare( $qry );  
#             $sth->execute($tag,$type); 
#             $sth->finish();
#         } 
        
    
#         foreach my $tag(@tags_arr){
#             my $sth2 = $dbh->prepare( "SELECT id FROM Tag WHERE name=? AND type=?" );  
#             $sth2->execute($tag, $type);
#             my $row = $sth2->fetchrow_hashref();
#             my $id = $row->{id} || -1;
#             push @tag_ids, $id if $id > -1;
#             $sth2->finish();
#         }
#    }

#    return @tag_ids;

# }
# ####################################################################################
# sub add {
#     my $self = shift;
#     my $dbh = $self->db;
#     my $type = $self->param('type') || 1;

#     $self->render(template => 'tags/add', type => $type);
# }

# ####################################################################################
# sub add_post {
#     my $self = shift;

#     my $dbh = $self->db;
#     my $type = $self->param('type') || 1;

#     my $tags_to_add = $self->param('new_tags');
#     my @tag_ids = add_tags_from_string($self, $tags_to_add, $type);

#     if(scalar @tag_ids >0 ){
#         $self->flash(msg  => "The following tags (of type $type) were added successfully: <i>$tags_to_add</i> , ids: <i>".join(", ",@tag_ids)."</i>");
#     }
#     $self->write_log("tags added: $tags_to_add, ids: ".join(", ",@tag_ids));
#     $self->redirect_to("/tags/$type/add");
#     # $self->render(template => 'tags/add');
# }

# ####################################################################################

# sub add_and_assign {
#     my $self = shift;
#     my $tags_to_add = $self->param('new_tags');
#     my $eid = $self->param('eid');
#     my $type = $self->param('type') || 1;
#     my $dbh = $self->db;

#     my @tag_ids = add_tags_from_string($self, $tags_to_add);

#     foreach my $tag_id (@tag_ids){
#         say "Want to assing tag (type $type) id $tag_id to entry eid $eid";
#         my $sth = $dbh->prepare( "INSERT INTO Entry_to_Tag(entry_id, tag_id) VALUES (?,?)");
#         $sth->execute($eid, $tag_id) if defined $eid and $eid > 0 and defined $tag_id and $tag_id > 0;
#     }

#     my $back_url = $self->param('back_url') || "/publications/manage_tags/$eid";
#     $self->redirect_to($back_url);
# }

# ####################################################################################

# sub edit {
#     my $self = shift;
#     my $dbh = $self->db;

#     my $tagid = $self->param('id');
#     my $new_tag = $self->param('new_tag') || undef;
#     my $type = $self->param('type') || 1;
#     my $saved = 0;

#     if(defined $new_tag){

#         # there is POST-data for editing
#         $new_tag = clean_tag_name($new_tag);

#         my $qry = 'UPDATE Tag SET name = ? WHERE id=? AND type=?';
#         my $sth = $dbh->prepare( $qry );  
#         $sth->execute($new_tag, $tagid, $type);
#         $saved = 1;
#     }
    
#     # my $qry = "SELECT DISTINCT id, name, substr(name, 0, 2) as let FROM Tag WHERE name NOT NULL AND id = ? ";
#     my $qry = "SELECT DISTINCT id, name
#              FROM Tag WHERE id = ? AND type=?";

#     my $sth = $dbh->prepare( $qry );  
#     $sth->execute($tagid, $type);  
#     my $row = $sth->fetchrow_hashref();
#     my $tag = $row->{name};

#     $self->stash(tag  => $tag, id => $tagid, saved  => $saved);
#     $self->render(template => 'tags/edit');
   
# }

# ####################################################################################
# sub get_authors_for_tag_read{
#     my $self = shift;
#     my $dbh = $self->db;
#     my $tag_id = $self->param('tid');
#     my $team = $self->param('team');

#     my $tag = get_tag_name_for_id($dbh, $tag_id);
#     if($tag == -1){
#         $tag = $tag_id;
#         $tag_id = get_tag_id($dbh, $tag);
#     }

#     my $team_id = get_team_id($dbh, $team);
#     if( $team_id == -1 ){
#         $team_id = $team;
#     }

#     my @authors = get_author_ids_for_tag_id($self, $tag_id);
#     @authors = get_author_ids_for_tag_id_and_team($self, $tag_id, $team_id);

#     $self->stash(tag => $tag, tag_id => $tag_id, author_ids  => \@authors);
#     $self->render(template => 'tags/authors_having_tag_read');
# }
# ####################################################################################
# sub get_tags_for_author_read{

#     my $self = shift;
#     my $user = $self->param('aid');
#     my $maid = $user;

#     my $dbh = $self->db;
#     $maid = get_master_id_for_master($dbh, $user);
#     if($maid == -1){
#         #user input is already master id! using the user's input
#         $maid = $user;
#     }

#     my ($tag_ids_arr_ref, $tags_arr_ref) = get_tags_for_author($self, $maid);

#     ### here list of objects should be created


#     my @TCarr;

#     my $i = 0;
#     foreach my $tag_id (@$tag_ids_arr_ref){
#         my $tag = $$tags_arr_ref[$i];

#         my $name = $tag;
#         $name =~ s/_/\ /g;

#         my $set = get_set_of_papers_for_author_and_tag($self, $maid, $tag_id);
#         my $count =  scalar $set->members;

#         my $url = "/read/publications?author=".get_master_for_id($self->db, $maid)."&tag=".$tag;
        
#         my $obj = new TagCloudClass($tag);
#         $obj->setURL($url);
#         $obj->setCount($count);
#         $obj->setName($name);

#         push @TCarr, $obj;
#         $i++;
#     }

#     my @sorted = reverse sort { $a->getCount() <=> $b->getCount()} @TCarr;

#     ### old code

#     $self->stash(tags => $tags_arr_ref, tag_ids => $tag_ids_arr_ref, author_id  => $maid, tcarr => \@sorted);
#     $self->render(template => 'tags/author_tags_read');

# }
# ####################################################################################
# sub get_authors_for_tag{
#     my $self = shift;
#     my $dbh = $self->db;
#     my $tag_id = $self->param('tid');

#     my $tag = get_tag_name_for_id($dbh, $tag_id);

#     my @authors = get_author_ids_for_tag_id($self, $tag_id);

#     $self->stash(tag => $tag, tag_id => $tag_id, author_ids  => \@authors);
#     $self->render(template => 'tags/authors_having_tag');
# }
# ####################################################################################

# sub delete {
#     my $self = shift;
#     my $dbh = $self->db;

#     my $tag_to_delete = $self->param('id_to_delete');
#     my $type = $self->param('type') || 1;

#     say $tag_to_delete;

#     if(defined $tag_to_delete){

#         $self->write_log("Deleting tag id: $tag_to_delete.");

#         my $sth = $dbh->prepare( 'DELETE FROM Tag WHERE id=? AND type=?' );  
#         $sth->execute($tag_to_delete, $type); 


#         my $sth2 = $dbh->prepare( 'DELETE FROM Entry_to_Tag WHERE tag_id=?' );  
#         $sth2->execute($tag_to_delete);
#     }
#     $self->redirect_to("/tags");
# }


1;