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

has 'labellings' => (
  is      => 'rw',
  isa     => 'ArrayRef[Labeling]',
  traits  => ['Array'],
  default => sub { [] },
  handles => {
    labellings_all        => 'elements',
    labellings_add        => 'push',
    labellings_count      => 'count',
    labellings_find       => 'first',
    labellings_find_index => 'first_index',
    labellings_filter     => 'grep',
    labellings_delete     => 'delete',
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
sub add_labelling {
  my ( $self, $label ) = @_;
  $label->validate;
  $self->labellings_add($label);
}
####################################################################################
sub remove_labelling {
  my ( $self, $label ) = @_;
  $label->validate;
  my $index = $self->labellings_find_index( sub { $_->equals($label) } );
  return   if $index == -1;
  return 1 if $self->labellings_delete($index);
  return;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
