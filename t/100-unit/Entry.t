use Mojo::Base -strict;
use Test::More 0.96;
use Test::Mojo;
use Test::Exception;
use Data::Dumper;
use Array::Utils qw(:all);

use BibSpace::Model::Entry;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self     = $t_anyone->app;

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

my $repo = $self->app->repo;

my @all_entries = $repo->entries_all;

my $limit_test_entries = 10;

note "============ Testing " . scalar(@all_entries) . " Entries ============";

foreach my $entry (@all_entries) {
  last if $limit_test_entries < 0;
  note ">> Testing Entry ID " . $entry->id . ".";

  ok($entry->equals($entry), "Entry is equal to itself");
  dies_ok(sub { $entry->equals(undef) }, 'equals undef expecting to die');

  ok($entry->equals_bibtex($entry), "Entry is equal_bibtex to itself");
  dies_ok(
    sub { $entry->equals_bibtex(undef) },
    'equal_bibtex undef expecting to die'
  );

  $entry->make_paper;
  ok($entry->is_paper);
  $entry->make_talk;
  ok($entry->is_talk);

  $entry->hide;
  ok($entry->is_hidden);
  $entry->toggle_hide;
  ok(!$entry->is_hidden);
  $entry->hide;
  ok($entry->is_hidden);
  $entry->unhide;
  ok(!$entry->is_hidden);

  ok(!$entry->has_bibtex_field("test"));
  isnt(!$entry->get_bibtex_field_value("test"), "test_value");
  $entry->add_bibtex_field("test", "test_value");
  ok($entry->has_bibtex_field("test"));
  is($entry->get_bibtex_field_value("test"), "test_value");

  if ($entry->has_bibtex_field('month')) {
    is($entry->remove_bibtex_fields(['month']), 1,
      "removed month bibtex field");
    $entry->month(0);
  }
  $entry->add_bibtex_field("month", "April");
  ok($entry->fix_month, "month fixed");
  is($entry->month, 4, "month fixed correctly");

  if ($entry->has_bibtex_field('author')) {
    my @author_names = $entry->author_names_from_bibtex;
    ok(scalar @author_names > 0, "Entry has authors in bibtex");
  }
  else {
    $entry->add_bibtex_field("author", "James Bond");
    my @author_names = $entry->author_names_from_bibtex;
    is(scalar @author_names, 1, "Entry has 1 author in bibtex");
  }

  note "Testing case where there are no authors but there are editors";
  $entry->remove_bibtex_fields(['author']);
  if ($entry->has_bibtex_field('editor')) {
    my @author_names = $entry->author_names_from_bibtex;
    ok(scalar @author_names > 0, "Entry has editors in bibtex");
  }
  else {
    $entry->add_bibtex_field("editor", "James Bond");
    my @author_names = $entry->author_names_from_bibtex;
    is(scalar @author_names, 1, "Entry has 1 editor in bibtex");
  }

  # readd removed field
  $entry->add_bibtex_field("author", "James Bond");

  if ($entry->has_bibtex_field('tags')) {
    is($entry->remove_bibtex_fields(['tags']), 1, "remove tags bibtex field");
    my @no_tag_names = $entry->tag_names_from_bibtex;
    is(scalar @no_tag_names, 0, "Entry has no tags in bibtex");
  }
  $entry->add_bibtex_field("tags", "test_tag");
  my @tag_names = $entry->tag_names_from_bibtex;
  is(scalar @tag_names, 1, "Entry has more than one tag in bibtex");

  # just call
  $entry->get_title;

  $self->app->preferences->bibitex_html_converter('BibStyleConverter');
  $entry->regenerate_html(1, $self->app->bst, $self->app->bibtexConverter);
  $self->app->preferences->bibitex_html_converter('Bibtex2HtmlConverter');
  $entry->regenerate_html(1, $self->app->bst, $self->app->bibtexConverter);
  $self->app->preferences->bibitex_html_converter('BibStyleConverter');

  $limit_test_entries = $limit_test_entries - 1;
}

my $broken_entry = $self->app->entityFactory->new_Entry(bib => ' ');
$broken_entry->regenerate_html(1, $self->app->bst, $self->app->bibtexConverter);

done_testing();
