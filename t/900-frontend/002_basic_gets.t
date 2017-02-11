use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Functions::Core;


my $t_logged_in = Test::Mojo->new('BibSpace');
my $self = $t_logged_in->app;
use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);


$self = $t_logged_in->app;
my $app_config = $t_logged_in->app->config;
$t_logged_in->ua->max_redirects(3);


my @all_tag_type_objs = $t_logged_in->app->repo->tagTypes_all;
my $some_tag_type_obj = $all_tag_type_objs[0];

my @tags = $t_logged_in->app->repo->tags_all;
my $some_tag = $tags[0];

my @teams = $t_logged_in->app->repo->teams_all;
my $some_team = $teams[0];

# generated with: ./bin/bibspace routes | grep GET | grep -v : 
my @pages = (
	$self->url_for('start'),
	$self->url_for('system_status'),
	"/forgot",
	"/login_form",
	"/youneedtologin",
	"/badpassword",
	"/logout",
	"/register",
	"/log",
	

	$self->url_for('add_publication'),
	$self->url_for('add_many_publications'),
	$self->url_for('recently_changed', num=>10),
	$self->url_for('recently_added', num=>10),

	$self->url_for('manage_users'),
	$self->url_for('fix_all_months'),
	$self->url_for('fix_attachment_urls'),
	$self->url_for('clean_ugly_bibtex'),

	$self->url_for('fix_masters'),

	"/profile",
	"/backups",
	"/types",
	"/types/add",
	"/authors",
	"/authors/add",
	"/authors/reassign",
	"/authors/reassign_and_create",
	"/tagtypes",
	"/tagtypes/add",
	"/teams",
	"/teams/add",
	"/publications",
	"/publications/orphaned",
	"/publications/candidates_to_delete",
	"/publications/missing_month",
	"/read/publications/meta",
	"/read/publications",
	"/r/publications",
	"/r/p",
	"/read/bibtex",
	"/r/bibtex",
	"/r/b",
	"/landing/publications",
	"/landing/publications?entry_type=paper",
	"/landing/publications?entry_type=paper&team=1",
	"/landing/publications?entry_type=paper&tag=not-existing",
	"/landing/publications?entry_type=paper&permalink=B2",
	"/landing/publications?entry_type=paper&permalink=not-existing",
	"/landing/publications?entry_type=paper&bibtex_type=inproceedings",
	"/landing/publications?entry_type=talk",
	"/landing/publications?entry_type=talk&bibtex_type=misc",
	"/l/p",
	"/landing-years/publications",
	"/landing-years/publications?entry_type=paper",
	"/landing-years/publications?entry_type=paper&year=2013",
	"/landing-years/publications?entry_type=paper&year=2013&bibtex_type=inproceedings",
	"/landing-years/publications?entry_type=talk",
	"/landing-years/publications?entry_type=talk&year=2013",
	"/landing-years/publications?entry_type=talk&year=2013&bibtex_type=misc",
	"/ly/p",
	"/cron",
	"/cron/day",
	"/cron/night",
	"/cron/week",
	"/cron/month",
	$self->url_for('get_authors_for_tag', id=>$some_tag->id, type=>$some_tag_type_obj->id),
	$self->url_for('get_authors_for_tag_and_team', tag_id=>$some_tag->id, team_id=>$some_team->id),

	# $self->url_for('regenerate_html_for_all_force'), # this will take too long to test
	$self->url_for('regenerate_html_for_all'),
);

my $ws_page;
$ws_page = $self->url_for('show_stats_websocket', num => 10); 
$t_logged_in->websocket_ok($ws_page, "Websocket OK for $ws_page");
$ws_page = $self->url_for('show_log_websocket', num => 10); 
$t_logged_in->websocket_ok($ws_page, "Websocket OK for $ws_page");

for my $page (@pages){
    note "============ Testing page $page ============";
    $t_logged_in->get_ok($page, "Get for page $page")
    	->status_isnt(404, "Checking: 404 $page")
    	->status_isnt(500, "Checking: 500 $page");
}

done_testing();
