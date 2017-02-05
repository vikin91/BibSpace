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
use MooseX::Storage;
with Storage( format => 'JSON', 'io' => 'File' );

class_has 'bibitex_html_converter'   => ( is => 'rw', default => 'BibStyleConverter');

class_has 'local_time_zone'   => ( is => 'rw', default => 'Europe/Berlin');#, trigger => \&_pref_changed );

# http://search.cpan.org/~drolsky/DateTime-1.42/lib/DateTime.pm#strftime_Patterns
class_has 'output_time_format'   => ( is => 'rw', default => '%a %d %b %T, %Y');#, trigger => \&_pref_changed );




sub _pref_changed {
    my ( $self, $curr_val, $prev_val ) = @_;
    if ( $prev_val and $curr_val ne $prev_val ) {
        # say "A preference changed to '$curr_val'.";
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
