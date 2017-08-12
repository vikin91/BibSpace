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
# This parameter is crucial for deserialization!
has 'dateTimeFormat' => (is => 'rw', isa => 'Str', default => '%T');

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

sub toJSON {
  my $self = shift;

  use JSON -convert_blessed_universally;
  my $json_obj = JSON->new->convert_blessed->utf8->pretty;
  return $json_obj->encode($self);
}

sub fromLayeredRepo {
  my $self       = shift;
  my $sourceRepo = shift;

  # PLAN:
  # 1) Pack all objects into DTO
  # 2) Serialize DTO

  my $dto = BibSpaceDTO->new('FormatVersion' => 1);

  for my $type ($sourceRepo->get_models) {
    my @all = $sourceRepo->lr->all($type);
    $dto->set($type, []);
    push @{$dto->get($type)}, @all;
  }
  return $dto;
}

sub toLayeredRepo {
  my $self            = shift;
  my $jsonString      = shift;
  my $destinationRepo = shift // die "Need to provide destination repository";

  my $parsedDTO = bless(JSON->new->decode($jsonString), 'BibSpaceDTO');
  my $dto = BibSpaceDTO->new('FormatVersion' => 1);

  # Each array (type => array) holds hashes
  # Hases need to be blessed to become objects
  # Json gives <ObjType>SerializableBase
  # Here, we bless into <ObjType>

  print "###############\n";
  use Data::Dumper;
  $Data::Dumper::Maxdepth = 2;

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

#       print "<<<<< Processing object of type $className.\n Input hash: \n";
#       print Dumper $objHash;

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

#       print ">>>>> Moose from $className is: \n";
#       print Dumper $mooseObj;

      push @{$dto->get($className)}, $mooseObj;

    }
  }
  return $dto;
}

sub _hashToMooseObject {
  my $self      = shift;
  my $className = shift;
  my $obj       = shift;
  my $args      = shift;
  my %hashObj   = %{$obj};
  my %hashArgs  = %{$args};

  my $mooseObj;
  try {
    $mooseObj = $className->new__DateTime_from_string($self->dateTimeFormat,
      (%hashObj, %hashArgs));
  }
  catch {
    $mooseObj = $className->new((%hashObj, %hashArgs));
  };

  return $mooseObj;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
