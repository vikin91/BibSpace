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

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

my $mock_obj_authors = $self->app->entityFactory->new_Author(uid => 'test');
my $mock_obj_entries = $self->app->entityFactory->new_Entry(bib => 'test');
my $mock_obj_tags = $self->app->entityFactory->new_Tag(name => 'test');
my $mock_obj_tagTypes = $self->app->entityFactory->new_TagType(name => 'test');
my $mock_obj_teams = $self->app->entityFactory->new_Team(name => 'test');
my $mock_obj_types = $self->app->entityFactory->new_Type(our_type => 'test');
my $mock_obj_users = $self->app->entityFactory->new_User(
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

ok($mock_obj_authors,     "mock_obj_authors:     $mock_obj_authors    ");
ok($mock_obj_authorships, "mock_obj_authorships: $mock_obj_authorships");
ok($mock_obj_entries,     "mock_obj_entries:     $mock_obj_entries    ");
ok($mock_obj_exceptions,  "mock_obj_exceptions:  $mock_obj_exceptions ");
ok($mock_obj_labelings,   "mock_obj_labelings:   $mock_obj_labelings  ");
ok($mock_obj_memberships, "mock_obj_memberships: $mock_obj_memberships");
ok($mock_obj_tags,        "mock_obj_tags:        $mock_obj_tags       ");
ok($mock_obj_tagTypes,    "mock_obj_tagTypes:    $mock_obj_tagTypes   ");
ok($mock_obj_teams,       "mock_obj_teams:       $mock_obj_teams      ");
ok($mock_obj_types,       "mock_obj_types:       $mock_obj_types      ");
ok($mock_obj_users,       "mock_obj_users:       $mock_obj_users      ");

my @actions0_defined = qw( all count );
my @actions0_undef   = qw( empty );

my @actions1 = qw( filter find );

my @actions2 = qw( save update exists );    # oder important because of exists!
my @actions2_delete = qw( delete );

my @objects   = qw(authors teams entries tags tagTypes types users);
my @relations = qw(authorships exceptions labelings memberships );

foreach my $obj (@objects) {

  foreach my $action (@actions0_defined) {
    note "================= Testing action $action =================";
    my $code = '$t_anyone->app->repo->' . "$obj" . "_" . "$action;";
    my $res  = eval "$code";
    isnt($res, '', "'$code'. Output: '$res'. Error captured: '$@'.");
    ok(!$@, "eval error empty");
  }

  foreach my $action (@actions0_undef) {
    note "================= Testing action $action =================";
    my $code = '$t_anyone->app->repo->' . "$obj" . "_" . "$action;";
    my $res  = eval "$code";
    is($res, '', "'$code'. Output: '$res'. Error captured: '$@'.");
    ok(!$@, "eval error empty");
  }

  foreach my $action (@actions1) {
    note "================= Testing action $action =================";
    my $code = '$t_anyone->app->repo->' . "$obj" . "_"
      . "$action(sub {defined " . '$_' . "} );";
    my $res = eval "$code";
    isnt($res, '', "'$code'. Output: '$res'. Error captured: '$@'.");
  }

  foreach my $action (@actions2) {
    note "================= Testing action $action =================";

    my $element = eval '$mock_obj_' . "$obj";
    say "element->id: " . $element->id;
    ok($element, "element '$element' is defined. Error captured: '$@'.");
    ok(!$@,      "eval error empty");

    my $code = 'my $element = ' . '$mock_obj_' . "$obj" . '; ';
    $code
      .= '$t_anyone->app->repo->' . "$obj" . "_"
      . "$action( "
      . '$element' . " );";

    my $res = eval "$code";
    isnt($res, '', "'$code'. Output: '$res'. Error captured: '$@'.");
    ok(!$@, "eval error empty");
  }

}

foreach my $obj (@relations) {

  foreach my $action (@actions0_defined) {
    note "================= Testing action $action =================";
    my $code = '$t_anyone->app->repo->' . "$obj" . "_" . "$action;";
    my $res  = eval "$code";
    isnt($res, '', "'$code'. Output: '$res'. Error captured: '$@'.");
    ok(!$@, "eval error empty");
  }

  foreach my $action (@actions0_undef) {
    note "================= Testing action $action =================";
    my $code = '$t_anyone->app->repo->' . "$obj" . "_" . "$action;";
    my $res  = eval "$code";
    is($res, '', "'$code'. Output: '$res'. Error captured: '$@'.");
    ok(!$@, "eval error empty");
  }

  foreach my $action (@actions1) {
    note "================= Testing action $action =================";
    my $code = '$t_anyone->app->repo->' . "$obj" . "_"
      . "$action(sub {defined " . '$_' . "} );";
    my $res = eval "$code";
    isnt($res, '', "'$code'. Output: '$res'. Error captured: '$@'.");
    ok(!$@, "eval error empty");
  }

  foreach my $action (@actions2) {
    note "================= Testing action $action =================";

    my $element = eval '$mock_obj_' . "$obj";
    say "element->id: " . $element->id;
    ok($element, "element '$element' is defined. Error captured: '$@'.");

    my $code = 'my $element = ' . '$mock_obj_' . "$obj" . '; ';
    $code
      .= '$t_anyone->app->repo->' . "$obj" . "_"
      . "$action( "
      . '$element' . " );";

    my $res = eval "$code";
    isnt($res, '', "'$code'. Output: '$res'. Error captured: '$@'.");
    ok(!$@, "eval error empty");
  }

}

foreach my $obj (@objects, @relations) {

  foreach my $action (@actions2_delete) {
    note "================= Testing action $action =================";
    my $element = eval '$mock_obj_' . "$obj";
    say "element->id: " . $element->id;
    ok($element, "element '$element' is defined. Error captured: '$@'.");

    my $code = 'my $element = ' . '$mock_obj_' . "$obj" . '; ';
    $code
      .= '$t_anyone->app->repo->' . "$obj" . "_"
      . "$action( "
      . '$element' . " );";

    my $res = eval "$code";
    isnt($res, '', "'$code'. Output: '$res'. Error captured: '$@'.");
  }
}

ok(1);
done_testing();

