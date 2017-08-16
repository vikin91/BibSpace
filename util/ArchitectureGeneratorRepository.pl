use strict;
use warnings;
use v5.10;
use Template;
use DateTime;
use File::Basename;
use File::Path qw/make_path/;

package main;

my $header = "# This code was auto-generated using ArchitectureGenerator.pl on "
  . DateTime->now();

# Methods:
# = first layer: all exists filter find count
# == no arg: all count
# == obj arg: exists
# == coderef arg: filter find
# = all layers: save update delete
# == array arg: save update delete

# WARNING: YOU MAY OVERWRITE BIBSPACE::MODEL::REPOSITORY WITH THE GENERATED CODE WITHOUT LOOSING ANYTHING
# WARNING: YOU MAY __NOT__ OVERWRITE BIBSPACE::MODEL::DAO WITH THE GENERATED CODE.
#   IF YOU DO SO, YOU WILL LOOSE THE CODE THAT IS RESPONSIBLE FOR SAVING, READING, .. OF THE BUSINESS ENTITY ENTRIES
#   YOU MAY HOWEVER OVERWRITE SELECTED PARTS OF IT (FACTORIES, NEW-BACKEND-RELATED CODE), E.G. IF YOU WANT TO ADD A NEW BACKEND

my %be
  = qw(Entry Entries Author Authors Team Teams Tag Tags TagType TagTypes Authorship Authorships Membership Memberships Labeling Labellings Exception Exceptions);
my $vars = {
  header               => $header,
  app_prefix           => 'BibSpace::Model::',
  logger_interface     => 'ILogger',
  idProvider_interface => 'IUidProvider',
  repo_package_prefix  => 'BibSpace::Model::Repository::',
  dao_package_prefix   => 'BibSpace::Model::DAO::',

  # plural and singular
  business_entities_hash => \%be,
  methods_all => [qw/all count save update delete exists filter find/],

  # take no arguments, returns
  methods_read => [qw/all count empty/],

  # take object as argument
  methods_check => [qw/exists/],

  # take object or array of objects as argument
  methods_write => [qw/save update delete/],

  # take coderef as argument
  methods_search       => [qw/filter find/],
  persistence_backends => ['MySQL', 'Redis', 'SmartArray'],
  repository_types     => ['Layered'],
};

my $DAOAbstractFactoryPackageName = "DAOFactory";
my $DAOAbstractFactoryPackagePath
  = "BibSpace::Model::DAO::$DAOAbstractFactoryPackageName";

sub printToFile {
  my $package  = shift;
  my $template = shift;
  my $vars     = shift;

  $package =~ s/::/\//g;
  my $file = "./$package";
  my $dir  = dirname($file);
  make_path($dir);
  open(my $fh, '>', $file) or die $_;
  Template->new({ENCODING => 'utf8', INTERPOLATE => 0})
    ->process(\$template, $vars, $fh);
  close $fh;
}

################# DAO ABSTRACT FACTORY
{
  my $package     = "DAOFactory";
  my $filePackage = "$vars->{dao_package_prefix}$package";

  my $absDaoFactory = <<CUT;
[% SET package = '$package' -%]
[% header %]
package [% package %];

use namespace::autoclean;
use Moose;
use [% app_prefix %][% logger_interface %];
[% FOREACH backend = persistence_backends -%]
use [% dao_package_prefix %][% backend %]DAOFactory;
[% END -%]

# this class has logger, because it may want to log somethig as well 
# thic code forces to instantiate the abstract factory first and then calling getInstance
has 'logger' => ( is => 'ro', does => '[% logger_interface %]', required => 1);


sub getInstance {
    my \$self        = shift;
    my \$factoryType = shift;
    my \$handle      = shift;

    die "Factory type not provided!" unless \$factoryType;
    die "Connection handle not provided!" unless \$handle;
    \$self->logger->debug("Requesting new concreteDOAFactory of type \$factoryType.","".__PACKAGE__."->getInstance");

    try{
        my \$class = \$factoryType;
        Class::Load::load_class(\$class);
        return \$class->new( logger => \$self->logger, handle => \$handle );
    }
    catch{
        die "Requested unknown type of DaoFactory: '\$factoryType'.";
    };
}
before 'getInstance' => sub { shift->logger->entering("","".__PACKAGE__."->getInstance"); };
after 'getInstance'  => sub { shift->logger->exiting("","".__PACKAGE__."->getInstance"); };
__PACKAGE__->meta->make_immutable;
no Moose;
1;
CUT
  printToFile("$filePackage.pm", $absDaoFactory, $vars);
}
################# DAO CONCRETE FACTORY

