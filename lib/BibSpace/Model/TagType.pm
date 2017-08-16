package TagType;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use v5.16;

use Moose;
use BibSpace::Model::IEntity;
with 'IEntity';

use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');

has 'name'    => (is => 'rw', isa => 'Str');
has 'comment' => (is => 'rw', isa => 'Maybe[Str]');

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
