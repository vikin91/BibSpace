package Type;

use List::MoreUtils qw(any uniq);

use Data::Dumper;
use utf8;

use v5.16;

use Try::Tiny;

use Moose;

use Moose::Util::TypeConstraints;
with 'IEntity';

use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');

has 'our_type'    => (is => 'ro', isa => 'Str');
has 'description' => (is => 'rw', isa => 'Maybe[Str]');
has 'onLanding'   => (is => 'rw', isa => 'Int', default => 0);
has 'bibtexTypes' => (
  is      => 'rw',
  isa     => 'ArrayRef[Str]',
  traits  => ['Array'],
  default => sub { [] },
  handles => {
    bibtexTypes_all        => 'elements',
    bibtexTypes_add        => 'push',
    bibtexTypes_map        => 'map',
    bibtexTypes_filter     => 'grep',
    bibtexTypes_find       => 'first',
    bibtexTypes_find_index => 'first_index',
    bibtexTypes_delete     => 'delete',
    bibtexTypes_clear      => 'clear',
    bibtexTypes_get        => 'get',
    bibtexTypes_join       => 'join',
    bibtexTypes_count      => 'count',
    bibtexTypes_has        => 'count',
    bibtexTypes_has_no     => 'is_empty',
    bibtexTypes_sorted     => 'sort',
  },
);

sub toString {
  my $self = shift;
  return
      "Type: '"
    . $self->our_type
    . "' maps to "
    . $self->bibtexTypes_count
    . " bibtex types: ["
    . join(', ', $self->bibtexTypes_all) . "]\n";
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
