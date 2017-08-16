use strict;
use warnings;
use v5.10;
use Template;
use DateTime;
use File::Basename;
use File::Path qw/make_path/;

################################### Example of business entity for testing
package Entry;
use Moose;
has 'bib' => (is => 'rw', isa => 'Str');
has 'year' => (is => 'rw', isa => 'Int', default => 2017);
__PACKAGE__->meta->make_immutable;
no Moose;

package BibSpace::Model::ILogger;
use Moose::Role;
use DateTime;

sub log {
  my $self   = shift;
  my $type   = shift;                 # info, warn, error, debug
  my $msg    = shift;                 # text to log
  my $origin = shift // "unknown";    # method from where the msg originates
  my $time   = DateTime->now();
  print "\t[$time] $type: $msg (Origin: $origin).\n";
}

sub debug {
  my $self   = shift;
  my $msg    = shift;
  my $origin = shift // 'unknown';
  $self->log('debu', $msg, $origin);
}

sub entering {
  my $self   = shift;
  my $msg    = shift;
  my $origin = shift // 'unknown';
  $self->log('ente', $msg, $origin);
}

sub exiting {
  my $self   = shift;
  my $msg    = shift;
  my $origin = shift // 'unknown';
  $self->log('exit', $msg, $origin);
}

sub info {
  my $self   = shift;
  my $msg    = shift;
  my $origin = shift // 'unknown';
  $self->log('info', $msg, $origin);
}

sub warn {
  my $self   = shift;
  my $msg    = shift;
  my $origin = shift // 'unknown';
  $self->log('warn', $msg, $origin);
}

sub error {
  my $self   = shift;
  my $msg    = shift;
  my $origin = shift // 'unknown';
  $self->log('erro', $msg, $origin);
}

no Moose;

package BibSpace::Model::SimpleLogger;
use Moose;
with 'BibSpace::Model::ILogger';

sub debug {
  my $self = shift;
  my $msg  = shift;
  my $time = DateTime->now();
  print "[$time] DEBU: $msg\n";
}

__PACKAGE__->meta->make_immutable;
no Moose;

package main;

## lets see if this generates properly
use Try::Tiny;

try {
  # use BibSpace::Model::DAO::DAOFactory;

  my $dbHandle    = "DB stuff";       # DBI->connect(...)
  my $redisHandle = "Redis stuff";    # Redis->connect(...)

  my $logger = BibSpace::Model::SimpleLogger->new();

  my %backendConfig = (
    backends => [
      {
        prio   => 1,
        type   => 'BibSpace::Model::DAO::ArrayDAOFactory',
        handle => "NOHANDLE"
      },
      {
        prio   => 2,
        type   => 'BibSpace::Model::DAO::RedisDAOFactory',
        handle => $redisHandle
      },
      {
        prio   => 2,
        type   => 'BibSpace::Model::DAO::MySQLDAOFactory',
        handle => $dbHandle
      },
    ]
  );

  # use Data::Dumper;
  # print "MAIN: using config: ".Dumper \%backendConfig;

  # require BibSpace::Model::Repository::RepositoryFactory;
  # my $factory
  #     = BibSpace::Model::Repository::RepositoryFactory->new(logger => $logger)
  #     ->getInstance(
  #         'BibSpace::Model::Repository::LayeredRepositoryFactory',
  #         \%backendConfig
  #     );

# say "######## CALLING 4 times \$factory->getEntriesRepository();";
# my $erepo = $factory->getEntriesRepository();
# $factory->getEntriesRepository();
# $factory->getEntriesRepository();
# $factory->getEntriesRepository();
# # there should be only one logger entry on the screen with: DEBU: Initializing filed instanceEntriesRepo in class BibSpace::Model::Repository::LayeredRepositoryFactory
# say "######## CALLING \$erepo->all();";

  # my @allEntries = $erepo->all();

  # my $entry  = Entry->new( bib => "sth", year => 2012 );
  # my $entry2 = Entry->new( bib => "sth", year => 2011 );
  # my @entries = ( $entry, $entry2 );
  # $erepo->save(@entries);

  # my @someEntries = $erepo->filter( sub { $_->year == 2011 } );    #fake!

}
catch {
  say "Caught exception: $_";
};

# Test for DAO only

# try{
#   require BibSpace::Model::DAO::DAOFactory;
#   BibSpace::Model::DAO::DAOFactory->import;
#   my $dbHandle = "DB stuff"; # DBI->connect(...)
#   my $redisHandle = "Redis stuff"; # Redis->connect(...)

#   my $logger = BibSpace::Model::SimpleLogger->new();
#   my $daoFactory;
#   $daoFactory = BibSpace::Model::DAO::DAOFactory->new(logger=>$logger)->getInstance( 'BibSpace::Model::DAO::MySQLDAOFactory', $dbHandle );
#   # $daoFactory = BibSpace::Model::DAO::DAOFactory->new()->getInstance( 'Redis', $redisHandle );

#   my $dao     = $daoFactory->getEntryDao();
#   # my @entries = $dao->all();

#   my $entry   = Entry->new( bib => "sth", year =>2012 );
#   my $entry2   = Entry->new( bib => "sth", year => 2011 );
#   my @entries = ($entry, $entry2);
#   $dao->save(@entries);
#   # my @someEntries = $dao->filter("blah"); #fake!
#   my @someEntries2 = $dao->filter(sub{$_->year==2011}); #fake!
# }
# catch{
#   say "Caught exception: $_";
# };
