package UserSerializableBase;

use utf8;
use v5.16;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::ClassAttribute;
use BibSpace::Model::SerializableBase::IEntitySerializableBase;
with 'IEntitySerializableBase';

class_has 'admin_rank'   => (is => 'ro', default => 2);
class_has 'manager_rank' => (is => 'ro', default => 1);
class_has 'user_rank'    => (is => 'ro', default => 0);

has 'login'     => (is => 'rw', isa => 'Str', required => 1);
has 'real_name' => (is => 'rw', isa => 'Str', default  => "unnamed");
has 'email'     => (is => 'rw', isa => 'Str', required => 1);
has 'rank'  => (is => 'rw', default => UserSerializableBase->user_rank);
has 'pass'  => (is => 'rw', isa     => 'Str');
has 'pass2' => (is => 'rw', isa     => 'Str', documentation => q{Salt});
has 'pass3' => (
  is            => 'rw',
  isa           => 'Maybe[Str]',
  documentation => q{Last password forgot token}
);

has 'master_id'         => (is => 'rw', default => 0);
has 'tennant_id'        => (is => 'rw', default => 0);
has 'last_login'        => (is => 'rw', isa     => 'DateTime');
has 'registration_time' => (is => 'ro', isa     => 'DateTime');

# Factory method
sub new__DateTime_from_string {
  my ($class, $dtFormat, %args) = @_;

# last_login and registration_time are inputed as strings in format: '2017-02-08T02:00:03'
  my $inputPattern   = DateTime::Format::Strptime->new(pattern => $dtFormat);
  my $last_login_obj = $inputPattern->parse_datetime($args{'last_login'});
  my $registration_time_obj
    = $inputPattern->parse_datetime($args{'registration_time'});
  $args{'last_login'}        = $last_login_obj;
  $args{'registration_time'} = $registration_time_obj;

  return $class->new(%args);
}

# We want to be able to have DateTime object built when we pass is as string
#
# The BUILDARGS method is called as a class method before an object is created.
# It will receive all of the arguments that were passed to new() as-is, and is expected to return a hash reference.
# This hash reference will be used to construct the object
# around BUILDARGS => sub {
#   my $input = shift;
#   my $class = shift;
#
#   # last_login and registration_time are inputed as strings in format: '2017-02-08T02:00:03'
#
#   if (@_ == 1 && !ref $_[0]) {
#     return $class->$input(ssn => $_[0]);
#   }
#   else {
#     return $class->$input(@_);
#   }
# };

no Moose;
__PACKAGE__->meta->make_immutable;
1;
