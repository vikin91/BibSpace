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

subtest '(fixture) Add merge authors using author IDs' => sub {
  my $author_from
    = $op->app->repo->authors_find(sub { $_->name eq 'TestMinion' });
  my $author_to
    = $op->app->repo->authors_find(sub { $_->name eq 'TestMaster' });
  ok($author_from);
  ok($author_to);
  my $aname_from = $author_from->name;
  my $aname_to   = $author_to->name;

  note "Merging TestMinion into TestMaster";
  $op->post_ok(
    $self->url_for('merge_authors') => {Accept => '*/*'},
    form => {author_to => $author_to->id, author_from => $author_from->id}
  )->status_is(200)->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/TestMaster/)
    ->content_like(qr/\Q Author TestMinion was merged into TestMaster/);

  my $edit_get_url = $self->url_for('edit_author', id => $author_to->id);
  $op->get_ok($edit_get_url)->status_is(200)
    ->element_exists('a[class$=author-minor-name-TestMinion]')
    ->text_like('a[class$=author-minor-name-TestMinion]' => qr/TestMinion/)
    ->element_exists('a[class$=author-minor-name-TestMaster]')
    ->text_like('a[class$=author-minor-name-TestMaster]' => qr/TestMaster/);

  my @entries_master = $author_to->get_entries;
  my @entries_minion = $author_from->get_entries;

 # 3 is a magic number calculated from fixture data
 # master and minion have 1 common paper, and 1 separate paper each - total is 3
  is(scalar @entries_master,
    3, "Master author should have 3 entries after merging");
  is(scalar @entries_minion,
    0, "Minion author should have 0 entries after merging");

};

subtest 'Edit author remove minion (unlink)' => sub {
  my $author = $op->app->repo->authors_find(sub { $_->name eq 'TestMaster' });
  ok($author->id > 1);
  my $minion = $op->app->repo->authors_find(sub { $_->name eq 'TestMinion' });
  ok($minion->id > 1);

  my $url = $self->url_for(
    'remove_author_uid',
    master_id => $author->id,
    minor_id  => $minion->id
  );
  $op->get_ok($url)->status_is(200);

  my $edit_get_url_master = $self->url_for('edit_author', id => $author->id);
  $op->get_ok($edit_get_url_master)->status_is(200)
    ->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/TestMaster/)
    ->element_exists('a[class$=author-minor-name-TestMaster]')
    ->text_like('a[class$=author-minor-name-TestMaster]' => qr/TestMaster/)
    ->element_exists_not('a[class$=author-minor-name-TestMinion]');

  my $edit_get_url_minion = $self->url_for('edit_author', id => $minion->id);
  $op->get_ok($edit_get_url_minion)->status_is(200)
    ->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/TestMinion/)
    ->element_exists('a[class$=author-minor-name-TestMinion]')
    ->text_like('a[class$=author-minor-name-TestMinion]' => qr/TestMinion/)
    ->element_exists_not('a[class$=author-minor-name-TestMaster]');

  # TODO: run reassign?

  my @entries_master = $author->get_entries;
  my @entries_minion = $minion->get_entries;

 # 2 are magic numbers calculated from fixture data
 # master and minion have 1 common paper, and 1 separate paper each - total is 3
  is(scalar @entries_master,
    2, "Master author should have 3 entries after merging");
  is(scalar @entries_minion,
    2, "Minion author should have 0 entries after merging");

};

done_testing();
