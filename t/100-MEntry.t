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

ok(defined $en, "Mentry initialized correctly");
ok($num_entries > 0, "Got more than 0 entries");


#### START fix months


#### single entry

my $en2 = MEntry->new();
$en2->{bib} = '@mastersthesis{ma_199A,
  address = {World},
  author = {James Bond},
  month = {August},
  school = {University of Bond},
  title = {{Selected aspects of some methods}},
  year = {1999},
}';

is($en2->bibtex_has('year'), 1, "MEntry has field year");
isnt($en2->bibtex_has('journal'), 1, "MEntry hasn't field journal");
is($en2->get_bibtex_field_value('year'), 1999, "MEntry year has value 1999");
is($en2->get_bibtex_field_value('year'), '1999', "MEntry year has value 1999");
isnt($en2->get_bibtex_field_value('year'), 2000, "MEntry year hasn't value 2000");
isnt($en2->get_bibtex_field_value('year'), '2000', "MEntry year hasn't value 2000");


isnt($en2->{month}, 8 , "Month field empty");

$en2->fix_month();

is($en2->{month}, 8, "Month field OK");
is($en2->{sort_month}, 8, "Sort month field OK");

is($en2->delete($dbh), '0E0', "Deleting not-existing entry= cannot delete");

is($en2->update($dbh), -1, "updating not existing entry");
ok($en2->store($dbh) > 1, "adding new entry");
is($en2->update($dbh), 1, "updating existing entry");
is($en2->delete($dbh), 1, "Deleting entry");




done_testing();
