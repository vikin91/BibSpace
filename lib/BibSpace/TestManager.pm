package TestManager;

use Try::Tiny;

use BibSpace;
use BibSpace::Model::Backup;
use BibSpace::Functions::BackupFunctions qw(restore_json_backup);
use BibSpace::Functions::FDB;    # TODO: purge DB etc.

use Moose;

sub apply_fixture {
  my $self = shift;
  my $app  = shift;
  ## THIS SHOULD BE REPEATED FOR EACH TEST!
  my $fixture_file = $app->home->rel_file('fixture/bibspace_fixture.json');
  my $fixture_name = '' . $fixture_file->basename;
  my $fixture_dir  = '' . $fixture_file->dirname;
  my $fixture = Backup->new(dir => $fixture_dir, filename => $fixture_name);
  restore_json_backup($fixture, $app);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
