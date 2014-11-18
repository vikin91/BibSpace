package BibSpaceDTO;

# BibSpace Data Transfer Object encapsulates all data from the system, except of Preferences, Statistics, and Backup.
# This allows to backup and restore entire system into/from a single file

use utf8;
use v5.16;
use Moose;
use MooseX::ClassAttribute;
use Try::Tiny;
use Data::Dumper;
$Data::Dumper::Maxdepth = 2;

# Class attribute is not serialized
has 'formatVersion' => (is => 'ro', isa => 'Str', default => '1');

# This parameter is used in backup restoring (deserialization)
# It is used for deserializing dateTime objects
# Always set this parameter to a value that is default for serialization in class 'DateTime'
# Currently, it is '%Y-%m-%dT%T'
# The parameter is ro, becuse there are no means and need to change it currently

# Commenting it out due to warning that this is replaced by the class_has version
# has 'dateTimeFormat' => (is => 'ro', isa => 'Str', default => '%Y-%m-%dT%T');

# duplicate as class atribute to make some functions purely static
class_has 'dateTimeFormat' =>
  (is => 'ro', isa => 'Str', default => '%Y-%m-%dT%T');

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
# THis method changes types of objects from Labeling to LabelingSerializableBase
sub toJSON {
  my $self = shift;

  use JSON -convert_blessed_universally;
  return JSON->new->convert_blessed->utf8->pretty->encode($self)
    ;    # this method chnages self!!
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
  my $self       = shift;
  my $jsonString = shift;
  my $repoFacade = shift
    // die "Need to provide repoFacade of destination repository";
  my $repoPreferences = $repoFacade->lr->preferences;

  # This parses a shallow BibSpaceDTO
  my $parsedDTO = bless(JSON->new->decode($jsonString), 'BibSpaceDTO');

  # Each array (type => array) holds hashes
  # Hashes need to be blessed to become objects
  # Json gives <ObjType>SerializableBase
  # Here, we bless into <ObjType>
  # This will hold rich objects constructed from data from shallow object
  my $dto = BibSpaceDTO->new('FormatVersion' => 1);

  # Init containers for objects
  for my $className ($parsedDTO->keys) {
    $dto->set($className, []);
  }

  # Fill containers with objects
  for my $className ($parsedDTO->keys) {
    my $arrayRef = $parsedDTO->data->{$className};
    for my $objHash (@$arrayRef) {
      my $blessedObj = bless($objHash, $className);

      # Load className and call constructor
      Class::Load::load_class($className);

      # BlessedObj has only SerializableBase
      # Call normal constructor to create rich object
      my $mooseObj = BibSpaceDTO->_hashToMooseObject($className, $objHash,
        {preferences => $repoPreferences, repo => $repoFacade});
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
    $mooseObj
      = $className->new__DateTime_from_string(BibSpaceDTO->dateTimeFormat,
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
