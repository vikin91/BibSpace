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

# TODO: The test should check state after restoring json backup

my @entries_bibtex_incollection = $repo->entries_filter(
  sub { $_->matches_our_type('bibtex-incollection', $repo) });
my @entries_bibtex_inproceedings = $repo->entries_filter(
  sub { $_->matches_our_type('bibtex-inproceedings', $repo) });
my @entries_our_incollection
  = $repo->entries_filter(sub { $_->matches_our_type('incollection', $repo) });
my @entries_our_inproceedings
  = $repo->entries_filter(sub { $_->matches_our_type('inproceedings', $repo) });

my $e_bib_inc = scalar @entries_bibtex_incollection;
my $e_bib_inp = scalar @entries_bibtex_inproceedings;
my $e_our_inc = scalar @entries_our_incollection;
my $e_our_inp = scalar @entries_our_inproceedings;

ok(
  $e_bib_inp <= $e_our_inp,
  "There should be more or equal number of entries of type our inproceedings than bibtex inproceedings"
);
ok(
  $e_bib_inc == $e_our_inc,
  "There should be equal number of entries of type our incollection and bibtex incollection"
);
is(
  $e_our_inp,
  $e_bib_inc + $e_bib_inp,
  "Our Inproceedings = bibtex inproceedings + bibtex incollection"
);

ok(1);
done_testing();
