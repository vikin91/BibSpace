package TagType;

use Data::Dumper;
use utf8;
use Text::BibTeX;
use v5.16;
use Moose;
use BibSpace::Model::IEntity;
with 'IEntity';
use BibSpace::Model::SerializableBase::TagTypeSerializableBase;
extends 'TagTypeSerializableBase';

sub equals {
  my $self = shift;
  my $obj  = shift;

  die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj)
    unless ref($self) eq ref($obj);
  return 1 if $self->name eq $obj->name;
  return;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
