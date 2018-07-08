use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Exception;

use Data::Dumper;
use Array::Utils qw(:all);
use feature qw( say );
use BibSpace::Repository::RepositoryFacade;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self     = $t_anyone->app;

# For this test, we need empty database
my @layers = $self->repo->lr->get_all_layers;
foreach (@layers) { $_->reset_data }

sub aDump {
  use JSON -convert_blessed_universally;
  JSON->new->convert_blessed->utf8->pretty->encode(shift);
}

my $mock_obj_authors
  = $self->app->entityFactory->new_Author(id => -1, uid => 'test');
my $mock_obj_entries
  = $self->app->entityFactory->new_Entry(id => -1, bib => 'test');
my $mock_obj_tags
  = $self->app->entityFactory->new_Tag(id => -1, name => 'test');
my $mock_obj_tagTypes
  = $self->app->entityFactory->new_TagType(id => -1, name => 'test', type => 1);
my $mock_obj_teams
  = $self->app->entityFactory->new_Team(id => -1, name => 'test');
my $mock_obj_types
  = $self->app->entityFactory->new_Type(id => -1, our_type => 'test');
my $mock_obj_users = $self->app->entityFactory->new_User(
  id    => -1,
  login => 'test',
  email => 'test',
  pass  => 'test',
  pass2 => 'test'
);

my $mock_obj_authorships = Authorship->new(
  entry_id  => $mock_obj_entries->id,
  entry     => $mock_obj_entries,
  author_id => $mock_obj_authors->id,
  author    => $mock_obj_authors
);
my $mock_obj_exceptions = Exception->new(
  entry_id => $mock_obj_entries->id,
  entry    => $mock_obj_entries,
  team_id  => $mock_obj_teams->id,
  team     => $mock_obj_teams
);
my $mock_obj_labelings = Labeling->new(
  entry_id => $mock_obj_entries->id,
  entry    => $mock_obj_entries,
  tag_id   => $mock_obj_tags->id,
  tag      => $mock_obj_tags
);
my $mock_obj_memberships = Membership->new(
  team_id   => $mock_obj_teams->id,
  team      => $mock_obj_teams,
  author_id => $mock_obj_authors->id,
  author    => $mock_obj_authors
);

# Check if repo is empty and add mock objects to DB
# Entities
my @objs;

is($t_anyone->app->repo->authors_empty, 1, "authors_empty should be 1");
ok($mock_obj_authors, "mock_obj_authors:     " . aDump($mock_obj_authors));
$t_anyone->app->repo->authors_save($mock_obj_authors);
@objs = $t_anyone->app->repo->authors_all;
ok($objs[0],         "Added object should exist" . aDump(@objs));
ok($objs[0]->id > 0, "Added object should have ID > 0" . aDump(@objs));

# TODO-NEXT: Fix these tests by applying _insert pattern (as in AuthorMySQLDAO.pm) to all entities
is($t_anyone->app->repo->entries_empty, 1, "entries_empty should be 1");
ok($mock_obj_entries, "mock_obj_entries:     " . aDump($mock_obj_entries));
$t_anyone->app->repo->entries_save($mock_obj_entries);
@objs = $t_anyone->app->repo->entries_all;
ok($objs[0],         "Added object should exist" . aDump(@objs));
ok($objs[0]->id > 0, "Added object should have ID > 0" . aDump(@objs));

is($t_anyone->app->repo->tagTypes_empty, 1, "tagTypes_empty should be 1");
ok($mock_obj_tagTypes, "mock_obj_tagTypes:    " . aDump($mock_obj_tagTypes));
$t_anyone->app->repo->tagTypes_save($mock_obj_tagTypes);
@objs = $t_anyone->app->repo->tagTypes_all;
ok($objs[0],         "Added object should exist" . aDump(@objs));
ok($objs[0]->id > 0, "Added object should have ID > 0" . aDump(@objs));

is($t_anyone->app->repo->tags_empty, 1, "tags_empty should be 1");
ok($mock_obj_tags, "mock_obj_tags:        " . aDump($mock_obj_tags));
$t_anyone->app->repo->tags_save($mock_obj_tags);
@objs = $t_anyone->app->repo->tags_all;
ok($objs[0],         "Added object should exist" . aDump(@objs));
ok($objs[0]->id > 0, "Added object should have ID > 0" . aDump(@objs));

