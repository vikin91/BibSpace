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

my @tags
  = $t_logged_in->app->repo->tags_filter(sub { scalar($_->get_entries) > 0 });
my $some_tag = $tags[0];

my @tags_permalink = $t_logged_in->app->repo->tags_filter(
  sub { defined $_->permalink and length($_->permalink) > 1 });
my $some_permalink = $tags_permalink[0];

my @teams     = $t_logged_in->app->repo->teams_all;
my $some_team = $teams[0];

my @authors
  = $t_logged_in->app->repo->authors_filter(sub { scalar($_->get_entries) > 0 }
  );
my $some_author = $authors[0];

# generated with: ./bin/bibspace routes | grep GET | grep -v :
my @pages = (
  $self->url_for('start'), $self->url_for('system_status'), "/forgot",
  "/login_form", "/youneedtologin", "/badpassword",  "/register",
  "/log",

  $self->url_for('add_publication'), $self->url_for('add_many_publications'),
  $self->url_for('recently_changed', num => 10),
  $self->url_for('recently_added',   num => 10),

  $self->url_for('manage_users'),        $self->url_for('fix_all_months'),
  $self->url_for('fix_attachment_urls'), $self->url_for('clean_ugly_bibtex'),
  $self->url_for('regenerate_html_for_all'),

  $self->url_for('fix_masters'),

  "/profile", "/backups", "/types", "/types/add", "/authors", "/authors/add",
  "/authors/reassign", "/authors/reassign_and_create", "/tagtypes",
  "/tagtypes/add", "/teams", "/teams/add", "/publications",
  $self->url_for('all_orphaned'), "/publications/candidates_to_delete",
  "/publications/missing_month", "/read/publications/meta", "/cron",
  "/cron/day", "/cron/night", "/cron/week", "/cron/month",
  "/logout",
);
# Logout must be last!

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
