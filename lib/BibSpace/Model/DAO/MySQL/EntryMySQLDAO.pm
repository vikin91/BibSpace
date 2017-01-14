# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-14T18:29:16
package EntryMySQLDAO;

use namespace::autoclean;
use Moose;
use BibSpace::Model::DAO::Interface::IEntryDAO;
use BibSpace::Model::Entry;
with 'IEntryDAO';
use Try::Tiny;

# Inherited fields from BibSpace::Model::DAO::Interface::IEntryDAO Mixin:
# has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);
# has 'handle' => ( is => 'ro', required => 1);

=item all
    Method documentation placeholder.
=cut 
sub all {
  my ($self) = @_;
  $self->logger->entering("","".__PACKAGE__."->all");
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
          id              => $row->{id},
          entry_type      => $row->{entry_type},
          bibtex_key      => $row->{bibtex_key},
          _bibtex_type     => $row->{bibtex_type},
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
  $self->logger->exiting("","".__PACKAGE__."->all");
  return @objs;
}

=item save
    Method documentation placeholder.
=cut 
sub save {
  my ($self, @objects) = @_;
  $self->logger->entering("","".__PACKAGE__."->save");
  die "".__PACKAGE__."->save not implemented. Method was instructed to save ".scalar(@objects)." objects.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->save");
}

=item update
    Method documentation placeholder.
=cut 
sub update {
  my ($self, @objects) = @_;
  $self->logger->entering("","".__PACKAGE__."->update");
  die "".__PACKAGE__."->update not implemented. Method was instructed to save ".scalar(@objects)." objects.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->update");
}

=item delete
    Method documentation placeholder.
=cut 
sub delete {
  my ($self, @objects) = @_;
  $self->logger->entering("","".__PACKAGE__."->delete");
  die "".__PACKAGE__."->delete not implemented. Method was instructed to save ".scalar(@objects)." objects.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->delete");
}

=item exists
    Method documentation placeholder.
=cut 
sub exists {
  my ($self, @objects) = @_;
  $self->logger->entering("","".__PACKAGE__."->exists");
  die "".__PACKAGE__."->exists not implemented. Method was instructed to save ".scalar(@objects)." objects.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->exists");
}

=item filter
    Method documentation placeholder.
=cut 
sub filter {
  my ($self, $coderef) = @_;
  $self->logger->entering("","".__PACKAGE__."->filter");
  die "".__PACKAGE__."->filter incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );
  die "".__PACKAGE__."->filter not implemented.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->filter");
}

=item find
    Method documentation placeholder.
=cut 
sub find {
  my ($self, $coderef) = @_;
  $self->logger->entering("","".__PACKAGE__."->find");
  die "".__PACKAGE__."->find incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );
  die "".__PACKAGE__."->find not implemented.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->find");
}

=item count
    Method documentation placeholder.
=cut 
sub count {
  my ($self, $coderef) = @_;
  $self->logger->entering("","".__PACKAGE__."->count");
  die "".__PACKAGE__."->count incorrect type of argument. Got: '".ref($coderef)."', expected: ".(ref sub{})."." unless (ref $coderef eq ref sub{} );
  die "".__PACKAGE__."->count not implemented.";

  # TODO: auto-generated method stub. Implement me!
  $self->logger->exiting("","".__PACKAGE__."->count");
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
