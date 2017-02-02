package Backup;

use Data::Dumper;
use utf8;

use 5.010;           #because of ~~ and say
use List::MoreUtils qw(any uniq);
use List::Util qw(first);
use Moose;

use UUID::Tiny ':std';

use DateTime::Format::Strptime;
use DateTime;
my $dtPattern
    = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d-%H-%M-%S' );

has 'uuid'     => ( is => 'rw', isa => 'Str', default => sub{ create_uuid_as_string(UUID_V4) } );
has 'name'     => ( is => 'rw', isa => 'Str', default => 'normal');
has 'type'     => ( is => 'rw', isa => 'Str', default => 'storable');
has 'filename' => ( is => 'rw', isa => 'Maybe[Str]' );
has 'dir'      => ( is => 'rw', isa => 'Maybe[Str]' );
has 'date' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        return "".DateTime->now(formatter => $dtPattern);
    },
);
####################################################################################
sub id {
  shift->uuid;
}
####################################################################################
sub get_size {
  my $self = shift;
  my $size = -s $self->get_path;
  $size = 0 + $size;
  $size = $size / 1024 / 1024;
  $size = sprintf("%.2f", $size);
  return "$size MB";
}
####################################################################################
sub get_path {
  my $self = shift;

  warn "backup->dir not set!" unless defined $self->dir;

  my $file_path = $self->dir . $self->filename;
  return $file_path;
}
####################################################################################
sub is_healthy {
  my $self = shift;
  my $dir = $self->dir;
  $dir =~ s!/*$!/!;
  my $file_path = $dir . $self->filename;
  return -e $file_path;
}
####################################################################################
sub create {
  my $self = shift;
  my $name = shift;
  my $type = shift // 'storable';

  my $uuid = create_uuid_as_string(UUID_V4);

  my $now = "".DateTime->now(formatter => $dtPattern);

  my $filename = "backup_$uuid"."_$name"."_$type"."_$now".".dat";

  my $b = Backup->new(filename => $filename, uuid=> $uuid, name => $name, type=>$type, date=>$now);
  return $b;
}
####################################################################################
sub parse {
  my $self = shift;
  my $filename = shift;

  my @tokens = split('_', $filename);
  my $prefix = shift @tokens;
  my $uuid = shift @tokens;
  my $name = shift @tokens;
  my $type = shift @tokens;
  my $date = shift @tokens;


  $date =~ s/\.dat//g;

  my $now = "".$dtPattern->parse_datetime( $date );

  my $b = Backup->new(filename => $filename, uuid=> $uuid, name => $name, type=>$type, date=>$now);
  return $b;
}
####################################################################################
sub toString {
  my $self = shift;
  return "Backup filename '".$self->filename."'";
}
####################################################################################
sub equals {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj) unless ref($self) eq ref($obj);
  return $self->filename eq $obj->filename;
}
####################################################################################

no Moose;
__PACKAGE__->meta->make_immutable;
1;
