package TestManager;

use Try::Tiny;

use BibSpace;
use BibSpace::Model::Backup;
use BibSpace::Functions::BackupFunctions qw(restore_storable_backup);
use BibSpace::Functions::FDB; # TODO: purge DB etc.


use Moose;

sub apply_fixture {
	my $self = shift;
	my $app = shift;
	## THIS SHOULD BE REPEATED FOR EACH TEST!
	my $fixture_name = "bibspace_fixture.dat";
	my $fixture_dir = "./fixture/";
	my $fixture = Backup->new(dir => $fixture_dir, filename =>$fixture_name);
	restore_storable_backup($fixture, $app);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;