is($t_anyone->app->repo->teams_empty, 1, "teams_empty should be 1");
ok($mock_obj_teams, "mock_obj_teams:       " . aDump($mock_obj_teams));
$t_anyone->app->repo->teams_save($mock_obj_teams);
@objs = $t_anyone->app->repo->teams_all;
ok($objs[0],         "Added object should exist" . aDump(@objs));
ok($objs[0]->id > 0, "Added object should have ID > 0" . aDump(@objs));

is($t_anyone->app->repo->types_empty, 1, "types_empty should be 1");
ok($mock_obj_types, "mock_obj_types:       " . aDump($mock_obj_types));
$t_anyone->app->repo->types_save($mock_obj_types);
@objs = $t_anyone->app->repo->types_all;
ok($objs[0],         "Added object should exist" . aDump(@objs));
ok($objs[0]->id > 0, "Added object should have ID > 0" . aDump(@objs));

is($t_anyone->app->repo->users_empty, 1, "users_empty should be 1");
ok($mock_obj_users, "mock_obj_users:       " . aDump($mock_obj_users));
$t_anyone->app->repo->users_save($mock_obj_users);
@objs = $t_anyone->app->repo->users_all;
ok($objs[0],         "Added object should exist" . aDump(@objs));
ok($objs[0]->id > 0, "Added object should have ID > 0" . aDump(@objs));

# Relations
is($t_anyone->app->repo->authorships_empty, 1, "authorships_empty should be 1");
ok($mock_obj_authorships,
  "mock_obj_authorships: " . aDump($mock_obj_authorships));
$t_anyone->app->repo->authorships_save($mock_obj_authorships);

is($t_anyone->app->repo->exceptions_empty, 1, "exceptions_empty should be 1");
ok($mock_obj_exceptions,
  "mock_obj_exceptions:  " . aDump($mock_obj_exceptions));

is($t_anyone->app->repo->labelings_empty, 1, "labelings_empty should be 1");
ok($mock_obj_labelings, "mock_obj_labelings:   " . aDump($mock_obj_labelings));

is($t_anyone->app->repo->memberships_empty, 1, "memberships_empty should be 1");
ok($mock_obj_memberships,
  "mock_obj_memberships: " . aDump($mock_obj_memberships));

my $res;
my $element;
my $prefix;

##### Authors
$element = $mock_obj_authors;
$prefix  = "authors";
$res     = $t_anyone->app->repo->authors_all;
isnt($res, undef, $prefix . "_all - output: $res should not be undef");
ok($res >= 1, $prefix . "_all - output: $res should be >= 1");

$res = $t_anyone->app->repo->authors_count;
isnt($res, undef, $prefix . "_count - output: $res should not be undef");
ok($res >= 1, $prefix . "_count - output: $res should be >= 1");

$res = $t_anyone->app->repo->authors_empty;
is($res, undef, $prefix . "_empty - output: $res should be undef");

$res = $t_anyone->app->repo->authors_filter(sub { defined $_ });
isnt($res, undef, $prefix . "_filter - output: $res should not be undef");

$res = $t_anyone->app->repo->authors_find(sub { defined $_ });
isnt($res, undef, $prefix . "_find - output: $res should not be undef");

$res = $t_anyone->app->repo->authors_save($element);
isnt($res, undef, $prefix . "_save - output: $res should not be undef");

$res = $t_anyone->app->repo->authors_update($element);
isnt($res, undef, $prefix . "_update - output: $res should not be undef");

$res = $t_anyone->app->repo->authors_delete($element);
isnt($res, undef, $prefix . "_delete - output: $res should not be undef");

##### Teams
$element = $mock_obj_teams;
$prefix  = "teams";
$res     = $t_anyone->app->repo->teams_all;
isnt($res, undef, $prefix . "_all - output: $res should not be undef");
ok($res >= 1, $prefix . "_all - output: $res should be >= 1");

$res = $t_anyone->app->repo->teams_count;
isnt($res, undef, $prefix . "_count - output: $res should not be undef");
ok($res >= 1, $prefix . "_count - output: $res should be >= 1");

