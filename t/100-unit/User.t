use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Exception;

my $t_logged_in = Test::Mojo->new('BibSpace');
my $self        = $t_logged_in->app;
$t_logged_in->post_ok(
  '/do_login' => {Accept => '*/*'},
  form        => {user   => 'pub_admin', pass => 'asdf'}
);
use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

my $repo      = $self->app->repo;
my @all_users = $repo->users_all;

# my $author = ($repo->authors_all)[0];
# my $author2 = ($repo->authors_all)[1];
# my $entry = ($repo->entries_all)[0];

my $limit_num_tests = 20;

my $me = $repo->users_find(sub { $_->login eq 'pub_admin' });

note "============ Testing " . scalar(@all_users) . " users ============";

foreach my $user (@all_users) {
  last if $limit_num_tests < 0;

  note "============ Testing User ID " . $user->id . ".";

  if (!$user->equals($me)) {
    ok($user->make_admin,   "make_admin");
    ok($user->make_manager, "make_manager");
    ok($user->make_user,    "make_user");
    ok($user->make_manager, "make_manager");
    ok($user->make_admin,   "make_admin");
    ok($user->make_user,    "make_user");
    is($user->get_forgot_pass_token, undef, "get forgot_token should be undef");
    $user->set_forgot_pass_token("aabbcc");
    is($user->get_forgot_pass_token,
      "aabbcc", "get forgot_token should be aabbcc");
    $user->reset_forgot_token;
    is($user->get_forgot_pass_token,
      undef, "get forgot_token should be undef again");
  }

  $limit_num_tests--;
}

ok(1);
done_testing();
