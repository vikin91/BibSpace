package IEntity;
use namespace::autoclean;

use BibSpace::Util::IntegerUidProvider;
use Moose::Role;
use MooseX::StrictConstructor;

require BibSpace::Model::SerializableBase::IEntitySerializableBase;
with 'IEntitySerializableBase';
# Responsibility for ID management is moved to the storage backend

has 'preferences' =>
  (is => 'ro', isa => 'Preferences', traits => ['DoNotSerialize']);

has 'idProvider' => (
  is       => 'ro',
  does     => 'IUidProvider',
  required => 1,
  traits   => ['DoNotSerialize'],
);

has 'old_mysql_id' => (is => 'ro', isa => 'Maybe[Int]', default => undef);
has 'id'           => (is => 'rw', isa => 'Maybe[Int]', default => undef,);

requires 'equals';

1;
