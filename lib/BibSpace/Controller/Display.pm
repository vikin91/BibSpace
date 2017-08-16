package BibSpace::Controller::Display;

use strict;
use warnings;
use utf8;
use v5.16;    #because of ~~

# use File::Slurp;
use Try::Tiny;
use List::Util qw(first);

use Data::Dumper;

use Mojo::JSON qw(decode_json encode_json);
use Mojo::Base 'Mojolicious::Controller';
use BibSpace::Functions::MySqlBackupFunctions;
use BibSpace::Functions::Core;
use BibSpace::Util::Statistics;

sub index {
  my $self = shift;
  if ($self->app->is_demo) {
    $self->session(user      => 'demouser');
    $self->session(user_name => 'demouser');
  }
  $self->render(template => 'display/start');
}

sub test500 {
  my $self = shift;
  $self->render(text => 'Oops 500.', status => 500);
}

sub test404 {
  my $self = shift;
  $self->render(text => 'Oops 404.', status => 404);
}

sub get_log_lines {
  my $dir       = shift;
  my $num       = shift;
  my $type      = shift;
  my $filter_re = shift;

  my $log_dir = Path::Tiny->new($dir);

  my @file_list = $log_dir->children(qr/\.log$/);
  my @log_names = map { $_->basename('.log') } @file_list;

  my $log_2_read;
  $log_2_read = $log_dir->child($type . ".log") if defined $type;
  if ((!$log_2_read) or (!$log_2_read->exists)) {
    $log_2_read = $file_list[0];
  }

  die "No log file found " if (!-e $log_2_read);    # throw

 # my @lines = $log_2_read->lines( { count => -1 * $num } );
 # @lines = ( $num >= @lines ) ? reverse @lines : reverse @lines[ -$num .. -1 ];
  my @lines = $log_2_read->lines();

  # @lines = reverse @lines;
  chomp(@lines);

  if ($filter_re) {
    @lines = grep {m/$filter_re/} @lines;
  }
  return @lines[-$num .. -1];
}

sub show_log {
  my $self   = shift;
  my $num    = $self->param('num') // 100;
  my $type   = $self->param('type') // 'general';    # default
  my $filter = $self->param('filter');

  my @lines;
  try {
    @lines = get_log_lines($self->app->get_log_dir, $num, $type, $filter);
  }
  catch {
    $self->app->logger->error("Cannot find log '$type'. Error: $_.");
    $self->stash(msg_type => 'danger', msg => "Cannot find log '$type'.");
  };

  my @file_list
    = Path::Tiny->new($self->app->get_log_dir)->children(qr/\.log$/);
  my $curr_file
    = Path::Tiny->new($self->app->get_log_dir)->child('general.log');

  $self->stash(
    files     => \@file_list,
    lines     => \@lines,
    curr_file => $curr_file,
    num       => $num
  );
  $self->render(template => 'display/log');

}

sub show_log_ws {
  my $self = shift;
  my $num = $self->param('num') // 20;

  $self->on(
    message => sub {
      my ($self, $filter) = @_;

      my @lines
        = get_log_lines($self->app->get_log_dir, $num, 'general', $filter);
      $self->send(Mojo::JSON::encode_json(\@lines));
    }
  );

  $self->on(
    finish => sub {
      my ($c, $code, $reason) = @_;
      say "show_log_ws WS closed";
    }
  );
}

sub show_stats {
  my $self = shift;
  my $num = $self->param('num') // 20;

  my @lines = $self->app->statistics->toLines;

  $self->stash(lines => \@lines, num => $num);
  $self->render(template => 'display/stats');
}

sub show_stats_websocket {
  my $self = shift;
  my $num = $self->param('num') // 20;

  $self->on(
    message => sub {
      my ($self, $filter) = @_;

      my @all_lines = $self->app->statistics->toLines;
      my @lines = grep {/$filter/} @all_lines;
      $self->send(Mojo::JSON::encode_json(\@lines));
    }
  );

  $self->on(
    finish => sub {
      my ($c, $code, $reason) = @_;
      say "show_stats_websocket WS closed";
    }
  );
}

1;
