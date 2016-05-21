use Mojo::Base -strict;

BEGIN {
  # $ENV{BIBSPACE_CONFIG}    = 'config/testing.conf';
  $ENV{BIBSPACE_CONFIG}    = 'config/development.conf';
}

use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Controller::Core;
use BibSpace::Functions::EntryObj;



my $t_anyone = Test::Mojo->new('BibSpace');
my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);
my $self = $t_logged_in->app;


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
	"/manage_users",
	"/settings/fix_entry_types",
	"/settings/fix_months",
	"/publications/fix_urls",
	"/profile",
	"/settings/regenerate_all",
	"/backups",
	"/types",
	"/types/add",
	"/authors",
	"/authors/add",
	"/authors/reassign",
	"/authors/reassign_and_create",
	"/authors/toggle_visibility",
	"/tagtypes",
	"/tagtypes/add",
	"/teams",
	"/teams/add",
	"/publications-set",
	"/publications",
	"/publications/orphaned",
	"/publications/candidates_to_delete",
	"/publications/missing_month",
	"/publications/sdqpdf",
	"/publications/add",
	"/publications/add_many",
	"/read/publications/meta",
	"/read/publications",
	"/r/publications",
	"/r/p",
	"/read/bibtex",
	"/r/bibtex",
	"/r/b",
	"/landing/publications",
	"/l/p",
	"/landing-years/publications",
	"/ly/p",
	"/cron",
	"/cron/day",
	"/cron/night",
	"/cron/week",
	"/cron/month",
);

for my $page (@pages){
    note "============ Testing page $page ============";
    $t_logged_in->get_ok($page)->status_isnt(404, "Checking: 404 $page")->status_isnt(500, "Checking: 500 $page");
}

done_testing();
