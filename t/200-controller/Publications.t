use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use BibSpace;
use BibSpace::Functions::Core;
use Data::Dumper;
use feature qw( state say );

my $admin_user = Test::Mojo->new('BibSpace');
$admin_user->post_ok(
  '/do_login' => {Accept => '*/*'},
  form        => {user   => 'pub_admin', pass => 'asdf'}
);

my $self       = $admin_user->app;
my $app_config = $admin_user->app->config;
$admin_user->ua->max_redirects(3);

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

my $test_file = Path::Tiny->new('fixture')->child('test_document.pdf');

ok(-e $test_file, "test pdf document exists");

ok(
  BibSpace::Controller::Publications::get_adding_editing_message_for_error_code(
    undef, 'ERR_BIBTEX'
  )
);
ok(
  BibSpace::Controller::Publications::get_adding_editing_message_for_error_code(
    undef, 'PREVIEW'
  )
);
ok(
  BibSpace::Controller::Publications::get_adding_editing_message_for_error_code(
    undef, 'ADD_OK'
  )
);
ok(
  BibSpace::Controller::Publications::get_adding_editing_message_for_error_code(
    undef, 'EDIT_OK'
  )
);
ok(
  BibSpace::Controller::Publications::get_adding_editing_message_for_error_code(
    undef, 'KEY_OK'
  )
);

# ok(BibSpace::Controller::Publications::get_adding_editing_message_for_error_code(undef, 'KEY_TAKEN')); # needs a real controller obj
ok(
  BibSpace::Controller::Publications::get_adding_editing_message_for_error_code(
    undef, 'WEIRD_SHIT'
  )
);

my @entries = $admin_user->app->repo->entries_all;
my $entry   = shift @entries;
my $author  = ($admin_user->app->repo->authors_all)[0];
my @teams   = $admin_user->app->repo->teams_all;
my $team    = shift @teams;
my @tags    = $admin_user->app->repo->tags_all;
my $tag     = shift @tags;

my $page = $self->url_for('add_publication');
$admin_user->get_ok($page, "Get for page $page")
  ->status_isnt(404, "Checking: 404 $page")
  ->status_isnt(500, "Checking: 500 $page");

subtest 'edit_publication_post' => sub {

  my @entries = $admin_user->app->repo->entries_all;
  my $entry   = shift @entries;

  ok($entry, "Find an entry to conduct test");

  my $bib_content = '
  @article{key_2017_TEST,
    author = {Johny Example},
    journal = {Journal of Bar},
    publisher = {Foo Publishing house},
    title = {{Selected aspects of some methods}},
    year = {2017},
    month = {January},
    day = {1--31},
  }';

  $admin_user->post_ok(
    $self->url_for('edit_publication_post', id => $entry->id) => form =>
      {new_bib => $bib_content, preview => 1});
  $admin_user->post_ok(
    $self->url_for('edit_publication_post', id => $entry->id) => form =>
      {new_bib => $bib_content, check_key => 1});
  $admin_user->post_ok(
    $self->url_for('edit_publication_post', id => $entry->id) => form =>
      {new_bib => $bib_content, save => 1});
  $admin_user->post_ok(
    $self->url_for('edit_publication_post', id => $entry->id) => form =>
      {new_bib => $bib_content, check_key => 1});
};

my $upload = {
  filetype      => 'paper',
  uploaded_file => {content => 'test', filename => 'test.pdf'}
};

my $upload_test_file = {
  filetype      => 'paper',
  uploaded_file => {file => "" . $test_file, filename => "" . $test_file}
};

my $upload_test_slides = {
  filetype      => 'slides',
  uploaded_file => {file => "" . $test_file, filename => "" . $test_file}
};

$admin_user->post_ok(
  $self->url_for('post_upload_pdf', id => $entry->id) => form => $upload,
  "Upload simple file OK"
);

ok(-e $self->app->get_upload_dir . "/papers/paper-" . $entry->id . ".pdf",
  "uploaded simple file exists");

