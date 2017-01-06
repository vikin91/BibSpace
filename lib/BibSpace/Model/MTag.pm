package MTag;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use 5.010;           #because of ~~ and say
use DBI;

use BibSpace::Model::Persistent;

use Moose;
use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');

with 'Persistent';

has 'id'        => ( is => 'rw' );
has 'name'      => ( is => 'rw' );
has 'type'      => ( is => 'rw' );
has 'permalink' => ( is => 'rw' );

####################################################################################
sub load {
    my $self = shift;
    my $dbh  = shift;

    # TODO: implement me!
}
####################################################################################
sub static_all {
    my $self = shift;
    my $dbh  = shift;

    my $qry = "SELECT id,
            name,
            type,
            permalink
        FROM Tag";
    my @objs;
    my $sth = $dbh->prepare($qry);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @objs,
            MTag->new(
            id        => $row->{id},
            name      => $row->{name},
            type      => $row->{type},
            permalink => $row->{permalink},
            );
    }
    return @objs;
}
####################################################################################
sub static_all_type {
    my $self = shift;
    my $dbh  = shift;
    my $type = shift;

    my $qry = "SELECT id,
            name,
            type,
            permalink
        FROM Tag
        WHERE type = ?";
    my @objs = ();
    my $sth  = $dbh->prepare($qry);
    $sth->execute($type);

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @objs,
            MTag->new(
            id        => $row->{id},
            name      => $row->{name},
            type      => $row->{type},
            permalink => $row->{permalink},
            );
    }
    return @objs;
}
####################################################################################
sub static_get {
    my $self = shift;
    my $dbh  = shift;
    my $id   = shift;

    # warn "Bad usage of MTag->static_get " if (ref $dbh) ne "DBI::db";

    my $qry = "SELECT id,
                    name,
                    type,
                    permalink
          FROM Tag
          WHERE id = ?";

    my $sth = $dbh->prepare($qry);
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref();

    if ( !defined $row ) {
        return undef;
    }

    return MTag->new(
        id        => $id,
        name      => $row->{name},
        type      => $row->{type},
        permalink => $row->{permalink},
    );
}
####################################################################################
sub update {
    my $self = shift;
    my $dbh  = shift;

    my $result = "";

    if ( !defined $self->{id} ) {
        say
            "Cannot update. MTag id not set. The entry may not exist in the DB. Returning -1";
        return -1;
    }

    my $qry = "UPDATE Tag SET
                name=?,
                type=?,
                permalink=?
            WHERE id = ?";
    my $sth = $dbh->prepare($qry);
    $result = $sth->execute( $self->{name}, $self->{type}, $self->{permalink},
        $self->{id} );
    $sth->finish();
    return $result;
}
####################################################################################
sub insert {
    my $self = shift;
    my $dbh  = shift;

    my $result = "";

    my $qry = "
    INSERT INTO Tag(
    name,
    type,
    permalink
    ) 
    VALUES (?,?,?);";
    my $sth = $dbh->prepare($qry);
    $result
        = $sth->execute( $self->{name}, $self->{type}, $self->{permalink} );
    my $inserted_id = $dbh->last_insert_id( '', '', 'Tag', '' );
    $self->{id} = $inserted_id;

    # say "MTag insert. inserted_id = $inserted_id";
    $sth->finish();
    return $inserted_id;    #or $result;
}
####################################################################################
sub save {
    my $self = shift;
    my $dbh  = shift;

    my $result = "";

    if ( !defined $self->{id} or $self->{id} <= 0 ) {
        my $inserted_id = $self->insert($dbh);
        $self->{id} = $inserted_id;

        # say "MTag save: inserting. inserted_id = ".$self->{id};
        return $inserted_id;
    }
    elsif ( defined $self->{id} and $self->{id} > 0 ) {

        # say "MTag save: updating ID = ".$self->{id};
        return $self->update($dbh);
    }
    else {
        warn "MTag save: cannot either insert nor update :( ID = "
            . $self->{id};
    }
}
####################################################################################
sub delete {
    my $self = shift;
    my $dbh  = shift;

    my $qry    = "DELETE FROM Tag WHERE id=?;";
    my $sth    = $dbh->prepare($qry);
    my $result = $sth->execute( $self->{id} );
    $self->{id} = undef;

    return $result;
}
####################################################################################
####################################################################################
#################################################################################### Methods from TagObj
####################################################################################
####################################################################################