$res = $t_anyone->app->repo->teams_empty;
is($res, undef, $prefix . "_empty - output: $res should be undef");

$res = $t_anyone->app->repo->teams_filter(sub { defined $_ });
isnt($res, undef, $prefix . "_filter - output: $res should not be undef");

$res = $t_anyone->app->repo->teams_find(sub { defined $_ });
isnt($res, undef, $prefix . "_find - output: $res should not be undef");

$res = $t_anyone->app->repo->teams_save($element);
isnt($res, undef, $prefix . "_save - output: $res should not be undef");

$res = $t_anyone->app->repo->teams_update($element);
isnt($res, undef, $prefix . "_update - output: $res should not be undef");

$res = $t_anyone->app->repo->teams_delete($element);
isnt($res, undef, $prefix . "_delete - output: $res should not be undef");

##### Entries
$element = $mock_obj_entries;
$prefix  = "entries";
$res     = $t_anyone->app->repo->entries_all;
isnt($res, undef, $prefix . "_all - output: $res should not be undef");
ok($res >= 1, $prefix . "_all - output: $res should be >= 1");

$res = $t_anyone->app->repo->entries_count;
isnt($res, undef, $prefix . "_count - output: $res should not be undef");
ok($res >= 1, $prefix . "_count - output: $res should be >= 1");

$res = $t_anyone->app->repo->entries_empty;
is($res, undef, $prefix . "_empty - output: $res should be undef");

$res = $t_anyone->app->repo->entries_filter(sub { defined $_ });
isnt($res, undef, $prefix . "_filter - output: $res should not be undef");

$res = $t_anyone->app->repo->entries_find(sub { defined $_ });
isnt($res, undef, $prefix . "_find - output: $res should not be undef");

$res = $t_anyone->app->repo->entries_save($element);
isnt($res, undef, $prefix . "_save - output: $res should not be undef");

$res = $t_anyone->app->repo->entries_update($element);
isnt($res, undef, $prefix . "_update - output: $res should not be undef");

$res = $t_anyone->app->repo->entries_delete($element);
isnt($res, undef, $prefix . "_delete - output: $res should not be undef");

##### Tags
$element = $mock_obj_tags;
$prefix  = "tags";
$res     = $t_anyone->app->repo->tags_all;
isnt($res, undef, $prefix . "_all - output: $res should not be undef");
ok($res >= 1, $prefix . "_all - output: $res should be >= 1");

$res = $t_anyone->app->repo->tags_count;
isnt($res, undef, $prefix . "_count - output: $res should not be undef");
ok($res >= 1, $prefix . "_count - output: $res should be >= 1");

$res = $t_anyone->app->repo->tags_empty;
is($res, undef, $prefix . "_empty - output: $res should be undef");

$res = $t_anyone->app->repo->tags_filter(sub { defined $_ });
isnt($res, undef, $prefix . "_filter - output: $res should not be undef");

$res = $t_anyone->app->repo->tags_find(sub { defined $_ });
isnt($res, undef, $prefix . "_find - output: $res should not be undef");

$res = $t_anyone->app->repo->tags_save($element);
isnt($res, undef, $prefix . "_save - output: $res should not be undef");

$res = $t_anyone->app->repo->tags_update($element);
isnt($res, undef, $prefix . "_update - output: $res should not be undef");

$res = $t_anyone->app->repo->tags_delete($element);
isnt($res, undef, $prefix . "_delete - output: $res should not be undef");

##### TagTypes
$element = $mock_obj_tagTypes;
$prefix  = "tagTypes";
$res     = $t_anyone->app->repo->tagTypes_all;
isnt($res, undef, $prefix . "_all - output: $res should not be undef");
ok($res >= 1, $prefix . "_all - output: $res should be >= 1");

$res = $t_anyone->app->repo->tagTypes_count;
isnt($res, undef, $prefix . "_count - output: $res should not be undef");
ok($res >= 1, $prefix . "_count - output: $res should be >= 1");

$res = $t_anyone->app->repo->tagTypes_empty;
is($res, undef, $prefix . "_empty - output: $res should be undef");

$res = $t_anyone->app->repo->tagTypes_filter(sub { defined $_ });
isnt($res, undef, $prefix . "_filter - output: $res should not be undef");

