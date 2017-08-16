package Backup;

use Data::Dumper;
use utf8;

use v5.16;
use List::MoreUtils qw(any uniq);
use List::Util qw(first);

use Moose;

use MooseX::ClassAttribute;
use UUID::Tiny ':std';

use DateTime::Format::Strptime;
use DateTime;

class_has 'date_format_pattern' => (is => 'ro', default => '%Y-%m-%d-%H-%M-%S');

has 'uuid' =>
  (is => 'rw', isa => 'Str', default => sub { create_uuid_as_string(UUID_V4) });
has 'name' => (is => 'rw', isa => 'Str', default => 'normal');
has 'type' => (is => 'rw', isa => 'Str', default => 'storable');
has 'filename'     => (is => 'rw', isa => 'Maybe[Str]');
has 'dir'          => (is => 'rw', isa => 'Maybe[Str]');
has 'allow_delete' => (is => 'rw', isa => 'Bool', default => 1);
has 'date' => (
  is      => 'rw',
  isa     => 'Str',
  default => sub {
    my $now
      = DateTime->now(formatter =>
        DateTime::Format::Strptime->new(pattern => Backup->date_format_pattern)
      );
    return "$now";
  },
);

sub id {
  shift->uuid;
}

sub get_size {
  my $self = shift;
  my $size = -s $self->get_path;
  $size = 0 + $size;
  $size = $size / 1024 / 1024;
  $size = sprintf("%.2f", $size);
  return $size;
}

sub get_path {
  my $self = shift;

  warn "backup->dir not set!" unless defined $self->dir;
  my $dir = $self->dir;
  $dir =~ s!/*$!/!;

  my $file_path = $dir . $self->filename;
  return $file_path;
}

sub is_healthy {
  my $self = shift;
  my $dir  = $self->dir;
  $dir =~ s!/*$!/!;
  my $file_path = $dir . $self->filename;
  return -e $file_path;
}

sub get_date_readable {
  my $self = shift;

  # parses from our format to default format
  my $date
    = DateTime::Format::Strptime->new(pattern => Backup->date_format_pattern)
    ->parse_datetime($self->date);

  # sets readable format for serialization
  $date->set_formatter(
    DateTime::Format::Strptime->new(pattern => '%d.%m.%Y %H:%M:%S'));
  return "$date";
}

sub get_age {
  my $self = shift;

  my $now = DateTime->now(formatter =>
      DateTime::Format::Strptime->new(pattern => Backup->date_format_pattern));
  my $then
    = DateTime::Format::Strptime->new(pattern => Backup->date_format_pattern)
    ->parse_datetime($self->date);

  my $diff = $now->subtract_datetime($then);
  return $diff;
}

sub create {
  my $self = shift;
  my $name = shift;
  my $type = shift // 'storable';

  my $ext = '.dat';
  $ext = '.sql' if $type eq 'mysql';

  my $uuid = create_uuid_as_string(UUID_V4);

  my $now
    = ""
    . DateTime->now(formatter =>
      DateTime::Format::Strptime->new(pattern => Backup->date_format_pattern));
  my $now_str = "$now";

  my $filename = "backup_$uuid" . "_$name" . "_$type" . "_$now" . $ext;

  return Backup->new(
    filename => $filename,
    uuid     => $uuid,
    name     => $name,
    type     => $type,
    date     => $now_str
  );
}

sub parse {
  my $self     = shift;
  my $filename = shift;

  # say "Backup->parse: $filename";

  my @tokens = split('_', $filename);
  die "Parse exception: wrong filename format. Probably not BibSpace backup."
    unless scalar(@tokens) == 5;
  my $prefix = shift @tokens;
  my $uuid   = shift @tokens;
  my $name   = shift @tokens;
  my $type   = shift @tokens;
  my $date   = shift @tokens;

  $date =~ s/\.dat//g;
  $date =~ s/\.sql//g;

# my $now = DateTime->now(formatter => DateTime::Format::Strptime->new( pattern => Backup->date_format_pattern ));
  my $now
    = DateTime::Format::Strptime->new(pattern => Backup->date_format_pattern)
    ->parse_datetime($date);
  $now->set_formatter(
    DateTime::Format::Strptime->new(pattern => Backup->date_format_pattern));
  my $now_str = "$now";

  return Backup->new(
    filename => $filename,
    uuid     => $uuid,
    name     => $name,
    type     => $type,
    date     => $now_str
  );
}

sub toString {
  my $self = shift;
  return "Backup filename '" . $self->filename . "'";
}

sub equals {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj)
    unless ref($self) eq ref($obj);
  return $self->filename eq $obj->filename;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
