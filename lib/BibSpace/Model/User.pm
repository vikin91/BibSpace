package User;

use Try::Tiny;
use Data::Dumper;
use utf8;
use v5.16;
use List::MoreUtils qw(any uniq);

use BibSpace::Functions::Core qw(check_password);
use BibSpace::Model::IEntity;

use Moose;

use Moose::Util::TypeConstraints;

use MooseX::ClassAttribute;
with 'IEntity';

use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');

use DateTime::Format::Strptime;
use DateTime;
my $dtPattern = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d %H:%M:%S');

class_has 'admin_rank'   => (is => 'ro', default => 2);
class_has 'manager_rank' => (is => 'ro', default => 1);
class_has 'user_rank'    => (is => 'ro', default => 0);

has 'login'     => (is => 'rw', isa => 'Str', required => 1);
has 'real_name' => (is => 'rw', isa => 'Str', default  => "unnamed");
has 'email'     => (is => 'rw', isa => 'Str', required => 1);
has 'rank' => (is => 'rw', default => User->user_rank);

# pass = user password
has 'pass' => (is => 'rw', isa => 'Str');

# pass2 = salt
has 'pass2' => (is => 'rw', isa => 'Str');
has 'pass3' => (is => 'rw', isa => 'Maybe[Str]');

# TODO: forgot_token is not a DB field!
has 'forgot_token' => (is => 'rw', isa     => 'Maybe[Str]');
has 'master_id'    => (is => 'rw', default => 0);
has 'tennant_id'   => (is => 'rw', default => 0);

has 'last_login' => (
  is      => 'rw',
  isa     => 'DateTime',
  lazy    => 1,            # due to preferences
  default => sub {
    my $self = shift;
    DateTime->now->set_time_zone($self->preferences->local_time_zone);
  },
);

sub get_last_login {
  my $self = shift;

  $self->last_login->set_time_zone($self->preferences->local_time_zone)
    ->strftime($self->preferences->output_time_format);
}

has 'registration_time' => (
  is      => 'ro',
  isa     => 'DateTime',
  lazy    => 1,            # due to preferences
  default => sub {
    my $self = shift;
    DateTime->now->set_time_zone($self->preferences->local_time_zone);
  },
);

sub get_registration_time {
  my $self = shift;
  $self->registration_time->set_time_zone($self->preferences->local_time_zone)
    ->strftime($self->preferences->output_time_format);
}

sub toString {
  my $self = shift;
  my $str  = "User >> login: ";
  $str .= sprintf "'%32s',", $self->login;
  $str .= " rank: '" . $self->rank . "'";
  $str .= " email: ";
  $str .= sprintf "'%32s'.", $self->email;
  return $str;
}

sub equals {
  my $self = shift;
  my $obj  = shift;
  die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj)
    unless ref($self) eq ref($obj);
  return $self->login eq $obj->login;
}

sub authenticate {
  my $self       = shift;
  my $input_pass = shift;

  return if !defined $self->pass;

  if (check_password($input_pass, $self->pass)) {
    return 1;
  }

  # bad password
  return;
}

sub is_manager {
  my $self = shift;
  return 1 if $self->rank >= User->manager_rank;
  return;
}

# for _under_ -checking
sub is_admin {
  my $self = shift;
  return 1 if $self->rank >= User->admin_rank;
  return;
}

sub make_admin {
  my $self = shift;
  return $self->rank(User->admin_rank);
}

sub make_manager {
  my $self = shift;
  return $self->rank(User->manager_rank);
}

sub make_user {
  my $self = shift;
  return 0 == $self->rank(User->user_rank);
}

sub record_logging_in {
  my $self = shift;
  $self->last_login(
    DateTime->now->set_time_zone($self->preferences->local_time_zone));

}
no Moose;
__PACKAGE__->meta->make_immutable;
1;