foreach my $backend (@{$vars->{persistence_backends}}) {
  my $package           = "$backend" . "DAOFactory";
  my $filePackage       = "$vars->{dao_package_prefix}$package";
  my $backendDaoFactory = <<CUT;
[% SET backend = '$backend' -%]
[% SET package = '$package' -%]
[% header %]
package [% package %];

use namespace::autoclean;
use Moose;
use [% app_prefix %][% logger_interface %];
[% FOREACH entity = business_entities_hash.keys -%]
use [% dao_package_prefix %][% backend %]::[% entity %][% backend %]DAO;
[% END -%]
use [% dao_package_prefix %]DAOFactory;
extends 'DAOFactory';

has 'handle' => ( is => 'ro', required => 1 );
has 'logger' => ( is => 'ro', does => '[% logger_interface %]', required => 1);


[% FOREACH entity = business_entities_hash.keys -%]
sub get[% entity %]Dao {
    my \$self = shift;
    my \$idProvider = shift;
    die "".__PACKAGE__."->get[% entity %]Dao MUST be called with valid idProvider!" if !defined \$idProvider;
    return [% entity %][% backend %]DAO->new( idProvider=> \$idProvider, logger=>\$self->logger, handle => \$self->handle );
}
before 'get[% entity %]Dao' => sub { shift->logger->entering("","".__PACKAGE__."->get[% entity %]Dao"); };
after 'get[% entity %]Dao'  => sub { shift->logger->exiting("","".__PACKAGE__."->get[% entity %]Dao"); };
[% END -%]
__PACKAGE__->meta->make_immutable;
no Moose;
1;
CUT

  printToFile("$filePackage.pm", $backendDaoFactory, $vars);
}

################# DAO BUSINESS ENTITY DAO INTERFACE

{
  my $package            = "IDAO";
  my $filePackage        = "$vars->{dao_package_prefix}Interface::$package";
  my $entityDaoInterface = <<CUT;
[% SET package = '$package' -%]
[% header %]
package [% package %];

use namespace::autoclean;
use Moose::Role; # = this package (class) is an interface
# Perl interfaces (Roles) can contain attributes =)
# In Java this interface would differ from other DAO::ENTITY interfaces.
# classes that implement this interface must provide the following functions
[% FOREACH method = methods_all -%]
requires '[% method %]';
[% END -%]

has 'logger' => ( is => 'ro', does => '[% logger_interface %]', required => 1);
# e.g. database connection handle
has 'handle' => ( is => 'ro', required => 1);
has 'idProvider' => ( is => 'ro', does => '[% idProvider_interface %]', required => 1);
1;
CUT

  printToFile("$filePackage.pm", $entityDaoInterface, $vars);
}

################# DAO BUSINESS ENTITY DAO

