use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Controller::Core;

my $t_anyone    = Test::Mojo->new('BibSpace');
my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);
my $self = $t_logged_in->app;

# this is crucial for the test to pass as there are redirects here!
$t_logged_in->ua->max_redirects(10);
$t_logged_in->ua->inactivity_timeout(3600);
my $dbh = $t_logged_in->app->db;

####################################################################
TODO: {
    local $TODO = "Testing gets for single publications";

    my @entries     = MEntry->static_all($dbh);
    my $size = $#entries;
    my $limit = 50;
    my $num_done = 0;

    while($num_done < $limit){
        my $rand = int(rand($size));
        my $e = $entries[$rand];
        my $id = $e->{id};

        my @pages = (
            $self->url_for('/publications/get/:id', id=>$id),
            $self->url_for('edit_publication', id=>$id),
            $self->url_for('regenerate_publication', id=>$id),
            $self->url_for('/publications/add_pdf/:id', id=>$id),
            $self->url_for('manage_tags', id=>$id),
            $self->url_for('manage_exceptions', id=>$id),
            $self->url_for('/publications/show_authors/:id', id=>$id),
            $self->url_for('metalist_entry', id=>$id),
        );
        for my $page (@pages){
            note "============ Testing page $page for paper id $id ============";
            $t_logged_in->get_ok($page)->status_isnt(404, "Checking: 404 $page")->status_isnt(500, "Checking: 500 $page");
        }
        $num_done = $num_done + 1;
    }
};



done_testing();


