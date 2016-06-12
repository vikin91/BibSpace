use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self = $t_anyone->app;
my $dbh = $t_anyone->app->db;


use BibSpace::Model::MTag;

use BibSpace::Controller::Set;
use BibSpace::Controller::Core;
use Set::Scalar;
use Data::Dumper;

require_ok "BibSpace::Model::MTag";
use_ok "BibSpace::Model::MTag";

$dbh->do('DELETE FROM Tag;');

# my $en = MTag->new();
my @tags = MTag->static_all($dbh);
my @tags_type1 = MTag->static_all_type($dbh, 1);
my $num_tags = scalar(@tags);
my $num_tags_type1 = scalar(@tags_type1);
is($num_tags, 0, "Got 0 tags");
is($num_tags_type1, 0, "Got 0 tags");


$dbh->do('DELETE FROM Tag;');

{
	# test adding many tags
	my $num_tags_to_add = 30;
	foreach my $iter (( 1..$num_tags_to_add )){
	  my $tag_name = random_string(16); # this will never start with Z!
	  my $mt = MTag->new();
		$mt->{name} = $tag_name;
		$mt->{type} = 1;
		ok($mt->save($dbh) > 0, "Saving tag $tag_name");
	}

	my @tags = MTag->static_all($dbh);
	my @tags_type1 = MTag->static_all_type($dbh, 1);
	my $num_tags = scalar(@tags);
	my $num_tags_type1 = scalar(@tags_type1);

	is($num_tags, $num_tags_to_add, "Got $num_tags_to_add tags");
	is($num_tags_type1, $num_tags_to_add, "Got $num_tags_to_add tags of type 1");
	is($num_tags_type1, $num_tags, "All tags are type 1");
}

$dbh->do('DELETE FROM Tag;');

{
	my $t1 = MTag->new();
	$t1->{name} = 'Shy_writers';
	$t1->save($dbh);

	@tags = MTag->static_all($dbh);
	$num_tags = scalar(@tags);
	is($num_tags, 1, "Got 1 tags");

	my $some_team = shift( \@tags );
	is($some_team->delete($dbh), 1);

	@tags = MTag->static_all($dbh);
	$num_tags = scalar(@tags);
	is($num_tags, 0, "Got 0 tags");
	is($some_team->{id}, undef);
}




my $random1 = random_string(16);
my $random2 = random_string(16);

my $mt = MTag->new();
$mt->{name} = $random1;
$mt->{type} = 1;
$mt->{permalink} = $random2;
$mt->save($dbh);

my $t1 = MTag->static_get_by_name($dbh, $random1);
is($t1->{id}, $mt->{id}, "static_get_by_name");

my $t2 = MTag->static_get_by_permalink($dbh, $random2);
is($t2->{id}, $mt->{id}, "static_get_by_permalink");


$dbh->do('DELETE FROM Tag;');
# test adding many tags
my $num_tags_to_add = 30;
foreach my $iter (( 1..$num_tags_to_add )){
  my $tag_name = random_string(16); # this will never start with Z!
  my $mt = MTag->new();
	$mt->{name} = $tag_name;
	$mt->{type} = 1;
	ok($mt->save($dbh) > 0, "Saving tag $tag_name");
}

my @all = MTag->static_all($dbh);
my @all_with_z = MTag->static_get_all_w_letter($dbh, 1, 'z');
is(scalar @all, $num_tags_to_add, "Size of all $num_tags_to_add");
is(scalar @all_with_z, 0, "Size of all starting with z is 0");



### TODO: to test
# ####################################################################################
# sub static_get_all_of_type_for_paper {
#   my $dbh = shift;
#   my $eid = shift;
#   my $type = shift // 1;
# ####################################################################################
# sub static_get_unassigned_of_type_for_paper {
#   my $dbh = shift;
#   my $eid = shift;
#   my $type = shift // 1;


done_testing();
