use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);
my $self = $t_logged_in->app;
my $dbh = $t_logged_in->app->db;


use BibSpace::Functions::FPublications;

$t_logged_in->app->repo->entries_delete($t_logged_in->app->repo->entries_all);

# my $en = MEntry->new();
my @entries = $t_logged_in->app->repo->entries_all;
my $num_entries = scalar(@entries);
is($num_entries, 0, "Got 0 entries");

#### adding some fixtures. TODO: this needs to be done automatically at the beginning of the test suite
my $idProvider = $t_logged_in->app->repo->entries_idProvider;
my $en3 = Entry->new(idProvider => $idProvider);
$en3->{bib} = '@mastersthesis{zzzzz1,
  address = {World},
  author = {James Bond},
  month = {August},
  school = {University of Bond},
  title = {{Selected aspects of some methods}},
  year = {1999},
}';
$en3->populate_from_bib($dbh);
$t_logged_in->app->repo->entries_save($en3);

my $en4 = Entry->new(idProvider => $idProvider);
$en4->{bib} = '@mastersthesis{zzzzz2,
  address = {World},
  author = {James Bond},
  month = {March},
  school = {University of Bond},
  title = {{Selected aspects of some methods}},
  year = {1999},
}';
$en4->populate_from_bib($dbh);
$t_logged_in->app->repo->entries_save($en4);



@entries = $t_logged_in->app->repo->entries_all;
$num_entries = scalar(@entries);

my $en = Entry->new(idProvider => $idProvider);
ok(defined $en, "MEntry initialized correctly");
ok($num_entries > 0, "Got more than 0 entries");


#### START fix months


#### single entry

$t_logged_in->app->repo->entries_delete($t_logged_in->app->repo->entries_all);

### adding some entries for the next test
$en3 = Entry->new(idProvider => $idProvider);
$en3->{bib} = '@mastersthesis{xxx1,
  address = {World},
  author = {James Bond},
  month = {August},
  school = {University of Bond},
  title = {{Selected aspects of some methods}},
  year = {1999},
}';
$en3->populate_from_bib($dbh);
$t_logged_in->app->repo->entries_save($en3);

$en4 = Entry->new(idProvider => $idProvider);
$en4->{bib} = '@mastersthesis{xxx2,
  address = {World},
  author = {James Bond},
  month = {March},
  school = {University of Bond},
  title = {{Selected aspects of some methods}},
  year = {1999},
}';
$en4->populate_from_bib($dbh);
$t_logged_in->app->repo->entries_save($en4);
@entries = $t_logged_in->app->repo->entries_all;
$num_entries = scalar(@entries);








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
