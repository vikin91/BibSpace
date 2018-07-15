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
  warn $url;
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

done_testing();
