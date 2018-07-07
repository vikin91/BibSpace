package MembershipSerializableBase;

use utf8;
use v5.16;
use Moose;

has 'team_id'   => (is => 'ro', isa => 'Int');
has 'author_id' => (is => 'ro', isa => 'Int');
has 'start'     => (is => 'rw', isa => 'Int', default => 0);
has 'stop'      => (is => 'rw', isa => 'Int', default => 0);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
