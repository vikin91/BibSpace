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
use MooseX::Storage;
use MooseX::ClassAttribute;
with Storage( format => 'JSON', 'io' => 'File' );

has '_bibitex_html_converter' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { Preferences->bibitex_html_converter }
);
has '_default_bibitex_html_converter' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { Preferences->default_bibitex_html_converter }
);
has '_local_time_zone' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { Preferences->local_time_zone }
);
has '_output_time_format' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { Preferences->output_time_format }
);
has '_cron' => (
    is      => 'rw',
    isa     => 'HashRef[Str]',
    default => sub { Preferences->cron },
);

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

sub load_class_vars {
    my ($self) = @_;
    $self->bibitex_html_converter( $self->_bibitex_html_converter );
    $self->local_time_zone( $self->_local_time_zone );
    $self->output_time_format( $self->_output_time_format );
    $self->cron( $self->_cron );
}

# sub store_class_vars {
#     my ($self) = @_;
#     $self->{_bibitex_html_converter} = Preferences->bibitex_html_converter;
#     $self->{_local_time_zone}        = Preferences->local_time_zone;
#     $self->{_output_time_format}     = Preferences->output_time_format;
#     $self->{_cron}                   = Preferences->cron;
# }

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
