use utf8;
package Menry::Schema::Result::Login;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Menry::Schema::Result::Login

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<Login>

=cut

__PACKAGE__->table("Login");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 registration_time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 last_login

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 login

  data_type: 'varchar'
  is_nullable: 0
  size: 250

=head2 real_name

  data_type: 'varchar'
  default_value: 'unnamed'
  is_nullable: 1
  size: 250

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 250

=head2 pass

  data_type: 'varchar'
  is_nullable: 0
  size: 250

=head2 pass2

  data_type: 'varchar'
  is_nullable: 0
  size: 250

=head2 pass3

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 master_id

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 tennant_id

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "registration_time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "last_login",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "login",
  { data_type => "varchar", is_nullable => 0, size => 250 },
  "real_name",
  {
    data_type => "varchar",
    default_value => "unnamed",
    is_nullable => 1,
    size => 250,
  },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 250 },
  "pass",
  { data_type => "varchar", is_nullable => 0, size => 250 },
  "pass2",
  { data_type => "varchar", is_nullable => 0, size => 250 },
  "pass3",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "master_id",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "tennant_id",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<login_unique>

=over 4

=item * L</login>

=back

=cut

__PACKAGE__->add_unique_constraint("login_unique", ["login"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-30 22:34:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fZWm4hIjMklHeJeIO61QUA

sub is_admin {
  my ($self) = @_;

  my $rank = $self->rank;
  return $rank > 1;
}

sub is_manager {
  my ($self) = @_;

  my $rank = $self->rank;
  return $rank > 0;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