####################################################################################
sub static_get_by_permalink {
    my $self      = shift;
    my $dbh       = shift;
    my $permalink = shift;

    my $sth = $dbh->prepare("SELECT id FROM Tag WHERE permalink=?");
    $sth->execute($permalink);

    my $row = $sth->fetchrow_hashref();
    my $id = $row->{id} || -1;

    if ( $id > 0 ) {
        return MTag->static_get( $dbh, $id );
    }
    return undef;
}
####################################################################################
sub static_get_by_name {
    my $self = shift;
    my $dbh  = shift;
    my $name = shift;

    my $sth = $dbh->prepare("SELECT id FROM Tag WHERE name=?");
    $sth->execute($name);

    my $row = $sth->fetchrow_hashref();
    my $id = $row->{id} || -1;

    if ( $id > 0 ) {
        return MTag->static_get( $dbh, $id );
    }
    return undef;
}
####################################################################################
sub static_get_all_w_letter {
    my $self   = shift;
    my $dbh    = shift;
    my $type   = shift // 1;
    my $letter = shift // '%';

    my @params;
    my $qry
        = "SELECT id, name, type, permalink FROM Tag WHERE name IS NOT NULL AND type = ? ";
    push @params, $type;
    if ( defined $letter ) {
        push @params, $letter;
        $qry .= "AND substr(name, 1, 1) LIKE ? ";
    }
    $qry .= "ORDER BY name ASC";

    my $sth = $dbh->prepare_cached($qry);
    $sth->execute(@params);

    my @objs = ();

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @objs,
            MTag->new(
            id        => $row->{id},
            name      => $row->{name},
            type      => $row->{type},
            permalink => $row->{permalink},
            );
    }
    return @objs;
}

####################################################################################
sub static_get_all_of_type_for_paper {
    my $self = shift;
    my $dbh  = shift;
    my $eid  = shift;
    my $type = shift // 1;

    my $qry = "SELECT Entry.id, Tag.id, Tag.name, Tag.type, Tag.permalink
              FROM Entry
              LEFT JOIN Entry_to_Tag ON Entry.id = Entry_to_Tag.entry_id 
              LEFT JOIN Tag ON Entry_to_Tag.tag_id = Tag.id 
              WHERE Entry.id = ?
              AND Tag.type = ?
              ORDER BY Tag.name";
    my $sth = $dbh->prepare($qry);
    $sth->execute( $eid, $type );

    my @objs = ();
    while ( my $row = $sth->fetchrow_hashref() ) {
        push @objs,
            MTag->new(
            id        => $row->{id},
            name      => $row->{name},
            type      => $row->{type},
            permalink => $row->{permalink},
            );
    }

    return @objs;
}
####################################################################################
sub static_get_unassigned_of_type_for_paper {
    my $self = shift;
    my $dbh  = shift;
    my $eid  = shift;
    my $type = shift // 1;

    my $qry = "SELECT id, name, type, permalink
              FROM Tag
              WHERE type = ? 
              AND id NOT IN (
                  SELECT tag_id 
                  FROM Entry_to_Tag
                  WHERE entry_id = ?
              )
              ORDER BY name";
    my $sth = $dbh->prepare($qry);
    $sth->execute( $type, $eid );

    my @objs = ();
    while ( my $row = $sth->fetchrow_hashref() ) {
        push @objs,
            MTag->new(
            id        => $row->{id},
            name      => $row->{name},
            type      => $row->{type},
            permalink => $row->{permalink},
            );
    }
    return @objs;
}
####################################################################################
sub get_authors {
    my $self   = shift;
    my $dbh    = shift;

    my $qry = "SELECT DISTINCT Entry_to_Author.author_id
            FROM Entry_to_Author 
            LEFT JOIN Entry_to_Tag ON Entry_to_Author.entry_id = Entry_to_Tag.entry_id 
            LEFT JOIN Author ON Entry_to_Author.author_id = Author.id 
            WHERE Entry_to_Tag.tag_id =? 
            AND Entry_to_Author.author_id IS NOT NULL";

    my $sth = $dbh->prepare($qry);
    $sth->execute($self->{id});

    my @authors;

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $author = MAuthor->static_get( $dbh, $row->{author_id} );
        push @authors, $author if defined $author;
    }
    return @authors;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
