package IEntitySerializableBase;

use namespace::autoclean;
use Moose::Role;
use MooseX::StrictConstructor;

# Required, even without explicit import MooseX::Storgae
use MooseX::Storage::Engine;
MooseX::Storage::Engine->add_custom_type_handler(
  'DateTime' => (
    expand   => sub { DateTime::Format::ISO8601->new->parser_datetime(shift) },
    collapse => sub { (shift)->iso8601 },
  )
);

has 'old_mysql_id' => (is => 'ro', isa => 'Maybe[Int]', default => undef);
has 'id'           => (is => 'rw', isa => 'Maybe[Int]', default => undef);

1;
