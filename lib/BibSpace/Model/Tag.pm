package Tag;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use v5.16;

use List::MoreUtils qw(any uniq first_index);

use Moose;
require BibSpace::Model::IEntity;
require BibSpace::Model::ILabeled;
with 'IEntity', 'ILabeled';

use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');

has 'name'      => (is => 'rw', isa => 'Str');
has 'type'      => (is => 'rw', isa => 'Int', default => 1);
has 'permalink' => (is => 'rw', isa => 'Maybe[Str]');

has 'tagtype' =>
  (is => 'rw', isa => 'Maybe[TagType]', traits => ['DoNotSerialize'],);

sub toString {
  my $self = shift;
  $self->freeze;
}

sub equals {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj)
    unless ref($self) eq ref($obj);
  return $self->name eq $obj->name;
}

sub get_authors {
  my $self = shift;

  my @entries = $self->get_entries;
  my @authors = map { $_->get_authors } @entries;
  return uniq @authors;
}

sub get_entries {
  my $self = shift;
  return map { $_->entry } $self->labelings_all;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
