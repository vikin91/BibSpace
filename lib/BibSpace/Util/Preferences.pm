package Preferences;

use v5.16;    
use Try::Tiny;
use Data::Dumper;
use namespace::autoclean;

use List::Util qw(first);
use List::MoreUtils qw(first_index);
use feature qw( state say );


use Moose;

use Moose::Util::TypeConstraints;

use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );


# I can't name it load due to deep recursion (direct or indirect)
sub load_maybe {
  my $self = shift;
  if ( -e 'bibspace_preferences.json' ) {
    say "Loading prefeerences from file 'bibspace_preferences.json'.";
    return Preferences->load('bibspace_preferences.json');
  }
  return $self;
}

has 'run_in_demo_mode' =>
  ( is => 'rw', isa => 'Int', default => 0, trigger => \&_pref_changed );

has 'bibitex_html_converter' =>
  ( is => 'rw', isa => 'Str', default => 'BibStyleConverter', trigger => \&_pref_changed );

# important for Preferences form to set flag "(default)" by the right list item
has 'default_bibitex_html_converter' => ( is => 'ro', isa => 'Str', default => 'BibStyleConverter' );

has 'local_time_zone' => ( is => 'rw', isa => 'Str', default => 'Europe/Berlin', trigger => \&_pref_changed );

# http://search.cpan.org/~drolsky/DateTime-1.42/lib/DateTime.pm#strftime_Patterns
has 'output_time_format' => ( is => 'rw', isa => 'Str', default => '%a %d %b %T, %Y', trigger => \&_pref_changed );

# cron_level => last_call
has 'cron' => (
  traits  => ['Hash'],
  is      => 'rw',
  isa     => 'HashRef[Str]',
  default => sub { {} },
  trigger => \&_pref_changed,
  handles => {
    cron_set     => 'set',
    cron_get     => 'get',
    cron_has     => 'exists',
    cron_defined => 'defined',
    cron_keys    => 'keys',
    cron_values  => 'values',
    cron_num     => 'count',
    cron_pairs   => 'kv',
  },
);

###### METHODS

sub _pref_changed {
  my ( $self, $curr_val, $prev_val ) = @_;

  if ( $prev_val and $curr_val ne $prev_val ) {
    say "A preference changed to '$curr_val'.";
    $self->store('bibspace_preferences.json');
  }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
