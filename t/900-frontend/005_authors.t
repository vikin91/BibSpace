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

my @teams     = $op->app->repo->teams_all;
my $some_team = $teams[0];

my @authors
  = $op->app->repo->authors_filter(sub { scalar($_->get_entries) > 0 });
my $some_author = $authors[0];

subtest
  '(fixture) Master authors (7) should include visible (6) and invisible (1) authors'
  => sub {
  $op->get_ok($self->url_for('all_authors'))->status_is(200)
    ->content_like(qr/ExampleJohny/i)->content_like(qr/InvisibleHenry/i);

# Matches only first row of the table
# ->text_like('td p:only-child[class$=author-master-name]' => qr/InvisibleHenry/)

  $op->get_ok($self->url_for('all_authors')->query(visible => 1))
    ->status_is(200)->content_like(qr/ExampleJohny/i)
    ->content_unlike(qr/InvisibleHenry/i);

  $op->get_ok($self->url_for('all_authors')->query(visible => 0))
    ->status_is(200)
    ->text_like(
    'td p:only-child[class$=author-master-name]' => qr/InvisibleHenry/)
    ->text_unlike(
    'td p:only-child[class$=author-master-name]' => qr/ExampleJohny/);

  $op->get_ok($self->url_for('all_authors')->query(visible => 0, letter => 'I'))
    ->status_is(200)
    ->text_like(
    'td p:only-child[class$=author-master-name]' => qr/InvisibleHenry/)
    ->text_unlike(
    'td p:only-child[class$=author-master-name]' => qr/ExampleJohny/);

  $op->get_ok($self->url_for('all_authors')->query(visible => 0, letter => 'E'))
    ->status_is(200)
    ->text_unlike(
    'td p:only-child[class$=author-master-name]' => qr/InvisibleHenry/)
    ->text_unlike(
    'td p:only-child[class$=author-master-name]' => qr/ExampleJohny/);

  $op->get_ok($self->url_for('all_authors')->query(visible => 1, letter => 'E'))
    ->status_is(200)
    ->text_unlike(
    'td p:only-child[class$=author-master-name]' => qr/InvisibleHenry/)
    ->text_like(
    'td p:only-child[class$=author-master-name]' => qr/ExampleJohny/);
  };

subtest '(fixture) Check shortcut for first letters of authors' => sub {
  $op->get_ok($self->url_for('all_authors')->query(visible => 1))
    ->status_is(200)->element_exists('ul li a[class$=author-letter-E]')
    ->element_exists_not('ul li a[class$=author-letter-I]');

  $op->get_ok($self->url_for('all_authors')->query(visible => 0))
    ->status_is(200)->element_exists('ul li a[class$=author-letter-I]')
    ->element_exists_not('ul li a[class$=author-letter-E]');
};

subtest 'Add author post' => sub {

  $op->post_ok(
    $self->url_for('add_author') => {Accept     => '*/*'},
    form                         => {new_master => 'XTestMasterAutogen'}
  )->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/XTestMasterAutogen/);

  $op->post_ok(
    $self->url_for('add_author') => {Accept     => '*/*'},
    form                         => {new_master => 'XTestMasterAutogen'}
    )
    ->content_like(
    qr/Author with proposed master: XTestMasterAutogen already exists!/);
};

subtest '(fixture) Add author to team' => sub {
  my $author
    = $op->app->repo->authors_find(sub { $_->name eq 'XTestMasterAutogen' });
  ok($author->id > 1);
  my $aid   = $author->id;
  my $aname = $author->name;
  my $tname = $some_team->name;

  my $url = $self->url_for(
    'add_author_to_team',
    id  => $author->id,
    tid => $some_team->id
  );
  $op->get_ok($url)->status_is(200)
    ->content_like(qr/\QAuthor $aname has just joined team $tname/)
    ->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/XTestMasterAutogen/)
    ->text_like('span[class$=author-id]'        => qr/\Q$aid/);
};

