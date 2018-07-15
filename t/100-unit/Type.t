use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Exception;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self     = $t_anyone->app;

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

my $repo      = $self->app->repo;
my @all_types = $repo->types_all;

my $limit_num_tests = 20;

note "============ Testing " . scalar(@all_types) . " Types ============";

foreach my $type (@all_types) {
  last if $limit_num_tests < 0;

  note "============ Testing Type ID " . $type->our_type . ".";

  ok($type->equals($type), "equals");

  if ($type->bibtexTypes_count == 1) {

    is($type->num_bibtex_types, 1, "num_bibtex_types is 1");
    ok($type->get_first_bibtex_type, "get_first_bibtex_type is defined");

    if ($type->get_first_bibtex_type eq $type->our_type) {
      ok(!$type->can_be_deleted,
            "allowed deletion of custom 1:1 mapping \n\t"
          . "\t - should not allow to delete");
    }
    else {
      ok($type->can_be_deleted,
            "disalowed deletion of custom 1:1 mapping \n\t"
          . "\t - should allow to delete");
    }

  }
  elsif ($type->bibtexTypes_count > 1) {

    ok($type->num_bibtex_types > 0,  "num_bibtex_types");
    ok($type->get_first_bibtex_type, "get_first_bibtex_type");
    ok(!$type->can_be_deleted,
          "allowed deletion of 1:N mapping \n\t"
        . "\t - should not allow to delete");
  }
  else {
    is($type->num_bibtex_types, 0, "num_bibtex_types");
    ok(!$type->get_first_bibtex_type, "get_first_bibtex_type");
    ok($type->can_be_deleted,         "can_be_deleted - zero bibtex types");
  }

  $limit_num_tests--;
}

ok(1);
done_testing();
