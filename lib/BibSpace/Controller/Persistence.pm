package BibSpace::Controller::Persistence;

use strict;
use warnings;
use utf8;
use v5.16;    #because of ~~

# use File::Slurp;
use Try::Tiny;

use Data::Dumper;

use BibSpace::Functions::MySqlBackupFunctions;
use BibSpace::Functions::Core;
use BibSpace::Model::Backup;
use BibSpace::Functions::BackupFunctions qw(restore_storable_backup);
use BibSpace::Functions::FDB;

use Mojo::Base 'Mojolicious::Controller';

sub persistence_status {
  my $self = shift;

  my $status
    = "Status: <pre style=\"font-family:monospace;\">"
    . $self->app->repo->lr->get_summary_table
    . "</pre>";
  $self->stash(msg_type => 'success', msg => $status);
  $self->flash(msg_type => 'success', msg => $status);
  $self->redirect_to($self->get_referrer);
}

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

  my $fixture_file = $self->app->home->rel_file('fixture/bibspace_fixture.dat');
  $self->app->logger->info("Loading fixture from: " . $fixture_file->to_string);

  my $fixture = Backup->new(
    dir      => '' . $fixture_file->dirname,
    filename => '' . $fixture_file->basename
  );

  restore_storable_backup($fixture, $self->app);

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

  my $fixture_file = $self->app->home->rel_file('fixture/bibspace_fixture.dat');

  my $backup = Backup->create('dummy', "storable");
  $backup->dir('' . $fixture_file->dirname);
  $backup->filename('' . $fixture_file->basename);

  my $layer = $self->app->repo->lr->get_read_layer;
  my $path  = "" . $backup->get_path;

  $Storable::forgive_me = "do store regexp please, we will not use them anyway";

# if you see any exceptions being thrown here, this might be due to REGEXP caused by DateTime pattern.
# this should not happen currently however - I think it is fixed now.
  Storable::store $layer, $path;

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

sub copy_mysql_to_smart {
  my $self = shift;

  $self->app->logger->warn("PERSISTENCE CONTROLLER does: copy_mysql_to_smart");

  $self->app->repo->lr->copy_data({from => 'mysql', to => 'smart'});
  $self->app->link_data;

  my $status
    = "Status: <pre style=\"font-family:monospace;\">"
    . $self->app->repo->lr->get_summary_table
    . "</pre>";
  $self->flash(msg_type => 'success', msg => "Copied mysql => smart. $status");
  $self->redirect_to($self->get_referrer);
}

sub copy_smart_to_mysql {
  my $self = shift;

  $self->app->repo->lr->copy_data({from => 'smart', to => 'mysql'});

  my $status
    = "Status: <pre style=\"font-family:monospace;\">"
    . $self->app->repo->lr->get_summary_table
    . "</pre>";
  $self->flash(msg_type => 'success', msg => "Copied smart => mysql. $status");
  $self->redirect_to($self->get_referrer);
}

sub insert_random_data {
  my $self = shift;
  my $num = $self->param('num') // 300;

  my $str_len = 60;

  for (1 .. $num) {
    my $obj = $self->app->entityFactory->new_User(
      login     => random_string($str_len),
      email     => random_string($str_len) . '@example.com',
      real_name => random_string($str_len),
      pass      => random_string($str_len),
      pass2     => random_string($str_len)

    );
    $self->app->repo->users_save($obj);

    $obj
      = $self->app->entityFactory->new_Author(uid => random_string($str_len),);
    $self->app->repo->authors_save($obj);

    $obj
      = $self->app->entityFactory->new_Entry(bib => random_string($str_len),);
    $self->app->repo->entries_save($obj);

    $obj
      = $self->app->entityFactory->new_TagType(name => random_string($str_len),
      );
    $self->app->repo->tagTypes_save($obj);

    my $tt = ($self->app->repo->tagTypes_all)[0];

    $obj = $self->app->entityFactory->new_Tag(
      name => random_string($str_len),
      type => $tt->id
    );
    $self->app->repo->tags_save($obj);

    $obj
      = $self->app->entityFactory->new_Team(name => random_string($str_len),);
    $self->app->repo->teams_save($obj);
  }

  my $status
    = "Status: <pre style=\"font-family:monospace;\">"
    . $self->app->repo->lr->get_summary_table
    . "</pre>";
  $self->flash(msg_type => 'success', msg => "Copied smart => mysql. $status");
  $self->redirect_to($self->get_referrer);
}

sub reset_smart {
  my $self = shift;

  $self->app->logger->warn("PERSISTENCE CONTROLLER does: reset_smart");

  my $layer = $self->app->repo->lr->get_layer('smart');
  if ($layer) {
    $layer->reset_data;
  }

  # no pub_admin user would lock the whole system
  # if you insert it here, it may will cause clash of IDs
  # $self->app->insert_admin;
  # instead, do not insert admin and set system in demo mode
  $self->app->preferences->run_in_demo_mode(1);

  say "setting preferences->run_in_demo_mode to: '"
    . $self->app->preferences->run_in_demo_mode . "'";

  my $status
    = "Status: <pre style=\"font-family:monospace;\">"
    . $self->app->repo->lr->get_summary_table
    . "</pre>";
  $self->flash(msg_type => 'success', msg => $status);
  $self->redirect_to($self->get_referrer);
}

sub reset_mysql {
  my $self = shift;

  $self->app->logger->warn("PERSISTENCE CONTROLLER does: reset_mysql");

  my $layer = $self->app->repo->lr->get_layer('mysql');
  if ($layer) {
    $layer->reset_data;
    my $status
      = "Status: <pre style=\"font-family:monospace;\">"
      . $self->app->repo->lr->get_summary_table
      . "</pre>";
    $self->flash(msg_type => 'success', msg => $status);
  }
  else {
    my $status
      = "Status: <pre style=\"font-family:monospace;\">"
      . $self->app->repo->lr->get_summary_table
      . "</pre>";
    $self->flash(
      msg_type => 'danger',
      msg      => "Reset failed - backend handle undefined. " . $status
    );
  }

  $self->redirect_to($self->get_referrer);
}

sub reset_all {
  my $self = shift;

  $self->app->logger->warn("PERSISTENCE CONTROLLER does: reset_all");

  my @layers = $self->app->repo->lr->get_all_layers;
  foreach (@layers) { $_->reset_data }
  $self->app->repo->lr->reset_uid_providers;

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
