package BibSpace::Controller::Persistence;

use strict;
use warnings;
use utf8;
use v5.16;    #because of ~~

# use File::Slurp;
use Try::Tiny;

use Data::Dumper;

use BibSpace::Functions::MySqlBackupFunctions;
use BibSpace::Functions::BackupFunctions qw/restore_json_backup/;
use BibSpace::Functions::Core;
use BibSpace::Model::Backup;
use BibSpace::Functions::FDB;

use Mojo::Base 'Mojolicious::Controller';

sub persistence_status_ajax {
  my $self = shift;

  my $status
    = "Status: <pre style=\"font-family:monospace;\">"
    . $self->app->repo->lr->get_summary_table
    . "</pre>";
  $self->render(text => $status);
}

sub load_fixture {
  my $self = shift;

  my $fixture_file
    = $self->app->home->rel_file('fixture/bibspace_fixture.json');
  $self->app->logger->info("Loading fixture from: " . $fixture_file->to_string);

  my $fixture = Backup->new(
    dir      => '' . $fixture_file->dirname,
    filename => '' . $fixture_file->basename
  );

  restore_json_backup($fixture, $self->app);

  my $status
    = "Status: <pre style=\"font-family:monospace;\">"
    . $self->app->repo->lr->get_summary_table
    . "</pre>";
  $self->flash(
    msg_type => 'success',
    msg      => "Fixture loaded into memory and mysql. $status"
  );
  $self->redirect_to($self->get_referrer);
}

sub save_fixture {
  my $self = shift;

  $self->app->logger->warn("PERSISTENCE CONTROLLER does: save_fixture");

  my $fixture_file
    = $self->app->home->rel_file('fixture/bibspace_fixture.json');

  my $backup = Backup->create('dummy', "json");
  $backup->dir('' . $fixture_file->dirname);
  $backup->filename('' . $fixture_file->basename);

  my $layer = $self->app->repo->lr->get_read_layer;
  my $path  = "" . $backup->get_path;

  # Doing backup
  my $dtoObject  = BibSpaceDTO->fromLayeredRepo($self->app->repo);
  my $jsonString = $dtoObject->toJSON;
  Path::Tiny::path($backup->get_path)->spew($jsonString);

  my $status
    = "Status: <pre style=\"font-family:monospace;\">"
    . $self->app->repo->lr->get_summary_table
    . "</pre>";
  $self->flash(
    msg_type => 'success',
    msg      => "Fixture stored to '" . $backup->get_path . "'. $status"
  );
  $self->redirect_to($self->get_referrer);
}

sub reset_all {
  my $self = shift;

  $self->app->logger->warn("PERSISTENCE CONTROLLER does: reset_all");

  my @layers = $self->app->repo->lr->get_all_layers;
  foreach (@layers) { $_->reset_data }

  # no pub_admin user would lock the whole system
  # if you insert it here, it may will cause clash of IDs
  # $self->app->insert_admin;
  # instead, do not insert admin and set system in demo mode
  $self->app->preferences->run_in_demo_mode(1);

  my $status
    = "Status: <pre style=\"font-family:monospace;\">"
    . $self->app->repo->lr->get_summary_table
    . "</pre>";
  $self->flash(msg_type => 'success', msg => $status);
  $self->redirect_to($self->get_referrer);
}

sub system_status {
  my $self = shift;

  my $msg         = "";
  my $log_dir     = $self->app->get_log_dir;
  my $backups_dir = $self->app->config->{backups_dir};
  my $upload_dir  = $self->app->get_upload_dir;

  my $backup_dir_absolute = $self->config->{backups_dir};
  $backup_dir_absolute
    =~ s!/*$!/!;    # makes sure that there is exactly one / at the end

  my $errored = 0;

  ###################
  $msg .= "<br/>" . "Connecting to DB: ";
  try {
    $self->app->db;
    $msg .= "OK ";
  }
  catch {
    $msg .= "ERROR: $_";
    $errored = 1;
  };
  ###################
  $msg .= "<br/>" . "Reading upload directory: ";
  try {
    get_dir_size($upload_dir);
    $msg .= "OK ";
  }
  catch {
    $msg .= "ERROR: $_";
    $errored = 1;
  };
  ###################
  $msg .= "<br/>" . "Reading log directory: ";
  try {
    get_dir_size($log_dir);
    $msg .= "OK ";
  }
  catch {
    $msg .= "ERROR: $_";
    $errored = 1;
  };
  ###################
  $msg .= "<br/>" . "Reading backup dir: ";
  try {
    get_dir_size($backups_dir);
    $msg .= "OK ";
  }
  catch {
    $msg .= "ERROR: $_";
    $errored = 1;
  };
  ###################
  $msg .= "<br/>" . "Current state of persistence backends:";
  $msg .= "<br/>" . "<pre style=\"font-family:monospace;\">";
  $msg .= $self->app->repo->lr->get_summary_table;
  $msg .= "</pre>";
  ###################
  $msg .= "<br/>" . "End.";

  if ($errored) {
    $self->render(text => $msg, status => 500);
    return;
  }
  else {
    $self->render(text => $msg, status => 200);
  }
}

1;
