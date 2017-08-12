package AuthorSerializableBase;

use utf8;
use v5.16;
use Moose;
require BibSpace::Model::SerializableBase::IEntitySerializableBase;
with 'IEntitySerializableBase';

has 'uid' => (is => 'rw', isa => 'Str', documentation => q{Author name});

has 'display' => (
  is            => 'rw',
  default       => 0,
  isa           => 'Int',
  documentation => q{If 1, the author will be displayed in menu.}
);

has 'master_id' => (
  is            => 'rw',
  isa           => 'Maybe[Int]',
  documentation => q{Id of author's master object}
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