foreach my $backend (@{$vars->{persistence_backends}}) {
  foreach my $entity (keys %{$vars->{business_entities_hash}}) {
    my $package          = "$entity" . "$backend" . "DAO";
    my $filePackage      = "$vars->{dao_package_prefix}$backend" . "::$package";
    my $entityDaoBackend = <<CUT;
[% SET entity = '$entity' -%]
[% SET backend = '$backend' -%]
[% SET package = '$package' -%]
[% header %]
package [% package %];

use namespace::autoclean;
use Moose;
use [% dao_package_prefix %]Interface::IDAO;
use [% app_prefix %][% entity %];
with 'IDAO';
use Try::Tiny;

# Inherited fields from [% dao_package_prefix %]Interface::IDAO Mixin:
# has 'logger' => ( is => 'ro', does => '[% logger_interface %]', required => 1);
# has 'handle' => ( is => 'ro', required => 1);

[% FOREACH method = methods_read -%]
=item [% method %]
    Method documentation placeholder.
    This method takes no arguments and returns array or scalar.
=cut 
sub [% method %] {
  my (\$self) = \@_;

  die "".__PACKAGE__."->[% method %] not implemented.";
  # TODO: auto-generated method stub. Implement me!

}
before '[% method %]' => sub { shift->logger->entering("","".__PACKAGE__."->[% method %]"); };
after '[% method %]'  => sub { shift->logger->exiting("","".__PACKAGE__."->[% method %]"); };
[% END -%]

[% FOREACH method = methods_check -%]
=item [% method %]
    Method documentation placeholder.
    This method takes single object as argument and returns a scalar.
=cut 
sub [% method %] {
  my (\$self, \$object) = \@_;
  
  die "".__PACKAGE__."->[% method %] not implemented.";
  # TODO: auto-generated method stub. Implement me!

}
before '[% method %]' => sub { shift->logger->entering("","".__PACKAGE__."->[% method %]"); };
after '[% method %]'  => sub { shift->logger->exiting("","".__PACKAGE__."->[% method %]"); };
[% END -%]

[% FOREACH method = methods_write -%]
=item [% method %]
    Method documentation placeholder.
    This method takes single object or array of objects as argument and returns nothing.
=cut 
sub [% method %] {
  my (\$self, \@objects) = \@_;

  die "".__PACKAGE__."->[% method %] not implemented. Method was instructed to [% method %] ".scalar(\@objects)." objects.";
  # TODO: auto-generated method stub. Implement me!

}
before '[% method %]' => sub { shift->logger->entering("","".__PACKAGE__."->[% method %]"); };
after '[% method %]'  => sub { shift->logger->exiting("","".__PACKAGE__."->[% method %]"); };
[% END -%]

[% FOREACH method = methods_search -%]
=item [% method %]
    Method documentation placeholder.
=cut 
sub [% method %] {
  my (\$self, \$coderef) = \@_;
  die "".__PACKAGE__."->[% method %] incorrect type of argument. Got: '".ref(\$coderef)."', expected: ".(ref sub{})."." unless (ref \$coderef eq ref sub{} );

  die "".__PACKAGE__."->[% method %] not implemented.";
  # TODO: auto-generated method stub. Implement me!
  
}
before '[% method %]' => sub { shift->logger->entering("","".__PACKAGE__."->[% method %]"); };
after '[% method %]'  => sub { shift->logger->exiting("","".__PACKAGE__."->[% method %]"); };
[% END -%]
__PACKAGE__->meta->make_immutable;
no Moose;
1;
CUT

    printToFile("$filePackage.pm", $entityDaoBackend, $vars);
  }
}

############################# REPOSITORY ############################################

