#!/usr/bin/perl

use v5.12;
use warnings;

use Mojolicious::Lite;
use Mojo::Redis2;

helper redis => sub { state $redis = Mojo::Redis2->new() };

app->redis->subscribe(['long_running_tasks']);

app->redis->on(
  message => sub {
    my ($self, $message, $channel) = @_;
    say "$message @ $channel staring...";
    sleep(10);
    say "$message @ $channel done!";
  }
);

app->redis->on(
  error => sub {
    my ($self, $err) = @_;
    say "error $err";
  }
);

get '/' => sub {
  my $self = shift;
  app->redis->publish("long_running_tasks" => "go");

  $self->render(json => {a => 1});
};

app->start;

