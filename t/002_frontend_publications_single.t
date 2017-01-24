use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use BibSpace;
use BibSpace::Controller::Core;

my $num_publications_limit = 10;

# plan tests => 1 + 9 * 3 * $num_publications_limit;

my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok( '/do_login' => { Accept => '*/*' }, form => { user => 'pub_admin', pass => 'asdf' } );
my $self = $t_logged_in->app;

# this is crucial for the test to pass as there are redirects here!
$t_logged_in->ua->max_redirects(10);
$t_logged_in->ua->inactivity_timeout(3600);
my $dbh = $t_logged_in->app->db;

####################################################################
subtest 'Checking pages for single publication' => sub {
  # local $TODO = "Testing gets for single publications";

  my @entries  = $t_logged_in->app->repo->getEntriesRepository->all;
  my $size     = $#entries;
  my $num_done = 0;


  while ( $num_done < $num_publications_limit ) {
    my $rand = int( rand($size) );
    my $e    = $entries[$rand];
    my $id   = $e->id;

    my @pages = (
      $self->url_for( 'get_single_publication',      id => $id ),
      $self->url_for( 'get_single_publication_read', id => $id ),
      $self->url_for( 'edit_publication',            id => $id ),
      $self->url_for( 'regenerate_publication',      id => $id ),
      $self->url_for( 'manage_attachments',          id => $id ),
      $self->url_for( 'manage_tags',                 id => $id ),
      $self->url_for( 'manage_exceptions',           id => $id ),
      $self->url_for( 'show_authors_of_entry',       id => $id ),
      $self->url_for( 'metalist_entry',              id => $id ),
    );
    for my $page (@pages) {
      note "============ Testing page $page for paper id $id ============";
      $t_logged_in->get_ok( $page, "Checking: OK $page" )->status_isnt( 404, "Checking: 404 $page" )
        ->status_isnt( 500, "Checking: 500 $page" );
    }
    ++$num_done;
  }
};


done_testing();