subtest '(fixture) Edit author membership dates' => sub {
  my $author
    = $op->app->repo->authors_find(sub { $_->name eq 'XTestMasterAutogen' });
  ok($author->id > 1);
  my $aid   = $author->id;
  my $aname = $author->name;
  my $tname = $some_team->name;

  my $edit_get_url = $self->url_for('edit_author', id => $author->id);
  $op->get_ok($edit_get_url)->status_is(200)
    ->element_exists('span[class$=author-joined-team-year-0]')
    ->element_exists('span[class~=author-joined-team-id-1]')
    ->element_exists('span[class$=author-left-team-year-inf]')
    ->element_exists('span[class~=author-left-team-id-1]');

  $op->post_ok(
    $self->url_for('edit_author_membership_dates') => {Accept => '*/*'},
    form =>
      {aid => $aid, tid => $some_team->id, new_start => 2000, new_stop => 2018}
  )->status_is(200)->content_like(qr/Membership updated successfully/)
    ->element_exists('span[class$=author-joined-team-year-2000]')
    ->element_exists('span[class~=author-joined-team-id-1]')
    ->element_exists('span[class$=author-left-team-year-2018]')
    ->element_exists('span[class~=author-left-team-id-1]');
};

subtest '(fixture) Remove author from team' => sub {
  my $author
    = $op->app->repo->authors_find(sub { $_->name eq 'XTestMasterAutogen' });
  ok($author->id > 1);
  my $aid   = $author->id;
  my $aname = $author->name;

  $op->get_ok(
    $self->url_for(
      'remove_author_from_team',
      id  => $author->id,
      tid => $some_team->id
    )
  )->status_is(200)->content_like(qr/\QAuthor $aname has just left team/)
    ->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/XTestMasterAutogen/);
};

subtest '(fixture) Toggle author visibility' => sub {
  my $author
    = $op->app->repo->authors_find(sub { $_->name eq 'XTestMasterAutogen' });
  ok($author->id > 1);

  # Make invisible
  my $old_visibility = $author->display;
  $author->display(0);

  $op->get_ok($self->url_for('all_authors')->query(visible => 0, letter => 'X'))
    ->status_is(200)->element_exists('ul li a[class$=author-letter-X]')
    ->text_like(
    'td p:only-child[class$=author-master-name]' => qr/XTestMasterAutogen/);

  $op->get_ok($self->url_for('toggle_author_visibility', id => $author->id))
    ->status_is(200);

  $op->get_ok($self->url_for('all_authors')->query(visible => 1, letter => 'X'))
    ->status_is(200)->element_exists('ul li a[class$=author-letter-X]')
    ->text_like(
    'td p:only-child[class$=author-master-name]' => qr/XTestMasterAutogen/);

  $op->get_ok($self->url_for('toggle_author_visibility', id => $author->id))
    ->status_is(200);

  $op->get_ok($self->url_for('all_authors')->query(visible => 0, letter => 'X'))
    ->status_is(200)->element_exists('ul li a[class$=author-letter-X]')
    ->text_like(
    'td p:only-child[class$=author-master-name]' => qr/XTestMasterAutogen/);

  $author->display($old_visibility);
};

subtest 'Edit author post add user_id (name)' => sub {
  my $author
    = $op->app->repo->authors_find(sub { $_->name eq 'XTestMasterAutogen' });
  ok($author->id > 1);
  my $aid = $author->id;

  $op->post_ok(
    $self->url_for('edit_author') => {Accept => '*/*'},
    form => {id => $author->id, new_user_id => 'XTestMasterAutogen2'}
  )->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/XTestMasterAutogen/);

  $op->post_ok(
    $self->url_for('edit_author') => {Accept => '*/*'},
    form => {id => $author->id, new_user_id => 'XTestMasterAutogen2'}
    )
    ->content_like(
    qr/Cannot add user ID XTestMasterAutogen2. Such ID already exist. Maybe you want to merge authors instead?/
    );

  my $edit_get_url = $self->url_for('edit_author', id => $author->id);
  $op->get_ok($edit_get_url)->status_is(200)
    ->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/XTestMasterAutogen/)
    ->element_exists('a[class$=author-minor-name-XTestMasterAutogen2]')
    ->text_like('a[class$=author-minor-name-XTestMasterAutogen2]' =>
      qr/XTestMasterAutogen2/);
};

