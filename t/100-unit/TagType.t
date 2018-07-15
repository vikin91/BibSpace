use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Exception;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self     = $t_anyone->app;
use BibSpace::TestManager;
TestManager->apply_fixture($self->app);
my $repo = $self->app->repo;

my $tt1
  = $self->app->entityFactory->new_TagType(name => 'tt1', comment => "abc");
my $tt2 = $self->app->entityFactory->new_TagType(name => 'tt2');
my $tt3
  = $self->app->entityFactory->new_TagType(name => 'tt1', comment => 'xyz');

ok($tt1->equals($tt3));
ok(!$tt1->equals($tt2));
ok(!$tt2->equals($tt3));

ok(1);
done_testing();
