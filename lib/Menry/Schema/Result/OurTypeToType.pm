use utf8;
package Menry::Schema::Result::OurTypeToType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Menry::Schema::Result::OurTypeToType

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<OurType_to_Type>

=cut

__PACKAGE__->table("OurType_to_Type");

=head1 ACCESSORS

=head2 bibtex_type

  data_type: 'varchar'
  is_nullable: 0
  size: 250

=head2 our_type

  data_type: 'varchar'
  is_nullable: 0
  size: 250

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 landing

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "bibtex_type",
  { data_type => "varchar", is_nullable => 0, size => 250 },
  "our_type",
  { data_type => "varchar", is_nullable => 0, size => 250 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "landing",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</bibtex_type>

=item * L</our_type>

=back

=cut

__PACKAGE__->set_primary_key("bibtex_type", "our_type");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-30 22:34:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PkKgKxoDM+2cgZe7qk9VRQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
