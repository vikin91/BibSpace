package MTeam;
    use Data::Dumper;
    use utf8;
    use Text::BibTeX; # parsing bib files
    use 5.010; #because of ~~ and say
    use DBI;
    use Moose;

   has 'id' => (is => 'rw'); 
   has 'name' => (is => 'rw'); 
   has 'parent' => (is => 'rw');

####################################################################################
sub static_all {
  my $self = shift;
  my $dbh = shift;

  my $qry = "SELECT id,
            name,
            parent
        FROM Team";
  my @objs;
  my $sth = $dbh->prepare( $qry );
  $sth->execute();

  while(my $row = $sth->fetchrow_hashref()) {
    my $obj = MTeam->new(
                          id => $row->{id},
                          name => $row->{name},
                          parent => $row->{parent}
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

  my $qry = "SELECT id,
                    name,
                    parent
          FROM Team
          WHERE id = ?";

  my $sth = $dbh->prepare( $qry );
  $sth->execute($id);
  my $row = $sth->fetchrow_hashref();

  if(!defined $row){
    return undef;
  }

  my $e = MTeam->new();
  $e->{id} = $id;
  $e->{name} = $row->{name};
  $e->{parent} = $row->{parent};
  return $e;
}
####################################################################################
sub update {
  my $self = shift;
  my $dbh = shift;

  my $result = "";


  if(!defined $self->{id}){
      say "Cannot update. MTeam id not set. The entry may not exist in the DB. Returning -1";
      return -1;
  }

  my $qry = "UPDATE Team SET
                name=?,
                parent=?
            WHERE id = ?";
  my $sth = $dbh->prepare( $qry );
  $result = $sth->execute(
            $self->{name},
            $self->{parent},
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
    INSERT INTO Team(
    name,
    parent
    ) 
    VALUES (?,?);";
    my $sth = $dbh->prepare( $qry );
    $result = $sth->execute(
            $self->{name},
            $self->{parent},
            );
  my $inserted_id = $dbh->last_insert_id('', '', 'Team', '');
  $self->{id} = $inserted_id;
  # say "MTeam insert. inserted_id = $inserted_id";
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
    # say "MTeam save: inserting. inserted_id = ".$self->{id};
    return $inserted_id;
  }
  elsif(defined $self->{id} and $self->{id} > 0){
    # say "MTeam save: updating ID = ".$self->{id};
    return $self->update($dbh);
  }
  else{
    warn "MTeam save: cannot either insert nor update :( ID = ".$self->{id};
  }
}
####################################################################################
sub delete {
  my $self = shift;
  my $dbh = shift;


  my $qry = "DELETE FROM Team WHERE id=?;";
  my $sth = $dbh->prepare( $qry );
  my $result = $sth->execute($self->{id});
  $self->{id} = undef;

  return $result;
}
####################################################################################
sub static_get_by_name{
  my $self = shift;
  my $dbh = shift;
  my $name = shift;

  my $sth = $dbh->prepare( "SELECT id FROM Team WHERE name=?" );     
  $sth->execute($name);
  my $row = $sth->fetchrow_hashref();
  my $id = $row->{id} || -1;

  if($id > 0){
    return MTeam->static_get($dbh, $id);
  }
  return undef;
}
####################################################################################
1;