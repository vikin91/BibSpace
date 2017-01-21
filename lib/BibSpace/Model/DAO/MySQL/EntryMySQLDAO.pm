# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T13:56:17
package EntryMySQLDAO;

use namespace::autoclean;
use Moose;
use BibSpace::Model::DAO::Interface::IDAO;
use BibSpace::Model::Entry;
with 'IDAO';
use Try::Tiny;

# Inherited fields from BibSpace::Model::DAO::Interface::IDAO Mixin:
# has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);
# has 'handle' => ( is => 'ro', required => 1);

=item all
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 
sub all {
  my ($self) = @_;
  my $dbh = $self->handle;
  my $qry = "SELECT
              id,
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
    
  my $sth;
  try{
      $sth= $dbh->prepare($qry);
      $sth->execute();
  }
  catch{
      my $trace = Devel::StackTrace->new;
      $self->logger->error("\n=== TRACE ===\n" . $trace->as_string . "\n=== END TRACE ===\n"); # like carp
  };
  my $dtPattern = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S' );

  my @objs;
  while ( my $row = $sth->fetchrow_hashref() ) {
      my $ct = $dtPattern->parse_datetime($row->{creation_time});
      my $mt = $dtPattern->parse_datetime($row->{modified_time});
      # set defaults
      $ct = DateTime->now unless $ct;
      $mt = DateTime->now unless $mt;
      # say "MEntry->static_all: parsing creation_ and mod_time";

      push @objs,
          Entry->new(
          old_mysql_id    => $row->{id},
          idProvider      => $self->idProvider,
          id              => $row->{id},
          entry_type      => $row->{entry_type},
          bibtex_key      => $row->{bibtex_key},
          _bibtex_type    => $row->{bibtex_type},
          bib             => $row->{bib},
          html            => $row->{html},
          html_bib        => $row->{html_bib},
          abstract        => $row->{abstract},
          title           => $row->{title},
          hidden          => $row->{hidden},
          year            => $row->{year},
          month           => $row->{month},
          sort_month      => $row->{sort_month},
          teams_str       => $row->{teams_str},
          people_str      => $row->{people_str},
          tags_str        => $row->{tags_str},
          creation_time   => $ct,
          modified_time   => $mt, 
          need_html_regen => $row->{need_html_regen},
          );
  }
  return @objs;
}
before 'all' => sub { shift->logger->entering("","".__PACKAGE__."->all"); };
after 'all'  => sub { shift->logger->exiting("","".__PACKAGE__."->all"); };
=item count
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 
sub count {
  my ($self) = @_;

  die "".__PACKAGE__."->count not implemented.";
  # TODO: auto-generated method stub. Implement me!

}
before 'count' => sub { shift->logger->entering("","".__PACKAGE__."->count"); };
after 'count'  => sub { shift->logger->exiting("","".__PACKAGE__."->count"); };
=item empty
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 
sub empty {
  my ($self) = @_;

  die "".__PACKAGE__."->empty not implemented.";
  # TODO: auto-generated method stub. Implement me!

}
before 'empty' => sub { shift->logger->entering("","".__PACKAGE__."->empty"); };
after 'empty'  => sub { shift->logger->exiting("","".__PACKAGE__."->empty"); };

=item exists
    Method documentation placeholder.
    This method takes single object as argument and returns a scalar.
=cut 
sub exists {
  my ($self, $object) = @_;
  my $dbh = $self->handle;
  my $sth = $dbh->prepare("SELECT COUNT(id) AS num FROM Entry WHERE id=?");
  $sth->execute($object->id);
  my $row = $sth->fetchrow_hashref();
  my $num = $row->{num} // 0;
  return $num > 0;

}
before 'exists' => sub { shift->logger->entering("","".__PACKAGE__."->exists"); };
after 'exists'  => sub { shift->logger->exiting("","".__PACKAGE__."->exists"); };

=item save
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub save {
  my ($self, @objects) = @_;
  my $dbh = $self->handle;

  foreach my $obj (@objects){
    if ( $self->exists($obj) ) {
      $self->update($obj);
      $self->logger->info("Updated object ID ".$obj->id." in DB.","".__PACKAGE__."->save");
    }
    else {
      $self->_insert($obj);
      $self->logger->info("Inserted object ID ".$obj->id." into DB.","".__PACKAGE__."->save");
    }
  }
}

