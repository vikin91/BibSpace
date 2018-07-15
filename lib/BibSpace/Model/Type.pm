package Type;

use List::MoreUtils qw(any uniq);
use utf8;
use v5.16;
use Try::Tiny;
use Moose;
use Moose::Util::TypeConstraints;
with 'IEntity';
use BibSpace::Model::SerializableBase::TypeSerializableBase;
extends 'TypeSerializableBase';

# Cast self to SerializableBase and serialize
# sub TO_JSON {
#   my $self = shift;
#   my $copy = $self->meta->clone_object($self);
#
# # The bibtexTypes array is not cloned by default, so this needs to be added as fix
#   $copy->bibtexTypes($self->bibtexTypes);
#
#   # Why this is not copied automatically?
#   $copy->onLanding($self->onLanding);
#
# # Suprisingly, some types may miss the obligatory field, so we provide a default vaule
#   if ($self->our_type) {
#     $copy->our_type($self->our_type);
#   }
#   else {
#     $copy->our_type('Unnamed');
#   }
#   my $tsb_debug = TypeSerializableBase->meta->rebless_instance_back($copy);
#   return $tsb_debug->TO_JSON;
# }

sub id {
  my $self = shift;
  return "(" . $self->our_type . "-" . join($self->bibtexTypes_all, ',') . ")";
}

sub equals {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj)
    unless ref($self) eq ref($obj);
  return $self->our_type eq $obj->our_type;
}

sub num_bibtex_types {
  my $self = shift;
  return $self->bibtexTypes_count;
}

sub get_first_bibtex_type {
  my $self = shift;
  my @all  = $self->bibtexTypes_all;
  if ($self->num_bibtex_types > 0) {
    return $all[0];
  }
  return;
}

sub is_original_bibtex_type {
  my $self = shift;
  if (  $self->num_bibtex_types == 1
    and $self->our_type eq $self->get_first_bibtex_type)
  {
    return 1;
  }
  return;
}

sub can_be_deleted {
  my $self = shift;
  return if $self->num_bibtex_types > 1;
  return if $self->is_original_bibtex_type;
  return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
