use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self = $t_anyone->app;
my $dbh = $t_anyone->app->db;


use BibSpace::Model::MTag;
use BibSpace::Model::MTagType;

use BibSpace::Controller::Core;
use BibSpace::Functions::FDB;
use Set::Scalar;
use Data::Dumper;


require_ok "BibSpace::Model::MTagType";
use_ok "BibSpace::Model::MTagType";


subtest 'MTagType: basics 1: static_all' => sub {
	$dbh->do('DELETE FROM Tag;');
	$dbh->do('DELETE FROM TagType;');
	
	my @tts = MTagType->static_all($dbh);
	my @tts1 = MTagType->static_get($dbh, 1);
	
	is(scalar(@tts), 0, "Got 0 tag types");
	is(scalar(@tts1), 1, "Got 1 tag types");
	is($tts1[0], undef, "Got 1 tag types");

	my $tt = MTagType->new( name=> 'test1', comment => 'test1comment');
	isnt( $tt->save($dbh), undef, "saving ok");

	is(scalar(MTagType->static_all($dbh)), 1, "Got 1 tag types");

	MTagType->new( name=> 'test2', comment => 'test2comment')->save($dbh);

	is(scalar(MTagType->static_all($dbh)), 2, "Got 2 tag types");

	my $a_tt = MTagType->static_get_by_name($dbh, 'test1');
	my $b_tt = MTagType->static_get_by_name($dbh, 'test2');
	is( $a_tt->equals($tt), 1, "static_get_by_name and equals ok");
	is( $a_tt->equals($b_tt), 0, "equals ok");

	$tt->{comment} = "new_comment";
	isnt( $tt->save($dbh), undef, "updating ok");
	my $id = $tt->{id};
	my $tt2 = MTagType->static_get($dbh, $id);
	isnt( $tt2, undef, "fetching ok");
	is( $tt2->{comment}, "new_comment", "update successful");

	my $num_tts = scalar MTagType->static_all($dbh);
	is( $tt2->delete($dbh), 1, "deleting ok");
	is( scalar MTagType->static_all($dbh), $num_tts-1, "deleting ok");

	is( MTagType->new( id=> undef, name=> 'test1', comment => 'test1comment')->update($dbh), undef, "fake update ok");
	isnt( MTagType->new( id=> undef, name=> 'test1', comment => 'test1comment')->save($dbh), undef, "fake save ok");

	# cleanup 
	$dbh->do('DELETE FROM Tag;');
	$dbh->do('DELETE FROM TagType;');
	populate_tables($dbh);

};




done_testing();
