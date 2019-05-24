package IRelation;
use namespace::autoclean;
use Moose::Role;

requires 'id';
requires 'equals';
has 'repo' => (
  is       => 'ro',
  isa      => 'FlatRepositoryFacade',
  required => 1,
  traits   => ['DoNotSerialize']
);

# Custm cloning method is required because the following construct does not copy fileds values
# my $clone = $self->meta->clone_object($self);
# LabelingSerializableBase->meta->rebless_instance_back($clone);
sub get_base {
  my $self            = shift;
  my $base_class_name = ref($self) . "SerializableBase";
  Class::Load::load_class($base_class_name);
  return $base_class_name->new(%$self);
}

# Cast self to SerializableBase and serialize
sub TO_JSON {
  my $self = shift;
  return $self->get_base->TO_JSON;
}

1;
