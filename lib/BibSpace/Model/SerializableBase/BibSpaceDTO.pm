package BibSpaceDTO;

# BibSpace Data Transfer Object encapsulates all data from the system, except of Preferences, Statistics, and Backup.
# This allows to backup and restore entire system into/from a single file

use utf8;
use v5.16;
use Moose;
use Try::Tiny;

# Class attribute is not serialized
has 'formatVersion' => (is => 'ro', isa => 'Str', default => '1');

# Format %T is default by serializing
# FIXME: This parameter is ignored by serialization!
# Temp fix: %Y-%m-%dT%T is a default format used by serialization
# This parameter is crucial for deserialization!
has 'dateTimeFormat' => (is => 'rw', isa => 'Str', default => '%Y-%m-%dT%T');

# The hash has form: 'ClassName' => Array[InstanceofClassName]
has 'data' => (
  traits  => ['Hash'],
  is      => 'ro',
  isa     => 'HashRef[ArrayRef[Object]]',
  default => sub { {} },
  handles => {
    set     => 'set',
    get     => 'get',
    has     => 'exists',
    defined => 'defined',
    keys    => 'keys',
    num     => 'count',
    pairs   => 'kv',
    _clear  => 'clear',
  },
);

# Converts BibSpaceDTO object into JSON string
sub toJSON {
  my $self = shift;

  use JSON -convert_blessed_universally;
  my $json_obj = JSON->new->convert_blessed->utf8->pretty;
  return $json_obj->encode($self);
}

# Static constructor method that creates BibSpaceDTO from LayeredRepo
sub fromLayeredRepo {
  my $self       = shift;
  my $sourceRepo = shift;

  my $dto = BibSpaceDTO->new('FormatVersion' => 1);
  for my $type ($sourceRepo->get_models) {
    my @all = $sourceRepo->lr->all($type);
    $dto->set($type, []);
    push @{$dto->get($type)}, @all;
  }
  return $dto;
}

# Static constructor method that creates BibSpaceDTO from JSON string
# Resulting DTO will hold rich objects (not SerializableBase) and thus
# requires additionall data from the repository
sub toLayeredRepo {
  my $self            = shift;
  my $jsonString      = shift;
  my $destinationRepo = shift // die "Need to provide destination repository";

  # This parses a shallow BibSpaceDTO
  my $parsedDTO = bless(JSON->new->decode($jsonString), 'BibSpaceDTO');

  # Each array (type => array) holds hashes
  # Hases need to be blessed to become objects
  # Json gives <ObjType>SerializableBase
  # Here, we bless into <ObjType>
  # This will hold rich objects constructed from data from shallow object
  my $dto = BibSpaceDTO->new('FormatVersion' => 1);

  # print "###############\n";
  # use Data::Dumper;
  # $Data::Dumper::Maxdepth = 2;

  # Init containers for objects
  for my $className ($parsedDTO->keys) {
    $dto->set($className, []);
  }

  # Reset ID providers for all classes - only once!
  my $smartUidProvider = $destinationRepo->lr->uidProvider;
  $smartUidProvider->reset;
  my $preferences = $destinationRepo->lr->preferences;

  # Fill containers with objects
  for my $className ($parsedDTO->keys) {
    my $arrayRef = $parsedDTO->data->{$className};
    for my $objHash (@$arrayRef) {
      my $blessedObj = bless($objHash, $className);

      # Load className and call constructor
      Class::Load::load_class($className);

      # Rich objects require several additional objects in their constructor
      # See IEntity.pm for details
      my $idProvider = $smartUidProvider->get_provider($className);

      # BlessedObj has only SerializableBase
      # Call normal constructor to create rich object
      my $mooseObj = $self->_hashToMooseObject($className, $objHash,
        {idProvider => $idProvider, preferences => $preferences});
      push @{$dto->get($className)}, $mooseObj;
    }
  }
  return $dto;
}

sub _hashToMooseObject {
  my $self      = shift;
  my $className = shift;
  my $obj  = shift;    # holds hash to be passed into the respective constructor
  my $args = shift;    # additional parameters that will be merged with obj hash

  my %hashObj  = %{$obj};
  my %hashArgs = %{$args};
  my $mooseObj;
  try {
    # Try calling constructor that creates DateTime rich fields from string
    $mooseObj = $className->new__DateTime_from_string($self->dateTimeFormat,
      (%hashObj, %hashArgs));
  }
  catch {
    # Some objects do not have DateTime fileds, so call default constructor
    $mooseObj = $className->new((%hashObj, %hashArgs));
  };
  return $mooseObj;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
