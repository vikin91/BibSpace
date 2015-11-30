use utf8;
package Menry::Schema::Result::Team;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Menry::Schema::Result::Team

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<Team>

=cut

__PACKAGE__->table("Team");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 250

=head2 parent

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 250 },
  "parent",
  { data_type => "varchar", is_nullable => 1, size => 250 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<team_name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("team_name_unique", ["name"]);

=head1 RELATIONS

=head2 author_to_teams

Type: has_many

Related object: L<Menry::Schema::Result::AuthorToTeam>

=cut

__PACKAGE__->has_many(
  "author_to_teams",
  "Menry::Schema::Result::AuthorToTeam",
  { "foreign.team_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 exceptions_entry_to_teams

Type: has_many

Related object: L<Menry::Schema::Result::ExceptionsEntryToTeam>

=cut

__PACKAGE__->has_many(
  "exceptions_entry_to_teams",
  "Menry::Schema::Result::ExceptionsEntryToTeam",
  { "foreign.team_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entries

Type: many_to_many

Composing rels: L</exceptions_entry_to_teams> -> entry

=cut

__PACKAGE__->many_to_many("entries", "exceptions_entry_to_teams", "entry");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-30 22:34:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0eD9SqPqR78+y4qfbI9zAg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
