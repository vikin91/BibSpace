use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Controller::Core;



my $t_anyone = Test::Mojo->new('BibSpace');
my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);
my $self = $t_logged_in->app;

$t_logged_in->ua->max_redirects(10);
$t_logged_in->ua->inactivity_timeout(3600);

my $dbh = $t_logged_in->app->db;

my @all_tag_type_objs = BibSpace::Functions::TagTypeObj->getAll($dbh);
my $some_tag_type_obj = $all_tag_type_objs[0];
my @tags = MTag->static_all($dbh);
my $some_tag = $tags[0];

my @teams = MTeam->static_all($dbh);
my $some_team = $teams[0];

# generated with: ./script/bibspace routes | grep GET | grep -v : 
my @pages = (
	"/",
	"/test",
	"/forgot",
	"/login_form",
	"/youneedtologin",
	"/badpassword",
	"/logout",
	"/register",
	"/log",
	"/settings/clean_all",
	"/settings/regenerate_all_force",
	$self->url_for('fix_attachment_urls'),
	$self->url_for('clean_ugly_bibtex'),
	$self->url_for('add_publication'),
	$self->url_for('add_many_publications'),
	$self->url_for('recently_changed', num=>10),
	$self->url_for('recently_added', num=>10),
	"/manage_users",
	"/settings/fix_entry_types",
	"/settings/fix_months",
	"/publications/fix_urls",
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
	"/publications-set",
	"/publications",
	"/publications/orphaned",
	"/publications/candidates_to_delete",
	"/publications/missing_month",
	"/publications/fix_urls",
	"/publications/sdqpdf",
	"/read/publications/meta",
	"/read/publications",
	"/r/publications",
	"/r/p",
	"/read/bibtex",
	"/r/bibtex",
	"/r/b",
	"/landing/publications",
	"/landing/publications?entry_type=paper",
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
	$self->url_for('get_authors_for_tag', tid=>$some_tag->{id}, type=>$some_tag_type_obj->{id}),
	$self->url_for('get_authors_for_tag_read', tid=>$some_tag->{id}, team=>$some_team->{id}),
	"/settings/regenerate_all"
);

for my $page (@pages){
    note "============ Testing page $page ============";
    $t_logged_in->get_ok($page)->status_isnt(404, "Checking: 404 $page")->status_isnt(500, "Checking: 500 $page");
}

done_testing();
