package AuthorSerializableBase;

use utf8;
use v5.16;
use Moose;
use MooseX::Privacy;
require BibSpace::Model::SerializableBase::IEntitySerializableBase;
with 'IEntitySerializableBase';

has 'uid' =>
  (is => 'rw', isa => 'Str', documentation => q{Author name (deprecated)});
has 'name' => (is => 'rw', isa => 'Str', documentation => q{Author name});

has 'display' => (
  is            => 'rw',
  default       => 0,
  isa           => 'Int',
  documentation => q{If 1, the author will be displayed in menu.}
);

has 'master_id' => (
  is            => 'rw',
  isa           => 'Maybe[Int]',
  traits        => [qw/Protected/],
  documentation => q{Id of author's master object}
);

# Read-Only getter for master_id
sub get_master_id {
  my $self = shift;
  if (not $self->master_id) {
    $self->master_id($self->id);
  }
  return $self->master_id;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
