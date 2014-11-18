package TeamSerializableBase;

use utf8;
use v5.16;
use Moose;
use BibSpace::Model::SerializableBase::IEntitySerializableBase;
with 'IEntitySerializableBase';

has 'name'   => (is => 'rw', isa => 'Str');
has 'parent' => (is => 'rw');

no Moose;
__PACKAGE__->meta->make_immutable;
1;
