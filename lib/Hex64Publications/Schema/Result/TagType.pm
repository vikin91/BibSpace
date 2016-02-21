use utf8;
package Hex64Publications::Schema::Result::TagType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Hex64Publications::Schema::Result::TagType

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<TagType>

=cut

__PACKAGE__->table("TagType");

=head1 ACCESSORS

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "text", is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 tags

Type: has_many

Related object: L<Hex64Publications::Schema::Result::Tag>

=cut

__PACKAGE__->has_many(
  "tags",
  "Hex64Publications::Schema::Result::Tag",
  { "foreign.type" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-30 22:34:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Jis2P6fRkx4vTBKk2aa+gQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
