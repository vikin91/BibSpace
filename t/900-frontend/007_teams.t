use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use BibSpace;
use BibSpace::Functions::Core;

my $op   = Test::Mojo->new('BibSpace');
my $self = $op->app;
use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

$op->post_ok(
  '/do_login' => {Accept => '*/*'},
  form        => {user   => 'pub_admin', pass => 'asdf'}
);

$self = $op->app;
my $app_config = $op->app->config;
$op->ua->max_redirects(10);

my @tts     = $op->app->repo->tagTypes_all;
my $some_tt = $tts[0];

subtest 'Show all teams' => sub {
  my $page = $self->url_for('all_teams');
  $op->get_ok($page)->status_is(200)->status_isnt(404)->status_isnt(500)
    ->element_exists('span[class$=team-name-SE-WUERZBURG]')
    ->text_like('span[class$=team-name-SE-WUERZBURG]' => qr/SE-WUERZBURG/);
};

subtest 'Edit team' => sub {
  my $page = $self->url_for('edit_team', id => 1);
  $op->get_ok($page)->status_is(200)->status_isnt(404)->status_isnt(500)
    ->element_exists('h1[class$=team-name-SE-WUERZBURG]')
    ->text_like('h1[class$=team-name-SE-WUERZBURG]' => qr/Team SE-WUERZBURG/);
};

subtest 'Edit non-existing team' => sub {
  my $page = $self->url_for('edit_team', id => 999);
  $op->get_ok($page)->status_is(200)->status_isnt(404)->status_isnt(500)
    ->element_exists('div[class$=alert-danger]')
    ->text_like('div[class$=alert-danger]' => qr/There is no team with id 999/);
};

# TODO: Finish this test suite

ok(1);
done_testing();

