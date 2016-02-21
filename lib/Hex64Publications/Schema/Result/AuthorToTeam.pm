use utf8;
package Hex64Publications::Schema::Result::AuthorToTeam;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Hex64Publications::Schema::Result::AuthorToTeam

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<Author_to_Team>

=cut

__PACKAGE__->table("Author_to_Team");

=head1 ACCESSORS

=head2 author_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 team_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 start

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 stop

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "author_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "team_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "start",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "stop",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</author_id>

=item * L</team_id>

=back

=cut

__PACKAGE__->set_primary_key("author_id", "team_id");

=head1 RELATIONS

=head2 author

Type: belongs_to

Related object: L<Hex64Publications::Schema::Result::Author>

=cut

__PACKAGE__->belongs_to(
  "author",
  "Hex64Publications::Schema::Result::Author",
  { master_id => "author_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 team

Type: belongs_to

Related object: L<Hex64Publications::Schema::Result::Team>

=cut

__PACKAGE__->belongs_to(
  "team",
  "Hex64Publications::Schema::Result::Team",
  { id => "team_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-30 22:34:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:K8es9/d6O8yqlq+pGKi6zA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
