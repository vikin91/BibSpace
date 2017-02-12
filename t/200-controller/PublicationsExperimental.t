use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use BibSpace;
use BibSpace::Functions::Core;


my $admin_user = Test::Mojo->new('BibSpace');
$admin_user->post_ok(
    '/do_login' => { Accept => '*/*' },
    form        => { user   => 'pub_admin', pass => 'asdf' }
);

use BibSpace::TestManager;
TestManager->apply_fixture($admin_user->app);

my $self = $admin_user->app;
my $app_config = $admin_user->app->config;
$admin_user->ua->max_redirects(3);





my $page = $self->url_for('add_many_publications');
  $admin_user->get_ok($page, "Get for page $page")
      ->status_isnt(404, "Checking: 404 $page")
      ->status_isnt(500, "Checking: 500 $page")->content_like(qr/You operate on an unsaved entry/i);



my $multi_bib1 = '
@article{key-xxx1-2017,
      author = {Johny Example},
      title = {{Selected aspects of some methods VH0P3E0G}},
      journal = {Journal of this and that},
      publisher = {Printer-at-home publishing},
      year = {2017},
      month = {February},
      day = {1--31},
  }

@article{key-xxx2-2017,
      author = {Johny Example},
      title = {{Selected aspects of some methods NGRDM1II}},
      journal = {Journal of other things},
      publisher = {Copy-machine publishing house},
      year = {2017},
      month = {February},
      day = {1--31},
}';

my $multi_bib2 = '
@article{key-xxx3-2017,
      author = {Johny Example},
      title = {{Selected aspects of some methods GFYUY77J}},
      journal = {Journal of this and that},
      publisher = {Printer-at-home publishing},
      year = {2017},
      month = {February},
      day = {1--31},
  }

@article{key-xxx4-2017,
      author = {Johny Example},
      title = {{Selected aspects of some methods NBGG54BB}},
      journal = {Journal of other things},
      publisher = {Copy-machine publishing house},
      year = {2017},
      month = {February},
      day = {1--31},
}';

$admin_user->post_ok(
    $self->url_for('add_many_publications_post') => form => {new_bib => $multi_bib1, preview => 1 }
);
$admin_user->post_ok(
    $self->url_for('add_many_publications_post') => form => {new_bib => $multi_bib2, save => 1 }
);

ok(1);

done_testing();
