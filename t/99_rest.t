use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Controller::Core;

`rm test-backups/*sql`;


# # ############################ PREPARATION
# my $t_anyone = Test::Mojo->new('BibSpace');
# my $t_logged_in = Test::Mojo->new('BibSpace');
# $t_logged_in->post_ok(
#     '/do_login' => { Accept => '*/*' },
#     form        => { user   => 'pub_admin', pass => 'asdf' }
# );

# my $dbh = $t_logged_in->app->db;

ok(1);
done_testing();


