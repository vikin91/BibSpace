use Mojo::Base -strict;
use Test::More 0.96;
use Test::Mojo;
use Test::Exception;
use Data::Dumper;
use Array::Utils qw(:all);

use BibSpace::Model::Entry;
use BibSpace::Model::Preferences;

my $t_anyone    = Test::Mojo->new('BibSpace');
my $self = $t_anyone->app;

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);


my $repo = $self->app->repo;


my @all_entries = $repo->entries_all;

my $limit_test_entries = 20;

note "============ Testing ".scalar(@all_entries)." entries ============";

foreach my $entry(@all_entries){
  last if $limit_test_entries < 0;
  note ">> Testing Entry ID ".$entry->id.".";


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

  if( $entry->has_bibtex_field('month') ){
      is( $entry->remove_bibtex_fields(['month']), 1, "removed month bibtex field");
      $entry->month(0);
  } 
  $entry->add_bibtex_field("month", "April");
  ok( $entry->fix_month, "month fixed");
  is( $entry->month, 4, "month fixed correctly");

  if( $entry->has_bibtex_field('author') or $entry->has_bibtex_field('editor') ){
    my @author_names = $entry->author_names_from_bibtex;
    ok( scalar @author_names > 0, "Entry has authors in bibtex");
  }
  else{
    $entry->add_bibtex_field("author", "James Bond");  
    my @author_names = $entry->author_names_from_bibtex;
    is( scalar @author_names, 1, "Entry has 1 author in bibtex");
  }

  if( $entry->has_bibtex_field('tags') ){
      is( $entry->remove_bibtex_fields(['tags']), 1, "remove tags bibtex field");
      my @no_tag_names = $entry->tag_names_from_bibtex;
      is( scalar @no_tag_names, 0, "Entry has no tags in bibtex");
  } 
  $entry->add_bibtex_field("tags", "test_tag");
  my @tag_names = $entry->tag_names_from_bibtex;
  is( scalar @tag_names, 1, "Entry has more than one tag in bibtex");

  # just call
  $entry->get_title;

  Preferences->bibitex_html_converter('BibStyleConverter');
  $entry->regenerate_html( 1, $self->app->bst, $self->app->bibtexConverter );
  Preferences->bibitex_html_converter('Bibtex2HtmlConverter');
  $entry->regenerate_html( 1, $self->app->bst, $self->app->bibtexConverter );
  Preferences->bibitex_html_converter('BibStyleConverter');
  


  $limit_test_entries = $limit_test_entries -1;
}



ok(1);
done_testing();
