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
has 'id_provider' => (is => 'rw', isa => 'SmartUidProvider', required => 1);
has 'preferences' => (is => 'ro', isa => 'Preferences',      required => 1);
has 'facade' =>
  (is => 'rw', isa => 'Maybe[FlatRepositoryFacade]', default => undef);

sub new_Entry {
  my ($self, %args) = @_;
  return Entry->new(
    idProvider  => $self->id_provider->get_provider('Entry'),
    preferences => $self->preferences,
    repo        => $self->facade,
    %args
  );
}

sub new_TagType {
  my ($self, %args) = @_;
  return TagType->new(
    idProvider  => $self->id_provider->get_provider('TagType'),
    preferences => $self->preferences,
    repo        => $self->facade,
    %args
  );
}

sub new_Team {
  my ($self, %args) = @_;
  return Team->new(
    idProvider  => $self->id_provider->get_provider('Team'),
    preferences => $self->preferences,
    repo        => $self->facade,
    %args
  );
}

sub new_Author {
  my ($self, %args) = @_;
  return Author->new(
    idProvider  => $self->id_provider->get_provider('Author'),
    preferences => $self->preferences,
    repo        => $self->facade,
    %args
  );
}

sub new_Tag {
  my ($self, %args) = @_;
  return Tag->new(
    idProvider  => $self->id_provider->get_provider('Tag'),
    preferences => $self->preferences,
    repo        => $self->facade,
    %args
  );
}

sub new_Type {
  my ($self, %args) = @_;
  return Type->new(
    idProvider  => $self->id_provider->get_provider('Type'),
    preferences => $self->preferences,
    repo        => $self->facade,
    %args
  );
}

sub new_User {
  my ($self, %args) = @_;
  return User->new(
    idProvider  => $self->id_provider->get_provider('User'),
    preferences => $self->preferences,
    repo        => $self->facade,
    %args
  );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
