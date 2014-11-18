package BibSpace::Functions::BackupFunctions;

use BibSpace::Functions::MySqlBackupFunctions;
use BibSpace::Model::Backup;
use BibSpace::Functions::Core;
use BibSpace::Functions::FDB;

use JSON -convert_blessed_universally;
use BibSpace::Model::SerializableBase::BibSpaceDTO;

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
  do_json_backup
  do_mysql_backup
  restore_json_backup
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
  my $app  = shift;
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

sub do_mysql_backup {
  my $app  = shift;
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
    $success    = 1;
  }
  catch {
    $app->logger->error("Exception during JSON restore: $_");
    $success = undef;
  };

  # First Models, then Relations
  if (defined $success and $success == 1) {
    my @layers = $app->repo->lr->get_all_layers;
    foreach (@layers) { $_->reset_data }

    for my $type (@{$app->repo->entities}, @{$app->repo->relations}) {
      my $arrayRef = $decodedDTO->data->{$type};

     # Authors reference each other, so the order of restoring is important
     # First masters, because they always reference themselves, and then minions
      my @waitingLine;
      for my $object (@$arrayRef) {
        try {
          if ($type eq "Author" && $object->is_minion) {
            $app->logger->debug("Putting $object->{uid} to waiting line\n");
            push @waitingLine, $object;
          }
          else {
            $app->repo->lr->save($type, $object);
          }
        }
        catch {
          $app->logger->warn(
            "Skipped restoring object of type '$type' from JSON backup. Error: $_"
          );
        };
      }
      for my $object (@waitingLine) {
        try {
          $app->logger->debug("Adding $object->{uid} from waiting line\n");
          $app->repo->lr->save($type, $object);
        }
        catch {
          $app->logger->warn(
            "Could not restore minion Author from waitingLine. Error: $_");
        };
      }
    }
  }
  return $success;
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
