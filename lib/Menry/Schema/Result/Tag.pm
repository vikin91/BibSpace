use utf8;
package Menry::Schema::Result::Tag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Menry::Schema::Result::Tag

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<Tag>

=cut

__PACKAGE__->table("Tag");

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 250

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 type

  data_type: 'integer'
  default_value: 1
  is_foreign_key: 1
  is_nullable: 1

=head2 permalink

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 0, size => 250 },
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "type",
  {
    data_type      => "integer",
    default_value  => 1,
    is_foreign_key => 1,
    is_nullable    => 1,
  },
  "permalink",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name", ["name"]);

=head1 RELATIONS

=head2 entries_to_tag

Type: has_many

Related object: L<Menry::Schema::Result::EntryToTag>

=cut

__PACKAGE__->has_many(
  "entries_to_tag",
  "Menry::Schema::Result::EntryToTag",
  { "foreign.tag_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 type

Type: belongs_to

Related object: L<Menry::Schema::Result::TagType>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Menry::Schema::Result::TagType",
  { id => "type" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 entries

Type: many_to_many

Composing rels: L</entries_to_tag> -> entry

=cut

__PACKAGE__->many_to_many("entries", "entries_to_tag", "entry");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-30 22:34:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VYBQiEr1ormL6UJXGfkpTA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
