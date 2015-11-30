use utf8;
package Menry::Schema::Result::EntryToTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Menry::Schema::Result::EntryToTag

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<Entry_to_Tag>

=cut

__PACKAGE__->table("Entry_to_Tag");

=head1 ACCESSORS

=head2 entry_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 tag_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "entry_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "tag_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</entry_id>

=item * L</tag_id>

=back

=cut

__PACKAGE__->set_primary_key("entry_id", "tag_id");

=head1 RELATIONS

=head2 entry

Type: belongs_to

Related object: L<Menry::Schema::Result::Entry>

=cut

__PACKAGE__->belongs_to(
  "entry",
  "Menry::Schema::Result::Entry",
  { id => "entry_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 tag

Type: belongs_to

Related object: L<Menry::Schema::Result::Tag>

=cut

__PACKAGE__->belongs_to(
  "tag",
  "Menry::Schema::Result::Tag",
  { id => "tag_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-30 22:34:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:90h9mAdn5k8H0fBvCsrZ8A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
