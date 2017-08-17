use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Test::Mojo;

my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
  '/do_login' => {Accept => '*/*'},
  form        => {user   => 'pub_admin', pass => 'asdf'}
);
my $self = $t_logged_in->app;

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);
use Path::Tiny;
use BibSpace::Functions::BackupFunctions;

subtest 'do_json_backup' => sub {

  my $dtoObject  = BibSpaceDTO->fromLayeredRepo($self->repo);
  my $jsonString = $dtoObject->toJSON;
  ok($jsonString, "Shall produce non-empty string");

  lives_ok { JSON->new->decode($jsonString) }
  "Json string should be valid - decodable";
  ok(JSON->new->decode($jsonString),
    "Json string should return non-undef object after decode");
  my $backup = do_json_backup($self->app, 'test');
  ok($backup, "Backup object should be defined");
  my $file_content = path($backup->get_path)->slurp_utf8;
  path($backup->get_path . ".expected")->spew($jsonString);

TODO: {
    local $TODO
      = "No way to compare this - this is unsorted at multiple levels";

    # one cannot compare these strings as the order of objects may differ
    # Maybe lenght should match at least?
    is(length($file_content), length($jsonString),
          "backup input and file content should have equal length. Run: wdiff "
        . $backup->get_path . " "
        . $backup->get_path
        . ".expected | colordiff");
  }
};

subtest 'restore_json_backup' => sub {
  my $dir        = $t_logged_in->app->get_backups_dir;
  my @json_paths = path($dir)->children(qr/\.json$/);

  # use Data::Dumper;
  # $Data::Dumper::MaxDepth = 2;
  # print Dumper \@json_paths;
SKIP: {
    skip "There is no json backup available to test restoring",
      if scalar @json_paths eq 0;

    my $some_backup = Backup->parse("" . $json_paths[0]);
    my $jsonString  = path($json_paths[0])->slurp_utf8;
    my $dto         = BibSpaceDTO->new();
    my $decodedDTO  = $dto->toLayeredRepo($jsonString, $t_logged_in->app->repo);
    ok($decodedDTO);    # this doesn't test much...
    ok(
      scalar $decodedDTO->get('Entry') > 0,
      "should restore at least one entry"
    );
  }
  ok(1);
};

done_testing();
