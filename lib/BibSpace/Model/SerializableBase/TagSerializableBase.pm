package TagSerializableBase;

use utf8;
use v5.16;
use Moose;
use BibSpace::Model::SerializableBase::IEntitySerializableBase;
with 'IEntitySerializableBase';

has 'name'      => (is => 'rw', isa => 'Str');
has 'type'      => (is => 'rw', isa => 'Int', default => 1);
has 'permalink' => (is => 'rw', isa => 'Maybe[Str]');

no Moose;
__PACKAGE__->meta->make_immutable;
1;
