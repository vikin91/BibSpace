# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T14:47:33
package EntityFactory;

use namespace::autoclean;

use Moose;
use BibSpace::Util::ILogger;
use BibSpace::Util::Preferences;
use BibSpace::Util::IUidProvider;

use BibSpace::Model::Entry;

# this class has logger, because it may want to log somethig as well
# thic code forces to instantiate the abstract factory first and then calling getInstance
has 'logger' => (is => 'ro', does => 'ILogger', required => 1);

# this may be rewritten during backup restore = must be rw (or writable in another way)
has 'preferences' => (is => 'ro', isa => 'Preferences', required => 1);
has 'facade' =>
  (is => 'rw', isa => 'Maybe[FlatRepositoryFacade]', default => undef);

sub new_Entry {
  my ($self, %args) = @_;
  return Entry->new(preferences => $self->preferences, repo => $self->facade,
    %args);
}

sub new_TagType {
  my ($self, %args) = @_;
  return TagType->new(
    preferences => $self->preferences,
    repo        => $self->facade,
    %args
  );
}

sub new_Team {
  my ($self, %args) = @_;
  return Team->new(preferences => $self->preferences, repo => $self->facade,
    %args);
}

sub new_Author {
  my ($self, %args) = @_;
  return Author->new(
    preferences => $self->preferences,
    repo        => $self->facade,
    %args
  );
}

sub new_Tag {
  my ($self, %args) = @_;
  return Tag->new(preferences => $self->preferences, repo => $self->facade,
    %args);
}

sub new_Type {
  my ($self, %args) = @_;
  return Type->new(preferences => $self->preferences, repo => $self->facade,
    %args);
}

sub new_User {
  my ($self, %args) = @_;
  return User->new(preferences => $self->preferences, repo => $self->facade,
    %args);
}

sub new_Authorship {
  my ($self, %args) = @_;
  return Authorship->new(repo => $self->facade, %args);
}

sub new_Membership {
  my ($self, %args) = @_;
  return Membership->new(repo => $self->facade, %args);
}

sub new_Labeling {
  my ($self, %args) = @_;
  return Labeling->new(repo => $self->facade, %args);
}

sub new_Exception {
  my ($self, %args) = @_;
  return Exception->new(repo => $self->facade, %args);
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;
