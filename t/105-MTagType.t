use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Exception;


# use BibSpace::Controller::Core;
# use BibSpace::Functions::FDB;
# use BibSpace::Controller::BackupFunctions;
# use Data::Dumper;

# my $t_logged_in = Test::Mojo->new('BibSpace');
# $t_logged_in->post_ok(
#     '/do_login' => { Accept => '*/*' },
#     form        => { user   => 'pub_admin', pass => 'asdf' }
# );
# my $self       = $t_logged_in->app;
# my $dbh        = $t_logged_in->app->db;
# my $app_config = $t_logged_in->app->config;

# my $status = 0;
# $status
#     = do_restore_backup_from_file( $dbh, "./fixture/db.sql", $app_config );
# is( $status, 1, "preparing DB for test" );



# subtest 'MTagType: basics 1' => sub {
# 	$dbh->do('DELETE FROM Tag;');
# 	$dbh->do('DELETE FROM TagType;');

# 	$storage->tagtypes_clear;
# 	$storage->tags_clear;
	
# 	my @tts = $storage->tagtypes_all;
# 	my @tts1 = $storage->tagtypes_filter( sub{$_->type == 1} );
	
# 	is(scalar(@tts), 0, "Got 0 tag types");
# 	is(scalar(@tts1), 0, "Got 0 tag types");

# 	my $tt = MTagType->new( name=> 'test1', comment => 'test1comment');
# 	$storage->add($tt);
# 	isnt( $tt->save($dbh), undef, "saving ok");

# 	is(scalar($storage->tagtypes_all), 1, "Got 1 tag types");

# 	$storage->add( MTagType->new( name=> 'test2', comment => 'test2comment') );


# 	is(scalar($storage->tagtypes_all), 2, "Got 2 tag types");

# 	my $a_tt = $storage->tagtypes_find( sub{ ($_->name cmp 'test1')==0} );
# 	# MTagType->static_get_by_name($dbh, 'test1');
# 	my $b_tt = $storage->tagtypes_find( sub{ ($_->name cmp 'test2')==0} );
# 	# MTagType->static_get_by_name($dbh, 'test2');
# 	is( $a_tt->equals($tt), 1, "static_get_by_name and equals ok");
# 	is( $a_tt->equals($b_tt), 0, "equals ok");

# 	$tt->{comment} = "new_comment";
# 	isnt( $tt->save($dbh), undef, "updating ok");
# 	$storage->add($tt);

# 	my $id = $tt->{id};
# 	my $tt2 = $storage->tagtypes_find( sub{$_->id == $id} );
# 	isnt( $tt2, undef, "fetching ok");
# 	is( $tt2->{comment}, "new_comment", "update successful");

# 	my $num_tts = scalar $storage->tagtypes_all;
# 	ok( $storage->delete($tt2), 'deleting from storage tt2 ok');
# 	is( $tt2->delete($dbh), 1, "deleting from DB ok");

# 	is( scalar $storage->tagtypes_all, $num_tts-1, "there is one less after deleting");

# 	my $fake;
# 	dies_ok { $fake = MTagType->new( id=> undef, name=> 'test1', comment => 'test1comment') } 'does not allow to create tagtype with undef as id';
# 	$fake = MTagType->new( name=> 'test1', comment => 'test1comment');

# 	is( $fake->update($dbh), undef, "fake update ok");
# 	isnt( $fake->save($dbh), undef, "fake save ok");
# 	ok( $storage->add($fake), 'adding fake to storage  ok');

# 	# cleanup 
# 	$dbh->do('DELETE FROM Tag;');
# 	$dbh->do('DELETE FROM TagType;');
# 	$storage->tagtypes_clear;
# 	$storage->tags_clear;
# 	populate_tables($dbh);
# 	# $storage->load($dbh);

# };



ok(1);
done_testing();
