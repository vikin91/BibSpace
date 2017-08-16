package BibSpace::Controller::Cron;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use Try::Tiny;

use DateTime::Format::Strptime;
use DateTime;
use DateTime::Format::HTTP;

use v5.16;           #because of ~~
use strict;
use warnings;

use BibSpace::Functions::FPublications;
use BibSpace::Functions::BackupFunctions;

use Mojo::Base 'Mojolicious::Controller';

# use Mojo::UserAgent;

# crontab -e
# 0 4,12,20 * * * curl http://146.185.144.116:8080/cron/day
# 0 2 * * * curl http://146.185.144.116:8080/cron/night
# 5 2 * * 0 curl http://146.185.144.116:8080/cron/week
# 10 2 1 * * curl http://146.185.144.116:8080/cron/month

sub index {
  my $self = shift;

  use JSON -convert_blessed_universally;
  my $json_text
    = JSON->new->allow_blessed(1)->convert_blessed(1)->utf8(1)->pretty(1)
    ->encode($self->app->preferences);
  say $json_text;

  $self->stash(
    lr_0 => $self->get_last_cron_run(0),
    lr_1 => $self->get_last_cron_run(1),
    lr_2 => $self->get_last_cron_run(2),
    lr_3 => $self->get_last_cron_run(3)
  );
  $self->render(template => 'display/cron');
}

sub cron {
  my $self        = shift;
  my $level_param = $self->param('level');    # or shift;

  $self->app->logger->debug("Called cron with level param '$level_param'.");

  my $num_level = -1;                         # just in case

  $num_level = 0 if $level_param eq 'day'   or $level_param eq '0';
  $num_level = 1 if $level_param eq 'night' or $level_param eq '1';
  $num_level = 2 if $level_param eq 'week'  or $level_param eq '2';
  $num_level = 3 if $level_param eq 'month' or $level_param eq '3';

  my $result = $self->cron_level($num_level);
  if (!$result) {
    $self->render(
      text =>
        "Error 404. Incorrect cron job level: $level_param (numeric: $num_level)",
      status => 404
    );
  }
  else {
    $self->render(text => $result, status => 200);
  }

}

sub cron_level {
  my $self  = shift;
  my $level = shift;

  if ((!defined $level) or ($level < 0) or ($level > 3)) {
    return "";
  }

  my $call_freq = 99999;

  if ($level == 0) {
    $call_freq = $self->config->{cron_day_freq_lock};
  }
  elsif ($level == 1) {
    $call_freq = $self->config->{cron_night_freq_lock};
  }
  elsif ($level == 2) {
    $call_freq = $self->config->{cron_week_freq_lock};
  }
  elsif ($level == 3) {
    $call_freq = $self->config->{cron_month_freq_lock};
  }
  else {
    # should never happen
  }

  my $message_string = $self->cron_run($level, $call_freq);

  # place to debug
  return $message_string;
}

sub calc_hours {
  my $duration = shift;
  return $duration->years * 365 * 24 + $duration->days * 24 + $duration->hours;
}

sub cron_run {
  my $self      = shift;
  my $level     = shift;
  my $call_freq = shift;

  my $last_call_hours = 3;
  my $last_call       = $self->get_last_cron_run($level);

  # stupid library.... You need to convert units manually
  if (defined $last_call) {
    $last_call_hours = calc_hours($last_call);
  }
  my $left = $call_freq - $last_call_hours;

  my $text_to_render;

  ############ Cron ACTIONS
  if ($last_call_hours < $call_freq) {
    $text_to_render
      = "Cron level $level called too often. Last call $last_call_hours hours ago. Come back in $left hours\n";
    return $text_to_render;
  }
  else {
    $text_to_render = "Cron level $level here\n";
  }

  ############ Cron ACTIONS
  $self->app->logger->info("Cron level $level started");

  if ($level == 0) {
    $self->do_cron_day();
  }
  elsif ($level == 1) {
    Mojo::IOLoop->stream($self->tx->connection)->timeout(3600);
    $self->do_cron_night();
  }
  elsif ($level == 2) {
    Mojo::IOLoop->stream($self->tx->connection)->timeout(3600);
    $self->do_cron_week();
  }
  elsif ($level == 3) {
    Mojo::IOLoop->stream($self->tx->connection)->timeout(3600);
    $self->do_cron_month();
  }
  else {
    # do nothing
  }

# this may cause: [error] Unable to open file (bibspace_preferences.json) for storing : Permission denied at
  $self->log_cron_usage($level);
  $self->app->logger->info("Cron level $level has finished");

  return $text_to_render;
}

sub do_cron_day {
  my $self = shift;

  my $backup1 = do_storable_backup($self->app, "cron");

}

sub do_cron_night {
  my $self = shift;

  my @entries = $self->app->repo->entries_all;

  for my $e (@entries) {
    $e->regenerate_html(0, $self->app->bst, $self->app->bibtexConverter);
  }
}

sub do_cron_week {
  my $self = shift;

  my $backup1 = do_mysql_backup($self->app, "cron");
  my $num_deleted = delete_old_backups($self->app);

}

sub do_cron_month {
  my $self = shift;

}

sub log_cron_usage {
  my $self  = shift;
  my $level = shift;

  my $now
    = DateTime->now->set_time_zone($self->app->preferences->local_time_zone);
  my $fomatted_now = DateTime::Format::HTTP->format_datetime($now);

  say "Storing cron usage level '$level' as '$fomatted_now'.";

  $self->app->preferences->cron_set($level, $fomatted_now);
}

sub get_last_cron_run {
  my $self  = shift;
  my $level = shift;

  # constant :P
  my $long_time_ago = DateTime::Duration->new(years => 10);

  my $last_call_str = $self->app->preferences->cron_get($level);
  return $long_time_ago if !$last_call_str;

  my $now
    = DateTime->now->set_time_zone($self->app->preferences->local_time_zone);
  my $last_call;
  try {
    $last_call = DateTime::Format::HTTP->parse_datetime($last_call_str);
  }
  catch {
    warn;
    $self->app->logger->error(
      "Cannot parse date of last cron usage. Parser got input: '$last_call_str', error: $_ "
    );
  };
  return $long_time_ago if !$last_call;

  my $diff = $now->subtract_datetime($last_call);
  return $diff;
}

# sub get_last_cron_run_in_hours {
#     my $self   = shift;
#     my $level = shift;

#     my $last_call_str = $self->app->preferences->cron_get($level);
#     return 0 if !$last_call_str;

#     my $now = DateTime->now->set_time_zone($self->app->preferences->local_time_zone);
#     my $last_call;
#     try{
#         $last_call = DateTime::Format::HTTP->parse_datetime( $last_call_str );
#     }
#     catch{
#         warn;
#         $self->app->logger->error("Cannot parse date of last cron usage. Parser got input: '$last_call_str', error: $_ ");
#     };
#     return 0 if !$last_call;

#     my $diff = $now->subtract_datetime($last_call);
#     my $hours = $diff->hours;
#     return $hours;
# }

1;