$page = $self->url_for(
  'download_publication_pdf',
  filetype => 'paper',
  id       => $entry->id
);
$admin_user->get_ok($page, "Download simple file OK: $page")
  ->status_isnt(404, "Checking: 404 $page")
  ->status_isnt(500, "Checking: 500 $page");

$page = $self->url_for(
  'publications_remove_attachment',
  filetype => 'paper',
  id       => $entry->id
);
$admin_user->get_ok($page, "Get for page $page")
  ->status_isnt(404, "Checking: 404 $page")
  ->status_isnt(500, "Checking: 500 $page");

ok(!-e $self->app->get_upload_dir . "/papers/paper-" . $entry->id . ".pdf",
  "uploaded file was deleted correctly");

say "NOW UPLOADING REAL FILE" . Dumper $upload_test_file;

$admin_user->post_ok(
  $self->url_for('post_upload_pdf', id => $entry->id) => form =>
    $upload_test_file,
  "Upload real pdf file OK"
);

$admin_user->post_ok(
  $self->url_for('post_upload_pdf', id => $entry->id) => form =>
    $upload_test_slides,
  "Upload real pdf with slides file OK"
);

$page = $self->url_for(
  'download_publication_pdf',
  filetype => 'paper',
  id       => $entry->id
);
$admin_user->get_ok($page, "Download real file OK: $page")
  ->status_isnt(404, "Checking: 404 $page")
  ->status_isnt(500, "Checking: 500 $page");

$page = $self->url_for(
  'download_publication_pdf',
  filetype => 'slides',
  id       => $entry->id
);
$admin_user->get_ok($page, "Download real file OK: $page")
  ->status_isnt(404, "Checking: 404 $page")
  ->status_isnt(500, "Checking: 500 $page");

ok(-e $self->app->get_upload_dir . "/papers/paper-" . $entry->id . ".pdf",
  "file uploaded again exists");

my $upload2 = {
  filetype      => 'paper',
  uploaded_file => {content => 'test2', filename => 'test.docx'}
};

$admin_user->post_ok(
  $self->url_for('post_upload_pdf', id => $entry->id) => form => $upload2);

$page = $self->url_for('download_publication', filetype => 'paper',
  id => $entry->id);
$admin_user->get_ok($page, "Get for page $page")

  #->status_isnt(404, "Checking: 404 $page")
  ->status_isnt(500, "Checking: 500 $page");

$page = $self->url_for(
  'publications_remove_attachment',
  filetype => 'paper',
  id       => $entry->id
);
$admin_user->get_ok($page, "Get for page $page")
  ->status_isnt(404, "Checking: 404 $page")
  ->status_isnt(500, "Checking: 500 $page");

# call twice to remove the non-existing file
$page = $self->url_for(
  'publications_remove_attachment',
  filetype => 'paper',
  id       => $entry->id
);
$admin_user->get_ok($page, "Get for page $page")
  ->status_isnt(404, "Checking: 404 $page")
  ->status_isnt(500, "Checking: 500 $page");

$page = $self->url_for('download_publication', filetype => 'paper',
  id => $entry->id);
$admin_user->get_ok($page, "Get for page $page")
  ->status_isnt(500, "Checking: 500 $page")
  ->status_is(404, "Checking: 404 $page")
  ;    # this should give 404, the attachment has been removed

subtest 'add_publication_post' => sub {

  my $random_string = random_string(16);

  my $bib_content = '
  @article{key_2017_TEST' . $random_string . ',
    author = {Johny Example},
    journal = {Journal of Bar},
    publisher = {Foo Publishing house},
    title = {{Selected aspects of some methods}},
    year = {2017},
    month = {January},
    day = {1--31},
  }';

  $admin_user->post_ok($self->url_for('add_publication_post') => form =>
      {new_bib => $bib_content, preview => 1});
  $admin_user->post_ok($self->url_for('add_publication_post') => form =>
      {new_bib => $bib_content, check_key => 1});
  $admin_user->post_ok($self->url_for('add_publication_post') => form =>
      {new_bib => $bib_content, save => 1});

  # again to get key conflict
  $admin_user->post_ok($self->url_for('add_publication_post') => form =>
      {new_bib => $bib_content, check_key => 1});
  $admin_user->post_ok($self->url_for('add_publication_post') => form =>
      {new_bib => $bib_content, save => 1});

  $admin_user->post_ok($self->url_for('add_publication_post') => form =>
      {new_bib => '@bad_content!', save => 1});
};

