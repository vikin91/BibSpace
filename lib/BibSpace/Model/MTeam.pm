package MTeam;
use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use 5.010;           #because of ~~ and say
use DBI;
use Moose;

has 'id'     => ( is => 'rw' );
has 'name'   => ( is => 'rw' );
has 'parent' => ( is => 'rw' );

####################################################################################
sub static_all {
    my $self = shift;
    my $dbh  = shift;

    my $qry = "SELECT id,
            name,
            parent
        FROM Team";
    my @objs;
    my $sth = $dbh->prepare($qry);
    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref() ) {
        my $obj = MTeam->new(
            id     => $row->{id},
            name   => $row->{name},
            parent => $row->{parent}
        );
        push @objs, $obj;
    }
    return @objs;
}
####################################################################################
sub static_get {
    my $self = shift;
    my $dbh  = shift;
    my $id   = shift;

    my $qry = "SELECT id,
                    name,
                    parent
          FROM Team
          WHERE id = ?";

    my $sth = $dbh->prepare($qry);
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref();

    if ( !defined $row ) {
        return undef;
    }

    return MTeam->new(
        id     => $id,
        name   => $row->{name},
        parent => $row->{parent}
    );
}
####################################################################################
sub update {
    my $self = shift;
    my $dbh  = shift;

    my $result = "";

    if ( !defined $self->{id} ) {
        say
            "Cannot update. MTeam id not set. The entry may not exist in the DB. Returning -1. Should never happen!";
        return -1;
    }

    my $qry = "UPDATE Team SET
                name=?,
                parent=?
            WHERE id = ?";
    my $sth = $dbh->prepare($qry);
    $result = $sth->execute( $self->{name}, $self->{parent}, $self->{id} );
    $sth->finish();
    return $result;
}
####################################################################################
sub insert {
    my $self   = shift;
    my $dbh    = shift;
    my $result = "";

    my $qry = "
        INSERT INTO Team(
        name,
        parent
        ) 
        VALUES (?,?);";
    my $sth = $dbh->prepare($qry);
    $result = $sth->execute( $self->{name}, $self->{parent}, );
    $self->{id} = $dbh->last_insert_id( '', '', 'Team', '' );
    $sth->finish();
    return $self->{id};
}
####################################################################################
sub save {
    my $self = shift;
    my $dbh  = shift;

    warn "No database handle supplied!" unless defined $dbh;

    my $result = "";

    if ( defined $self->{id} and $self->{id} > 0 ) {

        # say "MTeam save: updating ID = ".$self->{id};
        return $self->update($dbh);
    }
    elsif ( defined $self and !defined $self->{name} ) {
        warn "Cannot save MTeam that has no name";
        return -1;
    }
    else {
        my $inserted_id = $self->insert($dbh);
        $self->{id} = $inserted_id;

        # say "MTeam save: inserting. inserted_id = ".$self->{id};
        return $inserted_id;
    }
}
####################################################################################
sub delete {
    my $self = shift;
    my $dbh  = shift;

    my $qry    = "DELETE FROM Team WHERE id=?;";
    my $sth    = $dbh->prepare($qry);
    my $result = $sth->execute( $self->{id} );
    $self->{id} = undef;

    return $result;
}
####################################################################################
sub static_get_by_name {
    my $self = shift;
    my $dbh  = shift;
    my $name = shift;

    my $sth = $dbh->prepare("SELECT id FROM Team WHERE name=?");
    $sth->execute($name);
    my $row = $sth->fetchrow_hashref();
    my $id = $row->{id} || -1;

    if ( $id > 0 ) {
        return MTeam->static_get( $dbh, $id );
    }
    return undef;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
