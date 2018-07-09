use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Exception;

use Data::Dumper;
use Array::Utils qw(:all);
use feature qw( say );
use BibSpace::Repository::FlatRepositoryFacade;

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
my $mock_obj_types = $self->app->entityFactory->new_Type(our_type => 'test');
$mock_obj_types->bibtexTypes_add("Article");

my $mock_obj_users = $self->app->entityFactory->new_User(
  id    => -1,
  login => 'test',
  email => 'test',
  pass  => 'test',
  pass2 => 'test'
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
ok($objs[0], "Added object should exist" . aDump(@objs));
ok($objs[0]->our_type,
  "Added object should have ID (here: our_type) defined" . aDump(@objs));

is($t_anyone->app->repo->users_empty, 1, "users_empty should be 1");
ok($mock_obj_users, "mock_obj_users:       " . aDump($mock_obj_users));
$t_anyone->app->repo->users_save($mock_obj_users);
@objs = $t_anyone->app->repo->users_all;
ok($objs[0],         "Added object should exist" . aDump(@objs));
ok($objs[0]->id > 0, "Added object should have ID > 0" . aDump(@objs));

# Relations
my $mock_obj_authorships = $self->app->entityFactory->new_Authorship(
  entry_id  => $mock_obj_entries->id,
  author_id => $mock_obj_authors->id,
);
my $mock_obj_exceptions = $self->app->entityFactory->new_Exception(
  entry_id => $mock_obj_entries->id,
  team_id  => $mock_obj_teams->id,
);
my $mock_obj_labelings = $self->app->entityFactory->new_Labeling(
  entry_id => $mock_obj_entries->id,
  tag_id   => $mock_obj_tags->id,
);
my $mock_obj_memberships = $self->app->entityFactory->new_Membership(
  team_id   => $mock_obj_teams->id,
  author_id => $mock_obj_authors->id,
);
is($t_anyone->app->repo->authorships_empty, 1, "authorships_empty should be 1");
ok($mock_obj_authorships,
  "mock_obj_authorships: " . aDump($mock_obj_authorships));
ok($mock_obj_authorships->author_id > 0,
  "mock_obj_authorships: " . aDump($mock_obj_authorships));
ok($mock_obj_authorships->entry_id > 0,
  "mock_obj_authorships: " . aDump($mock_obj_authorships));
$t_anyone->app->repo->authorships_save($mock_obj_authorships);

is($t_anyone->app->repo->exceptions_empty, 1, "exceptions_empty should be 1");
ok($mock_obj_exceptions,
  "mock_obj_exceptions:  " . aDump($mock_obj_exceptions));
ok($mock_obj_exceptions->entry_id > 0,
  "mock_obj_exceptions:  " . aDump($mock_obj_exceptions));
ok($mock_obj_exceptions->team_id > 0,
  "mock_obj_exceptions:  " . aDump($mock_obj_exceptions));
$t_anyone->app->repo->exceptions_save($mock_obj_exceptions);

is($t_anyone->app->repo->labelings_empty, 1, "labelings_empty should be 1");
ok($mock_obj_labelings, "mock_obj_labelings:   " . aDump($mock_obj_labelings));
ok($mock_obj_labelings->entry_id > 0,
  "mock_obj_labelings:   " . aDump($mock_obj_labelings));
ok($mock_obj_labelings->tag_id > 0,
  "mock_obj_labelings:   " . aDump($mock_obj_labelings));
$t_anyone->app->repo->labelings_save($mock_obj_labelings);

is($t_anyone->app->repo->memberships_empty, 1, "memberships_empty should be 1");
ok($mock_obj_memberships,
  "mock_obj_memberships: " . aDump($mock_obj_memberships));
ok($mock_obj_memberships->author_id > 0,
  "mock_obj_memberships: " . aDump($mock_obj_memberships));
ok($mock_obj_memberships->team_id > 0,
  "mock_obj_memberships: " . aDump($mock_obj_memberships));
$t_anyone->app->repo->memberships_save($mock_obj_memberships);

my $res;
my $element;
my $prefix;

my @objects = qw(authors teams entries tags tagTypes types users);

foreach my $obj (@objects) {
  foreach my $action ('all', 'count') {
    note "=== $obj action $action ===";
    my $code = '$t_anyone->app->repo->' . "$obj" . "_" . "$action;";
    my $res  = eval "$code";
    ok(!$@, "eval error empty. code: $code warn $@");
    isnt($res, undef, $obj . "_$action - output: $res should not be undef");
    ok($res >= 1, $obj . "_$action - output: $res should be >= 1");
  }
  foreach my $action ('empty') {
    note "=== $obj action $action ===";
    my $code = '$t_anyone->app->repo->' . "$obj" . "_" . "$action;";
    my $res  = eval "$code";
    ok(!$@, "eval error empty. code: $code warn $@");
    is($res, undef, $obj . "_$action - output should be undef");
  }
  foreach my $action ('filter', 'find') {
    note "=== $obj action $action ===";
    my $code = '$t_anyone->app->repo->' . "$obj" . "_"
      . "$action(sub {defined \$_ });";
    my $res = eval "$code";
    ok(!$@, "eval error empty. code: $code warn $@");
    isnt($res, undef, $obj . "_$action - output: $res should not be undef");
  }
  foreach my $action ('save', 'update') {
    note "=== $obj action $action ===";
    my $code
      = 'my $element = $mock_obj_'
      . $obj
      . '; $t_anyone->app->repo->' . "$obj" . "_"
      . "$action(\$element);";
    my $res = eval "$code";
    ok(!$@, "eval error empty. code: $code warn $@");
    isnt($res, undef, $obj . "_$action - output: $res should not be undef");
  }

  # Delete will be tested at the end of this file
}
my @relations = qw(authorships exceptions labelings memberships );

foreach my $obj (@relations) {
  foreach my $action ('all', 'count') {
    note "=== $obj action $action ===";
    my $code = '$t_anyone->app->repo->' . "$obj" . "_" . "$action;";
    my $res  = eval "$code";
    ok(!$@, "eval error empty. code: $code warn $@");
    isnt($res, undef, $obj . "_$action - output: $res should not be undef");
    ok($res >= 1, $obj . "_$action - output: $res should be >= 1");
  }
  foreach my $action ('empty') {
    note "=== $obj action $action ===";
    my $code = '$t_anyone->app->repo->' . "$obj" . "_" . "$action;";
    my $res  = eval "$code";
    ok(!$@, "eval error empty. code: $code warn $@");
    is($res, undef, $obj . "_$action - output: $res should be undef");
  }
  foreach my $action ('filter', 'find') {
    note "=== $obj action $action ===";
    my $code = '$t_anyone->app->repo->' . "$obj" . "_"
      . "$action(sub {defined \$_ });";
    my $res = eval "$code";
    ok(!$@, "eval error empty");
    isnt($res, undef, $obj . "_$action - output: $res should not be undef");
  }
  foreach my $action ('save', 'update', 'delete') {
    note "=== $obj action $action ===";
    my $code
      = 'my $element = $mock_obj_'
      . $obj
      . '; $t_anyone->app->repo->' . "$obj" . "_"
      . "$action(\$element);";
    my $res = eval "$code";
    ok(!$@, "eval error empty");
    isnt($res, undef, $obj . "_$action - output: $res should not be undef");
  }
}

# Testing delete for all objects
foreach my $obj (@objects) {
  my $action = "delete";
  note "=== $obj action $action ===";
  my $code
    = 'my $element = $mock_obj_'
    . $obj
    . '; $t_anyone->app->repo->' . "$obj" . "_"
    . "$action(\$element);";
  my $res = eval "$code";
  ok(!$@, "eval error empty. code: $code warn $@");
  isnt($res, undef, $obj . "_$action - output: $res should not be undef");
}

ok(1);
done_testing();

