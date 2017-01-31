use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use BibSpace;
use BibSpace::Functions::Core;


my $admin_user = Test::Mojo->new('BibSpace');
$admin_user->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);


my $self = $admin_user->app;
my $app_config = $admin_user->app->config;

# uncommentig this causes "premature connection close"
# SKIP: {
#   note "============ APPLY DATABASE FIXTURE ============";
#   skip "Directory $fixture_dir does not exist", 1 if !-e $fixture_dir.$fixture_name;

#   my $status = 0;
#   $status = BibSpace::Functions::BackupFunctions::do_restore_backup_from_file($self, $dbh, "./fixture/".$fixture_name, $app_config);
#   is($status, 1, "Fixture read correctly");
#   $self->repo->hardReset;
#   $self->setup_repositories;
# }


$admin_user->ua->max_redirects(3);
# $admin_user->ua->inactivity_timeout(3600);



# my @all_tag_type_objs = $admin_user->app->repo->tagTypes_all;
# my $some_tag_type_obj = $all_tag_type_objs[0];

# my @tags = $admin_user->app->repo->tags_all;
# my $some_tag = $tags[0];

# my @teams = $admin_user->app->repo->teams_all;
# my $some_team = $teams[0];

# generated with: ./bin/bibspace routes | grep GET | grep -v : 
my @pages = (
  $self->url_for('publications'),
  $self->url_for('recently_added', num=> 10),
  $self->url_for('recently_changed', num=> 10),
  $self->url_for('get_untagged_publications'),
  "/publications/fix_urls",
  # "/publications/orphaned",
  # "/publications/candidates_to_delete",
  # "/publications/missing_month",
  # "/read/publications/meta",
  # "/read/publications",
  # "/r/publications",
  # "/r/p",
  # "/read/bibtex",
  # "/r/bibtex",
  # "/r/b",
  # "/landing/publications",
  # "/landing/publications?entry_type=paper",
  # "/landing/publications?entry_type=paper&bibtex_type=inproceedings",
  # "/landing/publications?entry_type=talk",
  # "/landing/publications?entry_type=talk&bibtex_type=misc",
  # "/l/p",
  # "/landing-years/publications",
  # "/landing-years/publications?entry_type=paper",
  # "/landing-years/publications?entry_type=paper&year=2013",
  # "/landing-years/publications?entry_type=paper&year=2013&bibtex_type=inproceedings",
  # "/landing-years/publications?entry_type=talk",
  # "/landing-years/publications?entry_type=talk&year=2013",
  # "/landing-years/publications?entry_type=talk&year=2013&bibtex_type=misc",
  # "/ly/p"
);

for my $page (@pages){
    note "============ Testing page $page ============";
    $admin_user->get_ok($page, "Get for page $page")
      ->status_isnt(404, "Checking: 404 $page")
      ->status_isnt(500, "Checking: 500 $page");
}

done_testing();
