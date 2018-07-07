package TypeSerializableBase;

use utf8;
use v5.16;
use Moose;
use Moose::Util::TypeConstraints;
use BibSpace::Model::SerializableBase::IEntitySerializableBase;
use MooseX::Storage;
with Storage('format' => 'JSON');
with 'IEntitySerializableBase';

has 'our_type'    => (is => 'rw', isa => 'Str', default => 'Unnamed');
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

no Moose;
__PACKAGE__->meta->make_immutable;
1;
