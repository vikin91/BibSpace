use utf8;
package Hex64Publications::Schema::Result::Token;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Hex64Publications::Schema::Result::Token

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<Token>

=cut

__PACKAGE__->table("Token");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 token

  data_type: 'varchar'
  is_nullable: 0
  size: 250

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 250

=head2 requested

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "token",
  { data_type => "varchar", is_nullable => 0, size => 250 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 250 },
  "requested",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<login_token_unique>

=over 4

=item * L</token>

=back

=cut

__PACKAGE__->add_unique_constraint("login_token_unique", ["token"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-30 22:34:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PEhIVpc74d/uPBjHXAhAKA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
