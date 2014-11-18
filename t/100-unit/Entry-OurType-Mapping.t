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

sub compare_types {
  my @entries_bibtex_incollection = $repo->entries_filter(
    sub { $_->matches_our_type('bibtex-incollection', $repo) });
  my @entries_bibtex_inproceedings = $repo->entries_filter(
    sub { $_->matches_our_type('bibtex-inproceedings', $repo) });
  my @entries_our_incollection
    = $repo->entries_filter(sub { $_->matches_our_type('incollection', $repo) }
    );
  my @entries_our_inproceedings
    = $repo->entries_filter(sub { $_->matches_our_type('inproceedings', $repo) }
    );

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
}

subtest
  'Compare entries with types: inproceedings and incollection before restoring backup'
  => \&compare_types;

# Assumption: incollection = incollection + inproceedings
my $twoEntriesJSON = <<'EOS';
{
   "formatVersion" : "1",
   "dateTimeFormat" : "%Y-%m-%dT%T",
   "data" : {
      "Entry" : [
         {
            "html" : "",
            "_bibtex_type" : "incollection",
            "hidden" : 0,
            "bibtex_key" : "incollection2017",
            "month" : 10,
            "html_bib" : "",
            "bib" : "@incollection{incollection2017,\n  title = {{Online Workload Forecasting}},\n  editor = {James Bond},\n  author = {Henry Ford},\n  booktitle = {{Doing cool stuff in collection}},\n  publisher = {{Springer}},\n  address = {{San Francisco, Germany}},\n  year = {2017},\n  }",
            "old_mysql_id" : 584,
            "creation_time" : "2017-02-08T17:53:53",
            "abstract" : null,
            "year" : 2017,
            "entry_type" : "paper",
            "id" : 584,
            "need_html_regen" : 0,
            "title" : "{Online Workload Forecating}",
            "modified_time" : "2017-02-08T02:00:03"
         },
         {
            "html" : "",
            "_bibtex_type" : "inproceedings",
            "hidden" : 0,
            "bibtex_key" : "inproceedings2017",
            "month" : 10,
            "html_bib" : "",
            "bib" : "@inproceedings{inproceedings2017,\n  title = {{Online Workload Forecasting}},\n  editor = {James Bond},\n  author = {Henry Ford},\n  booktitle = {{Doing cool stuff in proceedings}},\n  publisher = {{Springer}},\n  address = {{San Francisco, Germany}},\n  year = {2017},\n  }",
            "old_mysql_id" : 585,
            "creation_time" : "2017-02-08T17:53:53",
            "abstract" : null,
            "year" : 2017,
            "entry_type" : "paper",
            "id" : 585,
            "need_html_regen" : 0,
            "title" : "{Online Workload Forecating}",
            "modified_time" : "2017-02-08T02:00:03"
         }
      ]
   }
}
EOS

subtest 'Restore Entries from JSON' => sub {
  use Try::Tiny;
  my $bibspaceDTOObject = BibSpaceDTO->fromLayeredRepo($self->repo);
  my $decodedJson;
  try {
    $decodedJson = JSON->new->decode($twoEntriesJSON);
  }
  finally {
    # Just mute errors
  };
  my $decodedDTO;

  # Creates DTO. Requires repo only for uid provider and preferences
  $decodedDTO = $bibspaceDTOObject->toLayeredRepo($twoEntriesJSON, $self->repo);
  isa_ok($decodedDTO, 'BibSpaceDTO',
    "Decoded class should be BibSpaceDTO, but is " . ref $decodedDTO);

  note("Testing collection holding objects of type Entry");
  my $value = $decodedDTO->data->{'Entry'};
  is(ref $value, 'ARRAY', "->data->{'Entry'} should be ARRAY");
  is(@{$value},  2,       " There should be 2 entries after restoring backup");
};

subtest
  'Repeat subtest: Compare entries with types: inproceedings and incollection before restoring backup'
  => \&compare_types;

done_testing();
