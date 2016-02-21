use utf8;
package Hex64Publications::Schema::Result::ExceptionsEntryToTeam;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Hex64Publications::Schema::Result::ExceptionsEntryToTeam

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<Exceptions_Entry_to_Team>

=cut

__PACKAGE__->table("Exceptions_Entry_to_Team");

=head1 ACCESSORS

=head2 entry_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 team_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "entry_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "team_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</entry_id>

=item * L</team_id>

=back

=cut

__PACKAGE__->set_primary_key("entry_id", "team_id");

=head1 RELATIONS

=head2 entry

Type: belongs_to

Related object: L<Hex64Publications::Schema::Result::Entry>

=cut

__PACKAGE__->belongs_to(
  "entry",
  "Hex64Publications::Schema::Result::Entry",
  { id => "entry_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);

=head2 team

Type: belongs_to

Related object: L<Hex64Publications::Schema::Result::Team>

=cut

__PACKAGE__->belongs_to(
  "team",
  "Hex64Publications::Schema::Result::Team",
  { id => "team_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-30 22:34:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m9yF7N204O3NLaXO3Lj0AQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
