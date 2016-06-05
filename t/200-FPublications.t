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


  # say "get 1:   ".$en->get($self->app->db, 1);
  # my @entries = $en->all($self->app->db);
  # for my $en (@entries){
  #   say Dumper $en;
  #   say $en->{id};
  #   say $en->{bibtex_key};
  # }

use BibSpace::Model::MEntry;
use BibSpace::Functions::FPublications;

my $en = MEntry->new();
my @entries = $en->all($dbh);
my $num_entries = scalar(@entries);

ok(defined $en, "MEntry initialized correctly");
ok($num_entries > 0, "Got more than 0 entries");


#### START fix months


#### single entry

my $en2 = MEntry->new();
$en2->{bib} = '@mastersthesis{ma-199A,
  address = {World},
  author = {James Bond},
  month = {August},
  school = {University of Bond},
  title = {{Selected aspects of some methods}},
  year = {1999},
}';

isnt($en2->{month}, 8 , "Month field empty");

$en2->fix_month();

is($en2->{month}, 8, "Month field OK");
is($en2->{sort_month}, 8, "Sort month field OK");

$en2->{bib} = '@misc{test, month = {January}}';
$en2->fix_month();
is($en2->{month}, 1, "Month field OK");
$en2->{bib} = '@misc{test, month = {February}}';
$en2->fix_month();
is($en2->{month}, 2, "Month field OK");
$en2->{bib} = '@misc{test, month = {March}}';
$en2->fix_month();
is($en2->{month}, 3, "Month field OK");
$en2->{bib} = '@misc{test, month = {April}}';
$en2->fix_month();
is($en2->{month}, 4, "Month field OK");

$en2->{bib} = '@misc{test, month = {May}}';
$en2->fix_month();
is($en2->{month}, 5, "Month field OK");

$en2->{bib} = '@misc{test, month = {June}}';
$en2->fix_month();
is($en2->{month}, 6, "Month field OK");

$en2->{bib} = '@misc{test, month = {July}}';
$en2->fix_month();
is($en2->{month}, 7, "Month field OK");

$en2->{bib} = '@misc{test, month = {August}}';
$en2->fix_month();
is($en2->{month}, 8, "Month field OK");

$en2->{bib} = '@misc{test, month = {September}}';
$en2->fix_month();
is($en2->{month}, 9, "Month field OK");

$en2->{bib} = '@misc{test, month = {October}}';
$en2->fix_month();
is($en2->{month}, 10, "Month field OK");

$en2->{bib} = '@misc{test, month = {November}}';
$en2->fix_month();
is($en2->{month}, 11, "Month field OK");

$en2->{bib} = '@misc{test, month = {December}}';
$en2->fix_month();
is($en2->{month}, 12, "Month field OK");


$dbh->do('DELETE FROM Tag;');
# testing tags
$en2->{bib} = '@misc{test, tags = {aa;bb}}';
is($en2->process_tags($dbh), 2, "Adding 2 tags");
$en2->{bib} = '@misc{test, tags = {}}';
is($en2->process_tags($dbh), 0, "Adding 0 tags");
$en2->{bib} = '@misc{test, tags = {aa;bb;cc}}';
is($en2->process_tags($dbh), 1, "Adding 1 extra tag");


#### all entries
my ($processed_entries, $fixed_entries) = Ffix_months($dbh);
is($processed_entries, $num_entries, "fix_months processed all entries");
ok(($fixed_entries > 0), "fix_months fixed some entries");
ok(($fixed_entries <= $num_entries), "fix_months fixed almost all entries - this is badly designed test");

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
