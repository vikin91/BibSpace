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
    form                         => {new_master => 'TestMaster'}
    )->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/TestMaster/);

  $op->post_ok(
    $self->url_for('add_author') => {Accept     => '*/*'},
    form                         => {new_master => 'TestMaster'}
  )->content_like(qr/Author with proposed master: .+ already exists!/);
};

subtest '(fixture) Add author to team' => sub {
  my $author = $op->app->repo->authors_find(sub { $_->name eq 'TestMaster' });
  ok($author->id > 1);
  my $aid = $author->id;

  my $url = $self->url_for(
    'add_author_to_team',
    id  => $author->id,
    tid => $some_team->id
  );
  $op->get_ok($url)->status_is(200)
    ->content_like(qr/Author .+ has just joined team/)
    ->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/TestMaster/)
    ->text_like('span[class$=author-id]'        => qr/${aid}/);
};

subtest '(fixture) Remove author from team' => sub {
  my $author = $op->app->repo->authors_find(sub { $_->name eq 'TestMaster' });
  ok($author->id > 1);
  my $aid = $author->id;

  $op->get_ok(
    $self->url_for(
      'remove_author_from_team',
      id  => $author->id,
      tid => $some_team->id
    )
    )->status_is(200)->content_like(qr/Author .+ has just left team/)
    ->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/TestMaster/);

  # ->text_like('span[class$=author-id]' => qr/${aid}/);
};

subtest '(fixture) Toggle author visibility' => sub {
  my $author = $op->app->repo->authors_find(sub { $_->name eq 'TestMaster' });
  ok($author->id > 1);

  # Make invisible
  my $old_visibility = $author->display;
  $author->display(0);

  $op->get_ok($self->url_for('all_authors')->query(visible => 0, letter => 'T'))
    ->status_is(200)->element_exists('ul li a[class$=author-letter-T]')
    ->text_like('td p:only-child[class$=author-master-name]' => qr/TestMaster/);

  $op->get_ok($self->url_for('toggle_author_visibility', id => $author->id))
    ->status_is(200);

  $op->get_ok($self->url_for('all_authors')->query(visible => 1, letter => 'T'))
    ->status_is(200)->element_exists('ul li a[class$=author-letter-T]')
    ->text_like('td p:only-child[class$=author-master-name]' => qr/TestMaster/);

  $op->get_ok($self->url_for('toggle_author_visibility', id => $author->id))
    ->status_is(200);

  $op->get_ok($self->url_for('all_authors')->query(visible => 0, letter => 'T'))
    ->status_is(200)->element_exists('ul li a[class$=author-letter-T]')
    ->text_like('td p:only-child[class$=author-master-name]' => qr/TestMaster/);

  $author->display($old_visibility);
};

subtest 'Edit author post add user_id (name)' => sub {
  my $author = $op->app->repo->authors_find(sub { $_->name eq 'TestMaster' });
  ok($author->id > 1);

  $op->post_ok(
    $self->url_for('edit_author') => {Accept => '*/*'},
    form => {id => $author->id, new_user_id => 'TestMaster2'}
    )->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/TestMaster/);

  $op->post_ok(
    $self->url_for('edit_author') => {Accept => '*/*'},
    form => {id => $author->id, new_user_id => 'TestMaster2'}
    )
    ->content_like(
    qr/Cannot add user ID .+\. Such ID already exist. Maybe you want to merge authors instead\?/
    );

  my $edit_get_url = $self->url_for('edit_author', id => $author->id);
  $op->get_ok($edit_get_url)->status_is(200)
    ->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/TestMaster/)
    ->element_exists('a[class$=author-minor-name-TestMaster2]')
    ->text_like('a[class$=author-minor-name-TestMaster2]' => qr/TestMaster2/);
};

subtest 'Edit author remove minion (unlink)' => sub {
  my $author = $op->app->repo->authors_find(sub { $_->name eq 'TestMaster' });
  ok($author->id > 1);
  my $minion = $op->app->repo->authors_find(sub { $_->name eq 'TestMaster2' });
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
    ->text_like('h1[class$=author-master-name]' => qr/TestMaster/)
    ->element_exists('a[class$=author-minor-name-TestMaster]')
    ->text_like('a[class$=author-minor-name-TestMaster]' => qr/TestMaster/)
    ->element_exists_not('a[class$=author-minor-name-TestMaster3]');
};

subtest 'Edit author post change master name' => sub {
  my $author = $op->app->repo->authors_find(sub { $_->name eq 'TestMaster' });
  ok($author->id > 1);

  $op->post_ok(
    $self->url_for('edit_author') => {Accept => '*/*'},
    form => {id => $author->id, new_master => 'TestMaster3'}
  )->content_like(qr/Master name has been updated successfully/);

  my $edit_get_url = $self->url_for('edit_author', id => $author->id);
  $op->get_ok($edit_get_url)->status_is(200)
    ->element_exists('h1[class$=author-master-name]')
    ->text_like('h1[class$=author-master-name]' => qr/TestMaster3/);

  $op->post_ok(
    $self->url_for('edit_author') => {Accept => '*/*'},
    form => {id => $author->id, new_master => 'TestMaster3'}
  )->content_like(qr/This master name is already taken/);
};

done_testing();