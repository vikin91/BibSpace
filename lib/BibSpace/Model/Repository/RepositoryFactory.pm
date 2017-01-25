# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T15:07:35
package RepositoryFactory;
use namespace::autoclean;
use Moose;
use BibSpace::Model::ILogger;
require BibSpace::Model::Repository::LayeredRepositoryFactory;


sub getInstance {
  my $self               = shift;
  my $factoryType        = shift;
  my $logger             = shift;
  my $backendsConfigHash = shift;

  print "ftype: $factoryType\n";

  die "Factory type not provided!" unless $factoryType;
  die "Repository backends not provided!" unless defined $backendsConfigHash;

  my @sortedBackendConfigs = sort { $a->{'prio'} <=> $b->{'prio'} } @{ $backendsConfigHash->{'backends'} };
  $backendsConfigHash->{'backends'} = \@sortedBackendConfigs;

  my $concreteFactoryClass = $factoryType;
  try {
    Class::Load::load_class($concreteFactoryClass);
    return $concreteFactoryClass->new( logger => $logger )->getInstance($backendsConfigHash);
  }
  catch {
    die "Requested unknown type of RepositoryFactory: '$concreteFactoryClass'.";
  };
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;
