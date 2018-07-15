# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T14:47:33
package DAOFactory;

use namespace::autoclean;

use Moose;
use BibSpace::Util::ILogger;
use BibSpace::DAO::MySQLDAOFactory;

use BibSpace::Util::EntityFactory;

# this class has logger, because it may want to log somethig as well
# thic code forces to instantiate the abstract factory first and then calling getInstance
has 'logger'    => (is => 'ro', does => 'ILogger',       required => 1);
has 'e_factory' => (is => 'ro', isa  => 'EntityFactory', required => 1);

sub getInstance {
  my $self        = shift;
  my $factoryType = shift;
  my $handle      = shift;

  die "EntityFactory is undef!"         unless $self->e_factory;
  die "Factory type not provided!"      unless $factoryType;
  die "Connection handle not provided!" unless $handle;

# $self->logger->debug("Requesting new concreteDOAFactory of type $factoryType.");

  try {
    my $class = $factoryType;
    Class::Load::load_class($class);
    return $class->new(
      logger    => $self->logger,
      handle    => $handle,
      e_factory => $self->e_factory
    );
  }
  catch {
    die "Requested unknown type of DaoFactory: '$factoryType'.";
  };
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
