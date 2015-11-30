use utf8;
package Menry::Schema::Result::Author;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Menry::Schema::Result::Author

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<Author>

=cut

__PACKAGE__->table("Author");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 uid

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 display

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 master

  data_type: 'text'
  is_nullable: 1

=head2 master_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "uid",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "display",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "master",
  { data_type => "text", is_nullable => 1 },
  "master_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<author_uid_unique>

=over 4

=item * L</uid>

=back

=cut

__PACKAGE__->add_unique_constraint("author_uid_unique", ["uid"]);

=head1 RELATIONS

=head2 author_to_teams

Type: has_many

Related object: L<Menry::Schema::Result::AuthorToTeam>

=cut

__PACKAGE__->has_many(
  "author_to_teams",
  "Menry::Schema::Result::AuthorToTeam",
  { "foreign.author_id" => "self.master_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 authors

Type: has_many

Related object: L<Menry::Schema::Result::Author>

=cut

__PACKAGE__->has_many(
  "authors",
  "Menry::Schema::Result::Author",
  { "foreign.master_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entry_to_authors

Type: has_many

Related object: L<Menry::Schema::Result::EntryToAuthor>

=cut

__PACKAGE__->has_many(
  "entry_to_authors",
  "Menry::Schema::Result::EntryToAuthor",
  { "foreign.author_id" => "self.master_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 master

Type: belongs_to

Related object: L<Menry::Schema::Result::Author>

=cut

__PACKAGE__->belongs_to(
  "master",
  "Menry::Schema::Result::Author",
  { id => "master_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 entries

Type: many_to_many

Composing rels: L</entry_to_authors> -> entry

=cut

__PACKAGE__->many_to_many("entries", "entry_to_authors", "entry");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-30 22:34:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8XjzPw8pK5PJ+e7udXAVOQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
