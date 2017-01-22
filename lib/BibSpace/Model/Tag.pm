package Tag;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use 5.010;           #because of ~~ and say
use DBI;

use Moose;
use BibSpace::Model::IEntity;
with 'IEntity';
use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );


has 'name'      => ( is => 'rw', isa => 'Str' );
has 'type'      => ( is => 'rw', isa => 'Int', default => 1 );
has 'permalink' => ( is => 'rw', isa => 'Maybe[Str]' );

has 'tagtype' => ( is => 'rw', isa => 'Maybe[TagType]', traits => ['DoNotSerialize'], );

has 'labelings' => (
  is      => 'rw',
  isa     => 'ArrayRef[Labeling]',
  traits  => ['Array'],
  default => sub { [] },
  handles => {
    labelings_all        => 'elements',
    labelings_add        => 'push',
    labelings_count      => 'count',
    labelings_find       => 'first',
    labelings_find_index => 'first_index',
    labelings_filter     => 'grep',
    labelings_delete     => 'delete',
    labelings_clear      => 'clear',
  },
);


####################################################################################
sub toString {
  my $self = shift;
  $self->freeze;
}
####################################################################################
sub equals {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj) unless ref($self) eq ref($obj);
  return $self->name eq $obj->name;
}
####################################################################################
sub add_labeling {
  my ( $self, $label ) = @_;
  $label->validate;
  $self->labelings_add($label);
}
####################################################################################
sub remove_labeling {
  my ( $self, $label ) = @_;
  $label->validate;
  my $index = $self->labelings_find_index( sub { $_->equals($label) } );
  return   if $index == -1;
  return 1 if $self->labelings_delete($index);
  return;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