=item _insert
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub _insert {
  my ($self, @objects) = @_;
  my $dbh = $self->handle;
  my $qry = "
    INSERT INTO Entry(
    id,
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
    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,NOW(),NOW(),?);";
  
  foreach my $obj (@objects){
    my $sth = $dbh->prepare($qry);
    try{
      my $result = $sth->execute(
          $obj->{id}, $obj->{entry_type}, $obj->{bibtex_key}, $obj->{_bibtex_type},
          $obj->{bib}, $obj->{html}, $obj->{html_bib}, $obj->{abstract},
          $obj->{title}, $obj->{hidden}, $obj->{year}, $obj->{month},
          $obj->{sort_month}, $obj->{teams_str}, $obj->{people_str},
          $obj->{tags_str},

          # $obj->{creation_time},
          # $obj->{modified_time},
          $obj->{need_html_regen},
      );
      $sth->finish();
    }
    catch {
      $self->logger->error("Insert exception: $_","".__PACKAGE__."->insert");
    };
  }
}
before 'save' => sub { shift->logger->entering("","".__PACKAGE__."->save"); };
after 'save'  => sub { shift->logger->exiting("","".__PACKAGE__."->save"); };
=item update
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub update {
  my ($self, @objects) = @_;
  my $dbh = $self->handle;

  foreach my $obj (@objects){
    next if !defined $obj->id;
    # update field 'modified_time' only if needed
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
            need_html_regen=?";
    $qry .= ", modified_time=NOW()" if $obj->shall_update_modified_time == 1;
    $qry .= "WHERE id = ?";

    my $sth = $dbh->prepare($qry);
    try {
        my $result = $sth->execute(
            $obj->{entry_type},  $obj->{bibtex_key},
            $obj->{_bibtex_type}, $obj->{bib},
            $obj->{html},        $obj->{html_bib},
            $obj->{abstract},    $obj->{title},
            $obj->{hidden},      $obj->{year},
            $obj->{month},       $obj->{sort_month},
            $obj->{teams_str},   $obj->{people_str},
            $obj->{tags_str},    $obj->{need_html_regen},
            $obj->{id}
        );
        $sth->finish();
    }
    catch {
      $self->logger->error("Update exception: $_","".__PACKAGE__."->update");
    };
  }

}
before 'update' => sub { shift->logger->entering("","".__PACKAGE__."->update"); };
after 'update'  => sub { shift->logger->exiting("","".__PACKAGE__."->update"); };
=item delete
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub delete {
  my ($self, @objects) = @_;
  my $dbh = $self->handle;
  foreach my $obj (@objects){
    my $qry    = "DELETE FROM Entry WHERE id=?;";
    my $sth    = $dbh->prepare($qry);
    try{
      my $result = $sth->execute( $obj->{id} );
    }
    catch {
      $self->logger->error("Delete exception: $_","".__PACKAGE__."->delete");
    };
  }

}
before 'delete' => sub { shift->logger->entering("","".__PACKAGE__."->delete"); };
after 'delete'  => sub { shift->logger->exiting("","".__PACKAGE__."->delete"); };

=item filter
    Method documentation placeholder.
=cut 
sub filter {
  my ($self, $coderef) = @_;
  die "".__PACKAGE__."->filter incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );

  die "".__PACKAGE__."->filter not implemented.";
  # TODO: auto-generated method stub. Implement me!
  
}
before 'filter' => sub { shift->logger->entering("","".__PACKAGE__."->filter"); };
after 'filter'  => sub { shift->logger->exiting("","".__PACKAGE__."->filter"); };
=item find
    Method documentation placeholder.
=cut 
sub find {
  my ($self, $coderef) = @_;
  die "".__PACKAGE__."->find incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );

  die "".__PACKAGE__."->find not implemented.";
  # TODO: auto-generated method stub. Implement me!
  
}
before 'find' => sub { shift->logger->entering("","".__PACKAGE__."->find"); };
after 'find'  => sub { shift->logger->exiting("","".__PACKAGE__."->find"); };
__PACKAGE__->meta->make_immutable;
no Moose;
1;
