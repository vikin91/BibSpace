package BibSpace::Functions::BackupFunctions;

use BibSpace::Functions::MySqlBackupFunctions;
use BibSpace::Model::Backup;
use BibSpace::Functions::Core;
use BibSpace::Functions::FDB;

use JSON -convert_blessed_universally;
use BibSpace::Model::SerializableBase::BibSpaceDTO;
use Storable;

use Data::Dumper;
use utf8;
use Path::Tiny;
use DateTime;
use Try::Tiny;
use v5.16;    #because of ~~

use strict;
use warnings;

use Exporter;
our @ISA = qw( Exporter );

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw(
  find_backup
  read_backups
  do_storable_backup
  do_json_backup
  do_mysql_backup
  restore_json_backup
  restore_storable_backup
  delete_old_backups
);
## Trivial DAO FIND
## my $filename = "backup_$uuid" . "_$name" . "_$type" . "_$now" . $ext;

sub find_backup {
  my $uuid = shift;
  my $dir  = shift;

  my @backup_files
    = Path::Tiny->new($dir)->children(qr/^backup_$uuid.*\.(dat|sql|json)$/);
  return if scalar(@backup_files) == 0;

  my $file   = shift @backup_files;
  my $backup = Backup->parse($file->basename);
  $backup->dir($dir);
  return $backup;
}

## Trivial DAO ALL
sub read_backups {
  my $dir = shift;

  my @backup_files
    = Path::Tiny->new($dir)->children(qr/^backup_.*\.(dat|sql|json)$/);
  my @backups;
  foreach my $file (@backup_files) {
    my $backup = Backup->parse($file->basename);
    $backup->dir($dir);
    push @backups, $backup;
  }
  return @backups;
}

sub do_json_backup {
  my $app = shift;
  my $name = shift // 'normal';

  my $backup_dir = Path::Tiny->new($app->get_backups_dir)->relative;
  $backup_dir =~ s!/*$!/!;

  my $backup = Backup->create($name, "json");
  $backup->dir("" . $backup_dir);
  my $path = "" . $backup->get_path;

  my $dtoObject  = BibSpaceDTO->fromLayeredRepo($app->repo);
  my $jsonString = $dtoObject->toJSON;
  path($backup->get_path)->spew($jsonString);

  return $backup;
}

sub do_storable_backup {
  my $app = shift;
  my $name = shift // 'normal';

  my $backup_dir = Path::Tiny->new($app->get_backups_dir)->relative;
  $backup_dir =~ s!/*$!/!;    # hy do I need to add this???

  my $backup = Backup->create($name, "storable");
  $backup->dir("" . $backup_dir);

  my $layer = $app->repo->lr->get_read_layer;
  my $path  = "" . $backup->get_path;

  $Storable::forgive_me = "do store regexp please";
  Storable::store $layer, $path;

  return $backup;
}

sub do_mysql_backup {
  my $app = shift;
  my $name = shift // 'normal';

  my $backup_dir = Path::Tiny->new($app->get_backups_dir)->relative;
  $backup_dir =~ s!/*$!/!;

  my $backup = Backup->create($name, "mysql");
  $backup->dir("" . $backup_dir);
  dump_mysql_to_file($backup->get_path, $app->config);

  return $backup;
}

sub restore_json_backup {
  my $backup = shift;
  my $app    = shift;

  # 1) get filename
  # 2) open file
  # 3) read json contents
  # 4) Create DTO containg rich objects compatible with current repo
  # 5) Copy objects into the repo
  my $jsonString = '{}';
  my $file       = path($backup->get_path);
  if (not $file->exists or not $file->is_file) {
    $app->logger->warn("Cannot restore JSON backup from file "
        . $file
        . " - file does not exist.");
    return;
  }
  $jsonString = $file->slurp_utf8;

  my $success;
  my $dto = BibSpaceDTO->new();
  my $decodedDTO;
  try {
    $decodedDTO = $dto->toLayeredRepo($jsonString, $app->repo);

    # use Data::Dumper;
    # $Data::Dumper::MaxDepth = 2;
    # print Dumper $decodedDTO;
    $success = 1;
  }
  catch {
    $app->logger->error("Exception during json restore: $_");
    $success = undef;
  };

  # First Models, then Relations
  for my $type (@{$app->repo->entities}, @{$app->repo->relations}) {
    my $arrayRef = $decodedDTO->data->{$type};
    for my $object (@$arrayRef) {
      $app->repo->lr->save($type, $object);
    }
  }
  return $success;
}

sub restore_storable_backup {
  my $backup = shift;
  my $app    = shift;

  my $layer = retrieve($backup->get_path);

  say "restore_storable_backup has retrieved:" . $layer->get_summary_table;

  ## this writes to all layers!!

  my @layers = $app->repo->lr->get_all_layers;
  foreach (@layers) { $_->reset_data }
  $app->repo->lr->reset_uid_providers;

# say "Smart layer after reset:" . $app->repo->lr->get_layer('smart')->get_summary_table;

  my $layer_to_replace = $app->repo->lr->get_read_layer;
  $app->repo->lr->replace_layer($layer_to_replace->name, $layer);

  foreach my $layer (@layers) {
    next if $layer->name eq $layer_to_replace->name;

    $app->repo->lr->copy_data(
      {from => $layer_to_replace->name, to => $layer->name});
  }

# say "Smart layer after replace:" . $app->repo->lr->get_layer('smart')->get_summary_table;

  say "restore_storable_backup DONE. Smart layer after copy_data:"
    . $app->repo->lr->get_layer('smart')->get_summary_table;
  say "restore_storable_backup DONE. All layer after copy_data:"
    . $app->repo->lr->get_summary_table;
}

sub delete_old_backups {
  my $app          = shift;
  my $age_treshold = shift
    // $app->config->{backup_age_in_days_to_delete_automatically};

  my $num_deleted = 0;

  my @backups_arr
    = sort { $b->date cmp $a->date } read_backups($app->get_backups_dir);
  foreach my $backup (@backups_arr) {
    my $age = $backup->get_age->days;
    if ($age >= $age_treshold) {
      ++$num_deleted;
      unlink $backup->get_path;
    }
  }
  return $num_deleted;
}

1;
