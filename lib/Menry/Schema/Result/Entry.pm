use utf8;
package Menry::Schema::Result::Entry;
use Menry::Schema::Result::Tag;
# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Menry::Schema::Result::Entry

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<Entry>

=cut

__PACKAGE__->table("Entry");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 entry_type

  data_type: 'enum'
  extra: {list => ["paper","talk"]}
  is_nullable: 0

=head2 bibtex_key

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 bibtex_type

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 bib

  data_type: 'text'
  is_nullable: 1

=head2 html

  data_type: 'text'
  is_nullable: 1

=head2 html_bib

  data_type: 'text'
  is_nullable: 1

=head2 abstract

  data_type: 'text'
  is_nullable: 1

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 hidden

  data_type: 'tinyint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 year

  data_type: 'integer'
  is_nullable: 1

=head2 month

  data_type: 'tinyint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 sort_month

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 teams_str

  data_type: 'text'
  is_nullable: 1

=head2 people_str

  data_type: 'text'
  is_nullable: 1

=head2 tags_str

  data_type: 'text'
  is_nullable: 1

=head2 creation_time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 modified_time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 need_html_regen

  data_type: 'integer'
  default_value: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "entry_type",
  {
    data_type => "enum",
    extra => { list => ["paper", "talk"] },
    is_nullable => 0,
  },
  "bibtex_key",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "bibtex_type",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "bib",
  { data_type => "text", is_nullable => 1 },
  "html",
  { data_type => "text", is_nullable => 1 },
  "html_bib",
  { data_type => "text", is_nullable => 1 },
  "abstract",
  { data_type => "text", is_nullable => 1 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "hidden",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "year",
  { data_type => "integer", is_nullable => 1 },
  "month",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "sort_month",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "teams_str",
  { data_type => "text", is_nullable => 1 },
  "people_str",
  { data_type => "text", is_nullable => 1 },
  "tags_str",
  { data_type => "text", is_nullable => 1 },
  "creation_time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "modified_time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "need_html_regen",
  { data_type => "integer", default_value => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<bibtex_key>

=over 4

=item * L</bibtex_key>

=back

=cut

__PACKAGE__->add_unique_constraint("bibtex_key", ["bibtex_key"]);

=head1 RELATIONS

=head2 entries_to_tag

Type: has_many

Related object: L<Menry::Schema::Result::EntryToTag>

=cut

__PACKAGE__->has_many(
  "entries_to_tag",
  "Menry::Schema::Result::EntryToTag",
  { "foreign.entry_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entry_to_authors

Type: has_many

Related object: L<Menry::Schema::Result::EntryToAuthor>

=cut

__PACKAGE__->has_many(
  "entry_to_authors",
  "Menry::Schema::Result::EntryToAuthor",
  { "foreign.entry_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 exceptions_entry_to_teams

Type: has_many

Related object: L<Menry::Schema::Result::ExceptionsEntryToTeam>

=cut

__PACKAGE__->has_many(
  "exceptions_entry_to_teams",
  "Menry::Schema::Result::ExceptionsEntryToTeam",
  { "foreign.entry_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 authors

Type: many_to_many

Composing rels: L</entry_to_authors> -> author

=cut

__PACKAGE__->many_to_many("authors", "entry_to_authors", "author");

=head2 tags

Type: many_to_many

Composing rels: L</entries_to_tag> -> tag

=cut

__PACKAGE__->many_to_many("tags", "entries_to_tag", "tag");

=head2 teams

Type: many_to_many

Composing rels: L</exceptions_entry_to_teams> -> team

=cut

__PACKAGE__->many_to_many("teams", "exceptions_entry_to_teams", "team");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-30 22:34:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o4QS6GYqglPI/mWpQBENxA

sub isHidden {
  my ($self) = @_;
  return $self->hidden;
}

sub isTalk {
  my ($self) = @_;
  return $self->entry_type eq 'talk';
}

sub getTags {
  my ($self) = @_;
  return $self->tags;
}

sub getAuthors {
  my ($self) = @_;
  return $self->authors;
}
# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
