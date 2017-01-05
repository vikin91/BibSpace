package MTagType;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use 5.010;           #because of ~~ and say
use DBI;
use Moose;

has 'id'      => ( is => 'rw' );
has 'name'    => ( is => 'rw' );
has 'comment' => ( is => 'rw' );

####################################################################################

sub equals {
    my $self  = shift;
    my $other = shift;

    if (    $self->{id} == $other->{id}
        and $self->{name} eq $other->{name}
        and $self->{comment} eq $other->{comment} )
    {
        return 1;
    }

    return 0;
}
####################################################################################

sub static_get_by_name {
    my $self = shift;
    my $dbh  = shift;
    my $name = shift;

    my $qry = "SELECT id, name, comment
               FROM TagType
               WHERE name = ?";

    my $sth = $dbh->prepare($qry);
    $sth->execute($name);
    my $row = $sth->fetchrow_hashref();

    if ( !defined $row ) {
        return undef;
    }

    return MTagType->new(
        id      => $row->{id},
        name    => $row->{name},
        comment => $row->{comment},
    );
}
####################################################################################
sub static_get {
    my $self = shift;
    my $dbh  = shift;
    my $id   = shift;

    my $qry = "SELECT id, name, comment
               FROM TagType
               WHERE id = ?";

    my $sth = $dbh->prepare($qry);
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref();

    if ( !defined $row ) {
        return undef;
    }

    return MTagType->new(
        id      => $id,
        name    => $row->{name},
        comment => $row->{comment},
    );
}
####################################################################################
sub static_all {
    my $self = shift;
    my $dbh  = shift;

    my $qry = " SELECT id, name, comment 
                FROM TagType 
                ORDER BY id ASC";
    my $sth = $dbh->prepare($qry);
    $sth->execute();

    my @objs;

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @objs,
            MTagType->new(
            id      => $row->{id},
            name    => $row->{name},
            comment => $row->{comment},
            );
    }
    return @objs;
}
####################################################################################
sub update {
    my $self = shift;
    my $dbh  = shift;

    my $result = "";

    if ( !defined $self->{id} ) {
        say
            "Cannot update MTagType: id not set. The entry may not exist in the DB. Returning undef";
        return undef;
    }

    my $qry = "UPDATE TagType SET
                name=?,
                comment=?
            WHERE id = ?";
    my $sth = $dbh->prepare($qry);
    $result = $sth->execute( $self->{name}, $self->{comment}, $self->{id} );
    $sth->finish();
    return $result;
}
####################################################################################
sub insert {
    my $self = shift;
    my $dbh  = shift;

    my $result = "";

    my $qry = "INSERT INTO TagType (name, comment) VALUES (?,?);";
    my $sth = $dbh->prepare($qry);
    $result = $sth->execute( $self->{name}, $self->{comment} );
    my $inserted_id = $dbh->last_insert_id( '', '', 'TagType', '' );
    $self->{id} = $inserted_id;

    # say "MTag insert. inserted_id = $inserted_id";
    $sth->finish();
    return $inserted_id;    #or $result;
}
####################################################################################
sub save {
    my $self = shift;
    my $dbh  = shift;

    # exists, updating
    if ( defined $self->{id} and $self->{id} > 0 ) {
        return $self->update($dbh);
    }

    # does not exits, inserting
    $self->{id} = $self->insert($dbh);
    return $self->{id};
}
####################################################################################
sub delete {
    my $self = shift;
    my $dbh  = shift;

    my $qry    = "DELETE FROM TagType WHERE id=?;";
    my $sth    = $dbh->prepare($qry);
    my $result = $sth->execute( $self->{id} );
    $self->{id} = undef;

    return $result;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
