package ILabeled;

use namespace::autoclean;

use Moose::Role;

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

sub has_tag {
  my $self = shift;
  my $tag  = shift;
  return defined $self->labelings_find(sub { $_->tag->equals($tag) });
}

sub has_labeling {
  my ($self, $labeling) = @_;
  my $idx = $self->labelings_find_index(sub { $_->equals($labeling) });
  return $idx >= 0;
}

sub add_labeling {
  my ($self, $labeling) = @_;
  if (!$self->has_labeling($labeling)) {
    $self->labelings_add($labeling);
  }
}

sub remove_labeling {
  my ($self, $labeling) = @_;

  my $index = $self->labelings_find_index(sub { $_->equals($labeling) });
  return   if $index == -1;
  return 1 if $self->labelings_delete($index);
  return;
}

sub get_tags {
  my $self     = shift;
  my $tag_type = shift;

  my @tags = map { $_->tag } $self->labelings_all;
  if (defined $tag_type) {
    return grep { $_->type == $tag_type } @tags;
  }
  return @tags;
}

1;
