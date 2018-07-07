package LabelingSerializableBase;

use utf8;
use v5.16;
use Moose;

has 'entry_id' => (is => 'ro', isa => 'Int');
has 'tag_id'   => (is => 'ro', isa => 'Int');

no Moose;
__PACKAGE__->meta->make_immutable;
1;
