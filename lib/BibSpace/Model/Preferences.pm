package Preferences;

use 5.010;    #because of ~~ and say
use Try::Tiny;
use Data::Dumper;
use namespace::autoclean;

use List::Util qw(first);
use List::MoreUtils qw(first_index);
use feature qw( state say );

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::ClassAttribute;


###### CLASS VARIABLES

class_has 'bibitex_html_converter' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'BibStyleConverter',
    trigger => \&_pref_changed
);

# important for Preferences form
class_has 'default_bibitex_html_converter' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'BibStyleConverter',
    trigger => \&_pref_changed
);

class_has 'local_time_zone' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Europe/Berlin',
    trigger => \&_pref_changed
);

# http://search.cpan.org/~drolsky/DateTime-1.42/lib/DateTime.pm#strftime_Patterns
class_has 'output_time_format' => (
    is      => 'rw',
    isa     => 'Str',
    default => '%a %d %b %T, %Y',
    trigger => \&_pref_changed
);

# cron_level => last_call
# TODO: this will be not persisted and this is a real problem... need to solve this.
class_has 'cron' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[Str]',
    default => sub { {} },
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

    # $self->store_class_vars;
    if ( $curr_val ne $prev_val ) {
        say "A preference changed to '$curr_val'.";
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
