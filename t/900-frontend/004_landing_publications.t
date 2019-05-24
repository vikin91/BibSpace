use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Functions::Core;

my $t_logged_in = Test::Mojo->new('BibSpace');
my $self        = $t_logged_in->app;
use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

$t_logged_in->post_ok(
  '/do_login' => {Accept => '*/*'},
  form        => {user   => 'pub_admin', pass => 'asdf'}
);

$self = $t_logged_in->app;
my $app_config = $t_logged_in->app->config;
$t_logged_in->ua->max_redirects(3);

my @all_tag_type_objs = $t_logged_in->app->repo->tagTypes_all;
my $some_tag_type_obj = $all_tag_type_objs[0];
BAIL_OUT("Example tag_type must exist for this test") if not $some_tag_type_obj;

my @tags
  = $t_logged_in->app->repo->tags_filter(sub { scalar($_->get_entries) > 0 });
my $some_tag = $tags[0];
BAIL_OUT("Example tag (one that has some entries) must exist for this test")
  if not $some_tag;

my @tags_permalink = $t_logged_in->app->repo->tags_filter(
  sub { defined $_->permalink and length($_->permalink) > 1 });
my $some_permalink = $tags_permalink[0];
BAIL_OUT("Example permalink must exist for this test") if not $some_permalink;

my @teams     = $t_logged_in->app->repo->teams_all;
my $some_team = $teams[0];
BAIL_OUT("Example team must exist for this test") if not $some_team;

my @authors
  = $t_logged_in->app->repo->authors_filter(sub { scalar($_->get_entries) > 0 }
  );
my $some_author = $authors[0];
BAIL_OUT("Example author (having entries) must exist for this test")
  if not $some_author;

# generated with: ./bin/bibspace routes | grep GET | grep -v :
my @pages = (
  "/read/publications", "/r/publications", "/r/p", "/read/bibtex", "/r/bibtex",
  "/r/b", $self->url_for('lp'),
  $self->url_for('lp')->query(entry_type => 'paper'),
  $self->url_for('lp')
    ->query(entry_type => 'paper', author => $some_author->uid),
  $self->url_for('lp')
    ->query(entry_type => 'paper', author => $some_author->id),
  $self->url_for('lp')->query(entry_type => 'paper', team => $some_team->name),
  $self->url_for('lp')->query(entry_type => 'paper', team => $some_team->id),
  $self->url_for('lp')->query(entry_type => 'paper', tag  => $some_tag->name),
  $self->url_for('lp')->query(entry_type => 'paper', tag  => $some_tag->id),
  $self->url_for('lp')->query(entry_type => 'paper', tag  => 'not-existing'),
  $self->url_for('lp')
    ->query(entry_type => 'paper', permalink => $some_permalink->name),
  $self->url_for('lp')
    ->query(entry_type => 'paper', permalink => $some_permalink->id),
  $self->url_for('lp')
    ->query(entry_type => 'paper', permalink => 'not-existing'),
  $self->url_for('lp')
    ->query(entry_type => 'paper', bibtex_type => 'inproceedings'),
  $self->url_for('lp')->query(entry_type => 'talk'),

  $self->url_for('lyp'), $self->url_for('lyp')->query(entry_type => 'paper'),
  $self->url_for('lyp')
    ->query(entry_type => 'paper', author => $some_author->uid),
  $self->url_for('lyp')
    ->query(entry_type => 'paper', author => $some_author->id),
  $self->url_for('lyp')->query(entry_type => 'paper', team => $some_team->name),
  $self->url_for('lyp')->query(entry_type => 'paper', team => $some_team->id),
  $self->url_for('lyp')->query(entry_type => 'paper', tag  => $some_tag->name),
  $self->url_for('lyp')->query(entry_type => 'paper', tag  => $some_tag->id),
  $self->url_for('lyp')->query(entry_type => 'paper', tag  => 'not-existing'),
  $self->url_for('lyp')
    ->query(entry_type => 'paper', permalink => $some_permalink->name),
  $self->url_for('lyp')
    ->query(entry_type => 'paper', permalink => $some_permalink->id),
  $self->url_for('lyp')
    ->query(entry_type => 'paper', permalink => 'not-existing'),
  $self->url_for('lyp')
    ->query(entry_type => 'paper', bibtex_type => 'inproceedings'),
  $self->url_for('lyp')->query(entry_type => 'talk'),

  $self->url_for(
    'get_authors_for_tag',
    id   => $some_tag->id,
    type => $some_tag_type_obj->id
  ),
  $self->url_for(
    'get_authors_for_tag_and_team',
    tag_id  => $some_tag->id,
    team_id => $some_team->id
  ),

);

my $ws_page;
$ws_page = $self->url_for('show_stats_websocket', num => 10);
$t_logged_in->websocket_ok($ws_page, "Websocket OK for $ws_page");
$ws_page = $self->url_for('show_log_websocket', num => 10);
$t_logged_in->websocket_ok($ws_page, "Websocket OK for $ws_page");

for my $page (@pages) {
  note "============ Testing page $page ============";
  $t_logged_in->get_ok($page, "Get for page $page")
    ->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");
}

done_testing();
