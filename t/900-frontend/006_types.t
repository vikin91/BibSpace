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

subtest 'Show all types' => sub {
  my $page = $self->url_for('all_types');
  $op->get_ok($page)->status_is(200)->status_isnt(404)->status_isnt(500)
    ->element_exists('p[class$=type-name-article]')
    ->text_like('p[class$=type-name-article]' => qr/article/);
};

subtest 'Manage type' => sub {
  my $page = $self->url_for('edit_type', name => 'article');
  $op->get_ok($page, "Get for page $page")->status_is(200)->status_isnt(404)
    ->status_isnt(500);
};

subtest 'Add new our type' => sub {
  $op->post_ok(
    $self->url_for('add_type_post') => {Accept   => '*/*'},
    form                            => {new_type => 'XTestType'}
  )->element_exists('p[class$=type-name-XTestType]')
    ->text_like('p[class$=type-name-XTestType]' => qr/XTestType/);
};

subtest 'Update type description' => sub {
  $op->post_ok(
    $self->url_for('update_type_description') => {Accept => '*/*'},
    form => {our_type => 'XTestType', new_description => "This is test type"}
  )->element_exists('input[class$=type-description]')
    ->element_exists(
    'input[class$=type-description][value=\'This is test type\']');

  my $page = $self->url_for('edit_type', name => 'XTestType');
  $op->get_ok($page)->status_is(200)
    ->element_exists('input[class$=type-description]')
    ->element_exists(
    'input[class$=type-description][value=\'This is test type\']');
};

subtest 'Update type mapping' => sub {
  my $page = $self->url_for(
    'map_bibtex_type',
    our_type    => 'XTestType',
    bibtex_type => 'article'
  );
  $op->get_ok($page)->status_is(200)
    ->element_exists('span[class$=type-mapped-article]')
    ->element_exists('span[class$=type-mapped-dummy]');

  my $page_edit = $self->url_for('edit_type', name => 'XTestType');
  $op->get_ok($page_edit)->status_is(200)
    ->element_exists('span[class$=type-mapped-article]')
    ->element_exists('span[class$=type-mapped-dummy]');
};

subtest 'Remove legal type mapping' => sub {
  my $page = $self->url_for(
    'unmap_bibtex_type',
    our_type    => 'XTestType',
    bibtex_type => 'article'
  );
  $op->get_ok($page)->status_is(200)
    ->element_exists_not('span[class$=type-mapped-article]')
    ->element_exists('span[class$=type-mapped-dummy]');

  my $page_edit = $self->url_for('edit_type', name => 'XTestType');
  $op->get_ok($page_edit)->status_is(200)
    ->element_exists_not('span[class$=type-mapped-article]')
    ->element_exists('span[class$=type-mapped-dummy]');
};

subtest 'Remove dummy type mapping' => sub {
  my $map_page = $self->url_for(
    'map_bibtex_type',
    our_type    => 'XTestType',
    bibtex_type => 'article'
  );
  $op->get_ok($map_page)->status_is(200)
    ->element_exists('span[class$=type-mapped-article]')
    ->element_exists('span[class$=type-mapped-dummy]');

  my $unmap_page = $self->url_for(
    'unmap_bibtex_type',
    our_type    => 'XTestType',
    bibtex_type => 'dummy'
  );
  $op->get_ok($unmap_page)->status_is(200)
    ->element_exists('span[class$=type-mapped-article]')
    ->element_exists_not('span[class$=type-mapped-dummy]');

  my $page_edit = $self->url_for('edit_type', name => 'XTestType');
  $op->get_ok($page_edit)->status_is(200)
    ->element_exists('span[class$=type-mapped-article]')
    ->element_exists_not('span[class$=type-mapped-dummy]');
};

subtest 'Remove all mappings' => sub {
  my $unmap_page = $self->url_for(
    'unmap_bibtex_type',
    our_type    => 'XTestType',
    bibtex_type => 'dummy'
  );
  $op->get_ok($unmap_page)->status_is(200)
    ->element_exists_not('span[class$=type-mapped-dummy]');

# This will crash, because we cannot remove all mappings
# TODO: This shouldn't crash - there should be a reasonable message explaining user why the last mapping cannot be removed
  my $unmap_page2 = $self->url_for(
    'unmap_bibtex_type',
    our_type    => 'XTestType',
    bibtex_type => 'article'
  );
  $op->get_ok($unmap_page2)->status_is(500)
    ->element_exists_not('span[class$=type-mapped-dummy]');
};

subtest 'Remove type' => sub {
  $op->post_ok(
    $self->url_for('add_type_post') => {Accept   => '*/*'},
    form                            => {new_type => 'XTestType'}
  )->element_exists('p[class$=type-name-XTestType]')
    ->text_like('p[class$=type-name-XTestType]' => qr/XTestType/);

  my $all_page = $self->url_for('all_types');
  $op->get_ok($all_page)->status_is(200)->status_isnt(404)
    ->element_exists('p[class$=type-name-XTestType]')
    ->text_like('p[class$=type-name-XTestType]' => qr/XTestType/)
    ->element_exists('p[class$=type-name-article]')
    ->text_like('p[class$=type-name-article]' => qr/article/);

  my $delete_type = $self->url_for('delete_type', name => 'XTestType');
  $op->get_ok($delete_type)->status_is(200)
    ->element_exists('p[class$=type-name-article]')
    ->element_exists_not('p[class$=type-name-XTestType]');

  $op->get_ok($all_page)->status_is(200)->status_isnt(404)
    ->element_exists_not('p[class$=type-name-XTestType]')
    ->element_exists('p[class$=type-name-article]')
    ->text_like('p[class$=type-name-article]' => qr/article/);
};

ok(1);
done_testing();