# generated with: ./bin/bibspace routes | grep GET | grep -v :
my @pages = (
  $self->url_for('publications'), $self->url_for('recently_added', num => 10),
  $self->url_for('recently_changed', num => 10),

  $self->url_for('get_single_publication', id => 0),
  $self->url_for('get_single_publication', id => $entry->id),

  $self->url_for('toggle_hide_publication', id => $entry->id),
  $self->url_for('toggle_hide_publication', id => 0),

  $self->url_for('make_paper', id => $entry->id),
  $self->url_for('make_talk',  id => $entry->id),

  $self->url_for('make_paper', id => 0), $self->url_for('make_talk', id => 0),

  $self->url_for('edit_publication', id => $entry->id),
  $self->url_for('edit_publication', id => 0),

  $self->url_for('regenerate_publication', id => $entry->id),
  $self->url_for('regenerate_publication', id => 0),

  $self->url_for('get_untagged_publications', tagtype => 1)
    ->query(author => $author->id),
  $self->url_for('get_untagged_publications', tagtype => 1)
    ->query(author => 'NotExistingAuthor'),

  $self->url_for('discover_attachments', id => $entry->id),
  $self->url_for('discover_attachments', id => 0),

  "/publications/missing_month", "/publications/candidates_to_delete",

  $self->url_for('all_orphaned'), $self->url_for('delete_orphaned'),

  $self->url_for('regenerate_html_for_all'),

  $self->url_for('mark_author_to_regenerate', author_id  => $author->id),
  $self->url_for('regenerate_html_in_chunk',  chunk_size => 3),
  $self->url_for('mark_all_to_regenerate'),

  $self->url_for('fix_attachment_urls'), $self->url_for('clean_ugly_bibtex'),
  $self->url_for('fix_all_months'),
  $self->url_for('unrelated_papers_for_team', teamid => $team->id),

# $self->url_for('download_publication', filetype=>'paper', id=>$entry->id),
# $self->url_for('publications_remove_attachment', filetype=>'paper', id=>$entry->id),

  $self->url_for('manage_tags', id => 0),
  $self->url_for('manage_tags', id => $entry->id),
  $self->url_for('add_tag_to_publication', eid => $entry->id, tid => $tag->id),
  $self->url_for(
    'remove_tag_from_publication',
    eid => $entry->id,
    tid => $tag->id
  ),

  $self->url_for('manage_attachments', id => 0),
  $self->url_for('manage_attachments', id => $entry->id),

  $self->url_for('fix_attachment_urls', id => 0),
  $self->url_for('fix_attachment_urls', id => $entry->id),

  $self->url_for('manage_exceptions', id => 0),
  $self->url_for('manage_exceptions', id => $entry->id),

  $self->url_for(
    'add_exception_to_publication',
    eid => $entry->id,
    tid => $team->id
  ),
  $self->url_for('add_exception_to_publication', eid => 0, tid => $team->id),

  $self->url_for(
    'remove_exception_from_publication',
    eid => $entry->id,
    tid => $team->id
  ),
  $self->url_for(
    'remove_exception_from_publication',
    eid => $entry->id,
    tid => $team->id
  ),
  $self->url_for(
    'remove_exception_from_publication',
    eid => 0,
    tid => $team->id
  ),

  $self->url_for('show_authors_of_entry', id => 0),
  $self->url_for('show_authors_of_entry', id => $entry->id),

  $self->url_for('delete_publication_sure', id => 0),
  $self->url_for('delete_publication_sure', id => $entry->id),
);

# subtest 'loop over pages' => sub {
for my $page (@pages) {
  note "============ Testing page $page ============";
  $admin_user->get_ok($page, "Get for page $page")
    ->status_isnt(404, "Checking: 404 $page")
    ->status_isnt(500, "Checking: 500 $page");
}

# };

ok(1);
done_testing();