subtest 'Edit author remove minion (unlink)' => sub {
  my $author
    = $op->app->repo->authors_find(sub { $_->name eq 'XTestMasterAutogen' });
  ok($author->id > 1);
  my $minion
    = $op->app->repo->authors_find(sub { $_->name eq 'XTestMasterAutogen2' });
  ok($minion->id > 1);

  my $url = $self->url_for(
    'remove_author_uid',
    master_id => $author->id,
    minor_id  => $minion->id
  );
  $op->get_ok($url)->status_is(200);

  my $edit_get_url = $self->url_for('edit_author', id => $author->id);
  $op->get_ok($edit_get_url)->status_is(200)
    ->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/XTestMasterAutogen/)
    ->element_exists('a[class$=author-minor-name-XTestMasterAutogen]')
    ->text_like(
    'a[class$=author-minor-name-XTestMasterAutogen]' => qr/XTestMasterAutogen/)
    ->element_exists_not('a[class$=author-minor-name-XTestMasterAutogen3]');
};

subtest 'Edit author post change master name' => sub {
  my $author
    = $op->app->repo->authors_find(sub { $_->name eq 'XTestMasterAutogen' });
  ok($author->id > 1);

  $op->post_ok(
    $self->url_for('edit_author') => {Accept => '*/*'},
    form => {id => $author->id, new_master => 'XTestMasterAutogen3'}
  )->status_is(200)
    ->content_like(qr/Master name has been updated successfully/);

  my $edit_get_url = $self->url_for('edit_author', id => $author->id);
  $op->get_ok($edit_get_url)->status_is(200)
    ->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/XTestMasterAutogen3/);

  $op->post_ok(
    $self->url_for('edit_author') => {Accept => '*/*'},
    form => {id => $author->id, new_master => 'XTestMasterAutogen3'}
  )->status_is(200)->content_like(qr/This master name is already taken/);

  # Return to the original master name
  $op->post_ok(
    $self->url_for('edit_author') => {Accept => '*/*'},
    form => {id => $author->id, new_master => 'XTestMasterAutogen'}
  )->status_is(200)
    ->content_like(qr/Master name has been updated successfully/);
};

subtest 'Edit author delete' => sub {
  my $author
    = $op->app->repo->authors_find(sub { $_->name eq 'XTestMasterAutogen' });
  ok($author->id > 1);
  my $aid   = $author->id;
  my $aname = $author->name;

  my $delete_url = $self->url_for('delete_author', id => $author->id);
  $op->get_ok($delete_url)->status_is(200)
    ->content_like(qr/\QAuthor $aname ID $aid has been removed successfully/);

  my $edit_get_url = $self->url_for('edit_author', id => $author->id);
  $op->get_ok($edit_get_url)->status_is(200)
    ->content_like(qr/\QAuthor with id $aid does not exist!/);
};

subtest 'Edit author delete force' => sub {
  my $author
    = $op->app->repo->authors_find(sub { $_->name eq 'XTestMasterAutogen2' });
  ok($author->id > 1);
  my $aid   = $author->id;
  my $aname = $author->name;

  my $delete_url = $self->url_for('delete_author_force', id => $author->id);
  $op->get_ok($delete_url)->status_is(200)
    ->content_like(qr/\QAuthor $aname ID $aid has been removed successfully/);

  my $edit_get_url = $self->url_for('edit_author', id => $author->id);
  $op->get_ok($edit_get_url)->status_is(200)
    ->content_like(qr/\QAuthor with id $aid does not exist!/);
};

done_testing();