$res = $t_anyone->app->repo->tagTypes_find(sub { defined $_ });
isnt($res, undef, $prefix . "_find - output: $res should not be undef");

$res = $t_anyone->app->repo->tagTypes_save($element);
isnt($res, undef, $prefix . "_save - output: $res should not be undef");

$res = $t_anyone->app->repo->tagTypes_update($element);
isnt($res, undef, $prefix . "_update - output: $res should not be undef");

$res = $t_anyone->app->repo->tagTypes_delete($element);
isnt($res, undef, $prefix . "_delete - output: $res should not be undef");

##### Types
$element = $mock_obj_types;
$prefix  = "types";
$res     = $t_anyone->app->repo->types_all;
isnt($res, undef, $prefix . "_all - output: $res should not be undef");
ok($res >= 1, $prefix . "_all - output: $res should be >= 1");

$res = $t_anyone->app->repo->types_count;
isnt($res, undef, $prefix . "_count - output: $res should not be undef");
ok($res >= 1, $prefix . "_count - output: $res should be >= 1");

$res = $t_anyone->app->repo->types_empty;
is($res, undef, $prefix . "_empty - output: $res should be undef");

$res = $t_anyone->app->repo->types_filter(sub { defined $_ });
isnt($res, undef, $prefix . "_filter - output: $res should not be undef");

$res = $t_anyone->app->repo->types_find(sub { defined $_ });
isnt($res, undef, $prefix . "_find - output: $res should not be undef");

$res = $t_anyone->app->repo->types_save($element);
isnt($res, undef, $prefix . "_save - output: $res should not be undef");

$res = $t_anyone->app->repo->types_update($element);
isnt($res, undef, $prefix . "_update - output: $res should not be undef");

$res = $t_anyone->app->repo->types_delete($element);
isnt($res, undef, $prefix . "_delete - output: $res should not be undef");

##### Users
$element = $mock_obj_users;
$prefix  = "users";
$res     = $t_anyone->app->repo->users_all;
isnt($res, undef, $prefix . "_all - output: $res should not be undef");
ok($res >= 1, $prefix . "_all - output: $res should be >= 1");

$res = $t_anyone->app->repo->users_count;
isnt($res, undef, $prefix . "_count - output: $res should not be undef");
ok($res >= 1, $prefix . "_count - output: $res should be >= 1");

$res = $t_anyone->app->repo->users_empty;
is($res, undef, $prefix . "_empty - output: $res should be undef");

$res = $t_anyone->app->repo->users_filter(sub { defined $_ });
isnt($res, undef, $prefix . "_filter - output: $res should not be undef");

$res = $t_anyone->app->repo->users_find(sub { defined $_ });
isnt($res, undef, $prefix . "_find - output: $res should not be undef");

$res = $t_anyone->app->repo->users_save($element);
isnt($res, undef, $prefix . "_save - output: $res should not be undef");

$res = $t_anyone->app->repo->users_update($element);
isnt($res, undef, $prefix . "_update - output: $res should not be undef");

$res = $t_anyone->app->repo->users_delete($element);
isnt($res, undef, $prefix . "_delete - output: $res should not be undef");

##### Exceptions
$element = $mock_obj_exceptions;
$prefix  = "exceptions";
$res     = $t_anyone->app->repo->exceptions_all;
isnt($res, undef, $prefix . "_all - output: $res should not be undef");
ok($res >= 1, $prefix . "_all - output: $res should be >= 1");

$res = $t_anyone->app->repo->exceptions_count;
isnt($res, undef, $prefix . "_count - output: $res should not be undef");
ok($res >= 1, $prefix . "_count - output: $res should be >= 1");

$res = $t_anyone->app->repo->exceptions_empty;
is($res, undef, $prefix . "_empty - output: $res should be undef");

$res = $t_anyone->app->repo->exceptions_filter(sub { defined $_ });
isnt($res, undef, $prefix . "_filter - output: $res should not be undef");

$res = $t_anyone->app->repo->exceptions_find(sub { defined $_ });
isnt($res, undef, $prefix . "_find - output: $res should not be undef");

$res = $t_anyone->app->repo->exceptions_save($element);
isnt($res, undef, $prefix . "_save - output: $res should not be undef");

$res = $t_anyone->app->repo->exceptions_update($element);
isnt($res, undef, $prefix . "_update - output: $res should not be undef");

