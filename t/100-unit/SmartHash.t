use Test::More;
use Test::Exception;

use Data::Dumper;
use Array::Utils qw(:all);
use feature qw( say );
use BibSpace::Backend::SmartArray;
use BibSpace::Backend::SmartHash;
use BibSpace::Util::Thing;

# package Thing;
# use Moose;
# has 'str' => ( is => 'rw', isa => 'Str', default => "I am a thing");

# package main;

my $backend = SmartHash->new(logger => SimpleLogger->new());

ok($backend);

my $thing1 = Thing->new(id => 1);
my $thing2 = Thing->new(id => 2);
my $thing3 = Thing->new(id => 3);
my $type   = ref($thing1);

ok($backend->_init(ref($thing1)), "init ok");
ok($backend->empty($type),        "empty ok");
ok(!$backend->exists($thing1),    "exists ok");
ok($backend->_add($thing1),       "add ok");
ok($backend->exists($thing1),     "exists ok");
ok($backend->_add(($thing2, $thing3)), "add ok");
ok($backend->all($type), "all ok");
is($backend->count($type), 3, "count ok");
ok(!$backend->empty($type), "empty ok");

ok(!$backend->find($type, sub { $_->id == 4 }), "find ok");
ok($backend->find($type, sub { $_->id == 3 }), "find ok");

is(scalar($backend->filter($type, sub { $_->id < 2 })),   1, "filter ok");
is(scalar($backend->filter($type, sub { $_->id < 3 })),   2, "filter ok");
is(scalar($backend->filter($type, sub { $_->id < 4 })),   3, "filter ok");
is(scalar($backend->filter($type, sub { $_->id < 100 })), 3, "filter ok");

$thing3->str("updated");

ok($backend->update($thing3), "update ok");
my $found = $backend->find($type, sub { $_->id == 3 });
is($found->str, "updated");

is($backend->delete($thing3), 1, "delete ok");
my $found = $backend->find($type, sub { $_->id == 3 });
ok(!$found, "not found");
is(scalar($backend->filter($type, sub { $_->id < 100 })), 2, "filter ok");

ok($backend->dump, "dump ok");

# say Dumper $backend;

ok(1);
done_testing();

