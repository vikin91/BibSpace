package BibSpace::Controller::Backup;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;

# use File::Slurp;

use v5.16;
use Try::Tiny;
use strict;
use warnings;

use File::Copy qw(copy);
use List::MoreUtils qw(any uniq);
use List::Util qw(first);

use BibSpace::Functions::Core;
use BibSpace::Functions::MySqlBackupFunctions;
use BibSpace::Functions::BackupFunctions;
use BibSpace::Model::Backup;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;

sub index {
  my $self = shift;
  my $dbh  = $self->app->db;

  my $backup_dir = $self->app->get_backups_dir;
  my $dir_size   = get_dir_size($backup_dir);
  $dir_size = $dir_size >> 20;

  my @backups_arr = sort { $b->date cmp $a->date } read_backups($backup_dir);

  foreach my $backup (@backups_arr) {
    if ($backup->get_age->days
      >= $self->app->config->{allow_delete_backups_older_than})
    {
      $backup->allow_delete(1);
    }
    else {
      $backup->allow_delete(undef);
    }
  }

  $self->stash(backups_arr => \@backups_arr, dir_size => $dir_size);
  $self->render(template => 'backup/backup');
}

sub save {
  my $self = shift;
  return $self->save_json;
}

sub save_json {
  my $self = shift;

  my $backup = do_json_backup($self->app);

  if ($backup->is_healthy) {
    $self->flash(msg_type => 'success', msg => "Backup created successfully");
  }
  else {
    $self->flash(msg_type => 'danger', msg => "Backup create failed!");
  }
  $self->redirect_to('backup_index');
}

sub save_mysql {
  my $self = shift;

  my $backup = do_mysql_backup($self->app);

  if ($backup->is_healthy) {
    $self->flash(msg_type => 'success', msg => "Backup created successfully");
  }
  else {
    $self->flash(msg_type => 'danger', msg => "Backup create failed!");
  }
  $self->redirect_to('backup_index');
}

sub cleanup {
  my $self = shift;
  my $age_treshold
    = $self->config->{backup_age_in_days_to_delete_automatically};

  my $num_deleted = delete_old_backups($self->app, $age_treshold);

  $self->app->logger->info(
    "Deleting old backups.  $num_deleted backups have been cleaned.");
  $self->flash(
    msg_type => 'success',
    msg      => "$num_deleted backups have been cleaned."
  );

# redirecting to referrer here breaks the test if the test supports redirects! why?
# disabling redirects for test and putting here referrer allows test to pass
  $self->redirect_to('backup_index');
}

sub backup_download {
  my $self = shift;
  my $uuid = $self->param('id');

  my $backup = find_backup($uuid, $self->app->get_backups_dir);

  if ($backup and $backup->is_healthy) {
    $self->app->logger->info("Downloading backup " . $backup->uuid);
    $self->render_file('filepath' => $backup->get_path);
  }
  else {
    $self->flash(
      msg_type => 'danger',
      msg      => "Cannot download backup $uuid - backup not healthy."
    );
    $self->redirect_to($self->get_referrer);
  }
}

sub delete_backup {
  my $self = shift;
  my $uuid = $self->param('id');

  my $backup = find_backup($uuid, $self->app->get_backups_dir);

  if ($backup and $backup->is_healthy) {
    if ($backup->get_age->days
      >= $self->app->config->{allow_delete_backups_older_than})
    {
      $backup->allow_delete(1);
    }
    else {
      $backup->allow_delete(undef);
    }
    if ($backup->allow_delete) {
      try {
        unlink $backup->get_path;
        $self->app->logger->info("Deleting backup " . $backup->uuid);
        $self->flash(msg_type => 'success', msg => "Backup id $uuid deleted!");
      }
      catch {
        $self->flash(
          msg_type => 'danger',
          msg      => "Exception during deleting backup '$uuid': $_."
        );
      };
    }
    else {
      $self->flash(
        msg_type => 'warning',
        msg      => "Backup $uuid is too young to be deleted!"
      );
    }
  }
  else {
    $self->flash(
      msg_type => 'danger',
      msg      => "Cannot delete backup $uuid - you need to do this manually."
    );
  }

  $self->res->code(303);
  $self->redirect_to($self->url_for('backup_index'));
}

# This is called for all types of backups
sub restore_backup {
  my $self = shift;
  my $uuid = $self->param('id');

  my $backup   = find_backup($uuid, $self->app->get_backups_dir);
  my $msg_type = '';
  my $msg      = '';

  if ($backup and $backup->is_healthy) {
    if ($backup->type eq 'json') {
      return $self->controller_restore_json_backup($backup);
    }
    else {
      $msg_type = 'danger';
      $msg      = 'Unknown backup type: ', $backup->type;
    }

  }
  else {
    $msg_type = 'danger';
    $msg      = 'Backup not found or unhealthy';
  }
  $self->flash(msg_type => $msg_type, msg => $msg,);
  $self->redirect_to('backup_index');
  return;
}

sub controller_restore_json_backup {
  my $self   = shift;
  my $backup = shift;

  my $msg_type = 'success';
  my $msg      = '';

  if ($backup and $backup->is_healthy) {
    $self->app->logger->info("Restoring JSON backup " . $backup->uuid);
    my $success = restore_json_backup($backup, $self->app);
    if ($success) {
      $msg_type = 'success';
      $msg
        = 'Backup restored succesfully. You may want to run now Settings -> Fix attachment URLs to automatically map attachments to entries.';
    }
    else {
      $msg_type = 'danger';
      $msg
        = 'Something went wrong during restoring... system might be in unknown state';
    }
  }
  else {
    $msg_type = 'warning';
    $msg      = 'Cannot restore - backup not found or not healthy!';
  }
  $self->flash(msg_type => $msg_type, msg => $msg,);
  $self->redirect_to('backup_index');
  return;
}

1;
