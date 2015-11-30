use utf8;
package Menry::Schema::Result::Cron;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Menry::Schema::Result::Cron

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<Cron>

=cut

__PACKAGE__->table("Cron");

=head1 ACCESSORS

=head2 type

  data_type: 'integer'
  is_nullable: 0

=head2 last_run_time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "type",
  { data_type => "integer", is_nullable => 0 },
  "last_run_time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</type>

=back

=cut

__PACKAGE__->set_primary_key("type");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-30 22:34:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Fl56TUHH0n7Ofinn8kKAWQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