################# ABSTRACT REPOSITORY FACTORY
{
  my $package        = "RepositoryFactory";
  my $filePackage    = "$vars->{repo_package_prefix}$package";
  my $absRepoFactory = <<CUT;
[% SET package = '$package' -%]
[% header %]
package [% package %];
use namespace::autoclean;
use Moose;
use [% app_prefix %][% logger_interface %];
[% FOREACH repoType = repository_types -%]
require [% repo_package_prefix %][% repoType %]RepositoryFactory;
[% END -%]

# this class has logger, because it may want to log somethig as well 
# thic code forces to instantiate the abstract factory first and then calling getInstance
has 'logger' => ( is => 'ro', does => '[% logger_interface %]', required => 1);

=item _sortBackends 
    Sorts backends based on prio. Lower prio = more important for reading = probably faster backend.
    Perl Tip: The '_' means that the method is private.
=cut
sub _sortBackends {
    my \$self = shift;
    my \$backendsConfigHash = shift;

    my \@sortedBackendConfigs = sort { \$a->{'prio'} <=> \$b->{'prio'}} \@{ \$backendsConfigHash->{'backends'} };
    \$backendsConfigHash->{'backends'} = \\\@sortedBackendConfigs;
    return \$backendsConfigHash;
}

sub getInstance {
    my \$self        = shift;
    my \$factoryType = shift;
    my \$backendsConfigHash     = shift;

    die "Factory type not provided!" unless \$factoryType;
    die "Repository backends not provided!" unless defined \$backendsConfigHash;

    \$backendsConfigHash = \$self->_sortBackends(\$backendsConfigHash);

    my \$concreteFactoryClass = \$factoryType;
    try{
        Class::Load::load_class(\$concreteFactoryClass);
        return \$concreteFactoryClass->new(logger=> \$self->logger)->getInstance( \$backendsConfigHash );
    }
    catch{
        die "Requested unknown type of RepositoryFactory: '\$concreteFactoryClass'.";
    };
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;
CUT
  printToFile("$filePackage.pm", $absRepoFactory, $vars);
}
################# CONCRETE REPOSITORY FACTORY

foreach my $repoType (@{$vars->{repository_types}}) {
  my $package                 = "$repoType" . "RepositoryFactory";
  my $filePackage             = "$vars->{repo_package_prefix}$package";
  my $repoTypeConcreteFactory = <<CUT;
[% SET backend = '$repoType' -%]
[% SET package = '$package' -%]
[% header %]
package [% package %];
use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;
use Try::Tiny;

use [% app_prefix %]IUidProvider;
use [% repo_package_prefix %]Interface::IRepository;
[% FOREACH entityPair IN business_entities_hash.pairs -%]
use [% repo_package_prefix %][% backend %]::[% entityPair.value %][% backend %]Repository;
[% END -%]
require [% repo_package_prefix %]RepositoryFactory;
extends 'RepositoryFactory';

has 'backendsConfigHash' => ( is => 'rw', isa => 'Maybe[HashRef]');
has 'logger' => ( is => 'ro', does => '[% logger_interface %]', required => 1);

# class_has = static field
# This is important to guanartee, that there is only one reposiotory per system.
# Method getxxxRepostory guarantees that defined field will not be overwritten
[% FOREACH entityPair IN business_entities_hash.pairs -%]
has '_instance[% entityPair.value %]Repo' => ( is => 'rw', does => 'Maybe[IRepository]', default => undef);
[% END -%]

[% FOREACH entityPair IN business_entities_hash.pairs -%]
has '_idProvider[% entityPair.key %]' => ( is => 'rw', does => 'Maybe[IUidProvider]', default => undef, reader => 'idProvider[% entityPair.key %]');
[% END -%]

=item getInstance 
    This is supposed to be static constructor (factory) method.
    Unfortunately, the default constructor has not been disabled yet.
=cut
sub getInstance {
    my \$self            = shift;
    my \$backendsConfigHash = shift;

    die "".__PACKAGE__."->getInstance: repo backends not provided or not of type 'Hash'." unless (ref \$backendsConfigHash eq ref {} );
    if( !defined \$self->backendsConfigHash){
        \$self->backendsConfigHash(\$backendsConfigHash);
    }
    return \$self;
}

[% FOREACH entityPair IN business_entities_hash.pairs -%]
sub get[% entityPair.value %]Repository {
    my \$self = shift;
    if( !defined \$self->{_idProvider[% entityPair.key %]} ){
        \$self->logger->debug("Initializing instance of idProvider[% entityPair.key %].", "".__PACKAGE__."->get[% entityPair.value %]Repository");
        my \$idProviderTypeClass = \$self->backendsConfigHash->{'idProviderType'};
        try{
            Class::Load::load_class(\$idProviderTypeClass);
            my \$providerInstance = \$idProviderTypeClass->new();
            \$self->{_idProvider[% entityPair.key %]} = \$providerInstance;
        }
        catch{
            \$self->logger->error("Requested unknown type of [% idProvider_interface %] : '\$idProviderTypeClass'.", "".__PACKAGE__."->get[% entityPair.value %]Repository");
            die "Requested unknown type of [% idProvider_interface %] : '\$idProviderTypeClass'.";
        };
    }
    if( !defined \$self->{_instance[% entityPair.value %]Repo} ){
        \$self->logger->debug("Initializing field instance[% entityPair.value %]Repo.", "".__PACKAGE__."->get[% entityPair.value %]Repository");
        \$self->{_instance[% entityPair.value %]Repo} =
            [% entityPair.value %][% backend %]Repository->new( 
                _idProvider => \$self->{_idProvider[% entityPair.key %]},
                logger => \$self->logger,
                backendsConfigHash => \$self->backendsConfigHash 
            );
    }
    return \$self->{_instance[% entityPair.value %]Repo};
}
[% END -%]
__PACKAGE__->meta->make_immutable;
no Moose;
1;
CUT

  printToFile("$filePackage.pm", $repoTypeConcreteFactory, $vars);
}

#################  REPOSITORY INTERFACE

# foreach my $entity ( keys %{ $vars->{business_entities_hash} } )
{
  my $package     = "IRepository";
  my $filePackage = "$vars->{repo_package_prefix}Interface::$package";
  my $entityRespositoryInterface = <<CUT;
[% SET package = '$package' -%]
[% SET DAOAbstractFactoryPackageName = '$DAOAbstractFactoryPackageName' -%]
[% SET DAOAbstractFactoryPackagePath = '$DAOAbstractFactoryPackagePath' -%]
[% header %]
package [% package %];
use namespace::autoclean;


use Moose::Role; # = this package (class) is an interface
# Perl interfaces (Roles) can contain attributes =)
# In fact, Perl roles are Mixins: https://en.wikipedia.org/wiki/Mixin
# classes that implement this interface must provide the following functions
[% FOREACH method = methods -%]
requires '[% method %]';
[% END -%]
use [% DAOAbstractFactoryPackagePath %];
use List::MoreUtils;

=item backendsConfigHash 
    The backendsConfigHash should look like:
    {
      backends => [
        { prio => 1, type => ‘Redis’, handle => \$redisHandle },
        { prio => 2, type => ‘SQL’, handle => \$dbh },
      ]
    }
=cut
has 'backendsConfigHash' => ( is => 'ro', isa => 'HashRef', coerce => 0, traits => [ 'Hash' ], required => 1 );
# this parameter is lazy, because the builder routine depends on logger. Logger will be set as first (is non-lazy).
has 'logger' => ( is => 'ro', does => '[% logger_interface %]', required => 1);
has '_idProvider' => ( is => 'ro', does => 'IUidProvider', required => 1, lazy => 0 );
has 'backendDaoFactory'  => ( is => 'ro', isa => '[% DAOAbstractFactoryPackageName %]', lazy => 1, builder => '_buildDAOFactory' );

[% FOREACH method = methods_all -%]
requires '[% method %]';
[% END -%]

sub _buildDAOFactory{
    my \$self = shift;
    return [% DAOAbstractFactoryPackageName %]->new(logger => \$self->logger);
}

sub getBackendsArray{
    my \$self = shift;
    # this is sorted by 'prio' in the RepositoryFacotry
    return \@{ \$self->backendsConfigHash->{'backends'} };
}

1;
CUT

  printToFile("$filePackage.pm", $entityRespositoryInterface, $vars);
}

################# BUSINESS ENTITY Repo

foreach my $backend (@{$vars->{repository_types}}) {
  foreach my $entity (keys %{$vars->{business_entities_hash}}) {

    my $package
      = "$vars->{business_entities_hash}->{$entity}"
      . "$backend"
      . "Repository";
    my $filePackage
      = "$vars->{repo_package_prefix}$backend" . "::" . "$package";
    my $entityRepoBackend = <<CUT;
[% SET entity = '$entity' -%]
[% SET backend = '$backend' -%]
[% SET package = '$package' -%]
[% SET DAOAbstractFactoryPackageName = '$DAOAbstractFactoryPackageName' -%]
[% SET DAOAbstractFactoryPackagePath = '$DAOAbstractFactoryPackagePath' -%]
[% header %]
package [% package %];
use namespace::autoclean;
use Moose;
require [% repo_package_prefix %]Interface::IRepository;
with 'IRepository';
use [% app_prefix %][% entity %];
use Try::Tiny; # for try/catch
use List::Util qw(first);
use List::MoreUtils;


=item _getReadBackend 
    Returns backend with lowest 'prio' value from \$backendsConfigHash
=cut
sub _getReadBackend {
  my \$self = shift;

  if( !defined \$self->backendsConfigHash ){
    die "".__PACKAGE__."->_getReadBackendType: backendsConfigHash is not defined";
  }
  my \@backendsArray = \$self->getBackendsArray;
  my \$prioHash = shift \@backendsArray;
  if( !\$prioHash ){
    die "".__PACKAGE__."->_getReadBackendType: backend config hash for lowest prio (read) backend is not defined";
  }
  return \$prioHash;
}

=item _getBackendWithPrio 
    Returns backend with given 'prio' value from \$backendsConfigHash
=cut
sub _getBackendWithPrio {
  my \$self = shift;
  my \$prio = shift;

  if( !defined \$self->backendsConfigHash ){
    die "".__PACKAGE__."->_getReadBackendType: backendsConfigHash is not defined";
  }
  my \@backendsArray = \$self->getBackendsArray;
  my \$prioHash = first {\$_->{'prio'} == \$prio} \@backendsArray;
  if( !\$prioHash ){
    die "".__PACKAGE__."->_getReadBackendType: backend config hash for prio '\$prio' is not defined";
  }
  return \$prioHash;
}

=item copy 
    Copies all entries from backend with prio \$fromLayer to backend with prio \$toLayer
=cut
sub copy{
    my (\$self, \$fromLayer, \$toLayer) = \@_;
    \$self->logger->debug("Copying all [% entity %] from layer \$fromLayer to layer \$toLayer.","".__PACKAGE__."->copy");

    my \@resultRead = \$self->backendDaoFactory->getInstance( 
        \$self->_getBackendWithPrio(\$fromLayer)->{'type'},
        \$self->_getBackendWithPrio(\$fromLayer)->{'handle'} 
    )->get[% entity %]Dao(\$self->{_idProvider})->all();

    \$self->logger->debug(scalar(\@resultRead)." [% entity %] read from layer \$fromLayer.","".__PACKAGE__."->copy");
    
    my \$resultSave = \$self->backendDaoFactory->getInstance( 
        \$self->_getBackendWithPrio(\$toLayer)->{'type'},
        \$self->_getBackendWithPrio(\$toLayer)->{'handle'}
    )->get[% entity %]Dao(\$self->{_idProvider})->save( \@resultRead );

    \$self->logger->debug(" \$resultSave [% entity %] saved to layer \$toLayer.","".__PACKAGE__."->copy");
}
before 'copy' => sub { shift->logger->entering("","".__PACKAGE__."->copy"); };
after 'copy'  => sub { shift->logger->exiting("","".__PACKAGE__."->copy"); };

### READ METHODS

[% FOREACH method = methods_read -%]
=item [% method %]
    Method documentation placeholder.
=cut 
sub [% method %] {
    my (\$self) = \@_;
    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    my \$daoFactoryType = \$self->_getReadBackend()->{'type'};
    my \$daoBackendHandle = \$self->_getReadBackend()->{'handle'};
    my \$result;
    try{
        return \$self->backendDaoFactory
            ->getInstance( \$daoFactoryType, \$daoBackendHandle )
            ->get[% entity %]Dao(\$self->{_idProvider})
            ->[% method %]();
    }
    catch{
        print;
    };
}
before '[% method %]' => sub { shift->logger->entering("","".__PACKAGE__."->[% method %]"); };
after '[% method %]'  => sub { shift->logger->exiting("","".__PACKAGE__."->[% method %]"); };
[% END -%]

### CKECK METHODS

[% FOREACH method = methods_check -%]
=item [% method %]
    Method documentation placeholder.
=cut 
sub [% method %] {
    my (\$self, \$obj) = \@_;
    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    my \$daoFactoryType = \$self->_getReadBackend()->{'type'};
    my \$daoBackendHandle = \$self->_getReadBackend()->{'handle'};
    my \$result;
    try{
        return \$self->backendDaoFactory
            ->getInstance( \$daoFactoryType, \$daoBackendHandle )
            ->get[% entity %]Dao(\$self->{_idProvider})
            ->[% method %](\$obj);
    }
    catch{
        print;
    };
}
before '[% method %]' => sub { shift->logger->entering("","".__PACKAGE__."->[% method %]"); };
after '[% method %]'  => sub { shift->logger->exiting("","".__PACKAGE__."->[% method %]"); };
[% END -%]

### WRITE METHODS

[% FOREACH method = methods_write -%]
=item [% method %]
    Method documentation placeholder.
=cut 
sub [% method %] {
    my (\$self, \@objects) = \@_;
    die "".__PACKAGE__."->[% method %] argument 'objects' is undefined." unless \@objects;

    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value

    foreach my \$backendDAO ( \$self->getBackendsArray() ){
        my \$daoFactoryType = \$backendDAO->{'type'};
        my \$daoBackendHandle = \$backendDAO->{'handle'};
        try{
            \$self->backendDaoFactory->getInstance( \$daoFactoryType, \$daoBackendHandle )
              ->get[% entity %]Dao(\$self->{_idProvider})
              ->[% method %]( \@objects );
        }
        catch{
            print;
        };
    }
}
before '[% method %]' => sub { shift->logger->entering("","".__PACKAGE__."->[% method %]"); };
after '[% method %]'  => sub { shift->logger->exiting("","".__PACKAGE__."->[% method %]"); };
[% END -%]

### SEARCH METHODS

[% FOREACH method = methods_search -%]
=item [% method %]
    Method documentation placeholder.
=cut 
sub [% method %] {
    my (\$self, \$coderef) = \@_;
    die "".__PACKAGE__."->[% method %] 'coderef' is undefined." unless defined \$coderef;
    if( ref \$coderef ne ref sub{} ){
        die "".__PACKAGE__."->[% method %] incorrect type of argument. Got: ".ref(\$coderef).", expected: ".(ref sub{}).".";
    }

    # WARNING! Design assumption: write to all backends, but read and search from the one with the lowest 'prio' value
    my \@result;
    my \$daoFactoryType = \$self->_getReadBackend()->{'type'};
    my \$daoBackendHandle = \$self->_getReadBackend()->{'handle'};
    try{
        return \$self->backendDaoFactory->getInstance( \$daoFactoryType, \$daoBackendHandle )
            ->get[% entity %]Dao(\$self->{_idProvider})
            ->[% method %]( \$coderef );
    }
    catch{
        print;
    };
}
before '[% method %]' => sub { shift->logger->entering("","".__PACKAGE__."->[% method %]"); };
after '[% method %]'  => sub { shift->logger->exiting("","".__PACKAGE__."->[% method %]"); };
[% END -%]
__PACKAGE__->meta->make_immutable;
no Moose;
1;
CUT

    printToFile("$filePackage.pm", $entityRepoBackend, $vars);
  }
}