$res = $t_anyone->app->repo->exceptions_delete($element);
isnt($res, undef, $prefix . "_delete - output: $res should not be undef");

##### Authorships
$element = $mock_obj_authorships;
$prefix  = "authorships";
$res     = $t_anyone->app->repo->authorships_all;
isnt($res, undef, $prefix . "_all - output: $res should not be undef");
ok($res >= 1, $prefix . "_all - output: $res should be >= 1");

$res = $t_anyone->app->repo->authorships_count;
isnt($res, undef, $prefix . "_count - output: $res should not be undef");
ok($res >= 1, $prefix . "_count - output: $res should be >= 1");

$res = $t_anyone->app->repo->authorships_empty;
is($res, undef, $prefix . "_empty - output: $res should be undef");

$res = $t_anyone->app->repo->authorships_filter(sub { defined $_ });
isnt($res, undef, $prefix . "_filter - output: $res should not be undef");

$res = $t_anyone->app->repo->authorships_find(sub { defined $_ });
isnt($res, undef, $prefix . "_find - output: $res should not be undef");

$res = $t_anyone->app->repo->authorships_save($element);
isnt($res, undef, $prefix . "_save - output: $res should not be undef");

$res = $t_anyone->app->repo->authorships_update($element);
isnt($res, undef, $prefix . "_update - output: $res should not be undef");

$res = $t_anyone->app->repo->authorships_delete($element);
isnt($res, undef, $prefix . "_delete - output: $res should not be undef");

##### Labelings
$element = $mock_obj_labelings;
$prefix  = "labelings";
$res     = $t_anyone->app->repo->labelings_all;
isnt($res, undef, $prefix . "_all - output: $res should not be undef");
ok($res >= 1, $prefix . "_all - output: $res should be >= 1");

$res = $t_anyone->app->repo->labelings_count;
isnt($res, undef, $prefix . "_count - output: $res should not be undef");
ok($res >= 1, $prefix . "_count - output: $res should be >= 1");

$res = $t_anyone->app->repo->labelings_empty;
is($res, undef, $prefix . "_empty - output: $res should be undef");

$res = $t_anyone->app->repo->labelings_filter(sub { defined $_ });
isnt($res, undef, $prefix . "_filter - output: $res should not be undef");

$res = $t_anyone->app->repo->labelings_find(sub { defined $_ });
isnt($res, undef, $prefix . "_find - output: $res should not be undef");

$res = $t_anyone->app->repo->labelings_save($element);
isnt($res, undef, $prefix . "_save - output: $res should not be undef");

$res = $t_anyone->app->repo->labelings_update($element);
isnt($res, undef, $prefix . "_update - output: $res should not be undef");

$res = $t_anyone->app->repo->labelings_delete($element);
isnt($res, undef, $prefix . "_delete - output: $res should not be undef");

##### Memberships
$element = $mock_obj_memberships;
$prefix  = "memberships";
$res     = $t_anyone->app->repo->memberships_all;
isnt($res, undef, $prefix . "_all - output: $res should not be undef");
ok($res >= 1, $prefix . "_all - output: $res should be >= 1");

$res = $t_anyone->app->repo->memberships_count;
isnt($res, undef, $prefix . "_count - output: $res should not be undef");
ok($res >= 1, $prefix . "_count - output: $res should be >= 1");

$res = $t_anyone->app->repo->memberships_empty;
is($res, undef, $prefix . "_empty - output: $res should be undef");

$res = $t_anyone->app->repo->memberships_filter(sub { defined $_ });
isnt($res, undef, $prefix . "_filter - output: $res should not be undef");

$res = $t_anyone->app->repo->memberships_find(sub { defined $_ });
isnt($res, undef, $prefix . "_find - output: $res should not be undef");

$res = $t_anyone->app->repo->memberships_save($element);
isnt($res, undef, $prefix . "_save - output: $res should not be undef");

$res = $t_anyone->app->repo->memberships_update($element);
isnt($res, undef, $prefix . "_update - output: $res should not be undef");

$res = $t_anyone->app->repo->memberships_delete($element);
isnt($res, undef, $prefix . "_delete - output: $res should not be undef");

ok(1);
done_testing();

