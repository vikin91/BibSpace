use Mojo::Base -strict;
use Test::More;
use Test::Mojo;



my $t_anyone = Test::Mojo->new('BibSpace');
my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);
my $self = $t_logged_in->app;

my $dbh = $t_logged_in->app->db;
my $storage = StorageBase::get();


use BibSpace::Model::M::MEntry;
use BibSpace::Functions::FPublications;

$dbh->do('DELETE FROM Entry;');
$storage->entries_clear;

# my $en = MEntry->new();
my @entries = $storage->entries_all;
my $num_entries = scalar(@entries);
is($num_entries, 0, "Got 0 entries");

#### adding some fixtures. TODO: this needs to be done automatically at the beginning of the test suite
my $en3 = MEntry->new();
$en3->{bib} = '@mastersthesis{zzzzz1,
  address = {World},
  author = {James Bond},
  month = {August},
  school = {University of Bond},
  title = {{Selected aspects of some methods}},
  year = {1999},
}';
$en3->populate_from_bib($dbh);
$en3->save($dbh);
$storage->add($en3);

my $en4 = MEntry->new();
$en4->{bib} = '@mastersthesis{zzzzz2,
  address = {World},
  author = {James Bond},
  month = {March},
  school = {University of Bond},
  title = {{Selected aspects of some methods}},
  year = {1999},
}';
$en4->populate_from_bib($dbh);
$en4->save($dbh);
$storage->add($en4);



@entries = $storage->entries_all;
$num_entries = scalar(@entries);

my $en = MEntry->new();
ok(defined $en, "MEntry initialized correctly");
ok($num_entries > 0, "Got more than 0 entries");


#### START fix months


#### single entry

$dbh->do('DELETE FROM Entry;');
$storage->entries_clear;

### adding some entries for the next test
$en3 = MEntry->new();
$en3->{bib} = '@mastersthesis{xxx1,
  address = {World},
  author = {James Bond},
  month = {August},
  school = {University of Bond},
  title = {{Selected aspects of some methods}},
  year = {1999},
}';
$en3->populate_from_bib($dbh);
$en3->save($dbh);
$storage->add($en3);

$en4 = MEntry->new();
$en4->{bib} = '@mastersthesis{xxx2,
  address = {World},
  author = {James Bond},
  month = {March},
  school = {University of Bond},
  title = {{Selected aspects of some methods}},
  year = {1999},
}';
$en4->populate_from_bib($dbh);
$en4->save($dbh);
$storage->add($en4);
@entries = $storage->entries_all;
$num_entries = scalar(@entries);


#### all entries
my ($numChecks, $numFixes) = Ffix_months($dbh, @entries);
is($numChecks, $num_entries, "fix_months processed all entries");
ok(($numFixes > 0), "fix_months fixed some entries");



ok(Fclean_ugly_bibtex_fields_for_all_entries() >= 0, "Fclean_ugly_bibtex_fields_for_all_entries");

my $num_authors_created = Fhandle_author_uids_change_for_all_entries($dbh, 0);
ok( $num_authors_created  >= 0, "Fhandle_author_uids_change_for_all_entries create 0");

$num_authors_created = Fhandle_author_uids_change_for_all_entries($dbh, 1);
ok( $num_authors_created  >= 0, "Fhandle_author_uids_change_for_all_entries create 1");



### this will fail if the user gives a month name with a typo = bad test
# for my $entry (@entries){	
# 	if($entry->bibtex_has('month')){
# 		my $month_bib = $entry->get_bibtex_field_value('month');
# 		if($month_bib ne ''){
# 			my $month_digit = $entry->{month};	
# 				if($month_digit == 0){
# 					say $entry->{bib};
# 				}
# 				ok(($month_digit > 0 and $month_digit < 13), "Month field of entry id ".$entry->{id}." is ".$month_digit);
# 		}
# 	}
# }
#### END fix months


done_testing();
