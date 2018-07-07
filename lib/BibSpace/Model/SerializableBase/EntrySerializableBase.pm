package EntrySerializableBase;

# Plain Old Perl Object Entry

use BibSpace::Model::Entry;
use utf8;
use v5.16;
use Moose;
use BibSpace::Model::SerializableBase::IEntitySerializableBase;
with 'IEntitySerializableBase';

sub DateTime::TO_JSON {
  { "" . shift }
}

has 'entry_type'      => (is => 'rw', isa => 'Str');
has 'bibtex_key'      => (is => 'rw', isa => 'Maybe[Str]');
has '_bibtex_type'    => (is => 'rw', isa => 'Maybe[Str]');
has 'bib'             => (is => 'rw', isa => 'Maybe[Str]');
has 'html'            => (is => 'rw', isa => 'Maybe[Str]');
has 'html_bib'        => (is => 'rw', isa => 'Maybe[Str]');
has 'abstract'        => (is => 'rw', isa => 'Maybe[Str]');
has 'title'           => (is => 'rw', isa => 'Maybe[Str]');
has 'hidden'          => (is => 'rw', isa => 'Int', default => 0);
has 'year'            => (is => 'rw', isa => 'Maybe[Int]', default => 0);
has 'month'           => (is => 'rw', isa => 'Int', default => 0);
has 'need_html_regen' => (is => 'rw', isa => 'Int', default => 1);
has 'creation_time'   => (is => 'rw', isa => 'DateTime');
has 'modified_time'   => (is => 'rw', isa => 'DateTime');

# Factory method
sub new__DateTime_from_string {
  my ($class, $dtFormat, %args) = @_;

# last_login and registration_time are inputed as strings in format: '2017-02-08T02:00:03'
  my $inputPattern      = DateTime::Format::Strptime->new(pattern => $dtFormat);
  my $creation_time_obj = $inputPattern->parse_datetime($args{'creation_time'});
  my $modified_time_obj = $inputPattern->parse_datetime($args{'modified_time'});
  $args{'creation_time'} = $creation_time_obj;
  $args{'modified_time'} = $modified_time_obj;

  return $class->new(%args);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
