package IntegerUidProvider;
use feature qw(current_sub);
use Moose;
use BibSpace::Util::IUidProvider;
with 'IUidProvider';
use List::Util qw(max);
use Scalar::Util qw( refaddr );
use List::MoreUtils qw(any uniq);

use feature qw(current_sub);

use BibSpace::Util::SimpleLogger;

# use feature qw(current_sub);
use MooseX::ClassAttribute;

has 'data' => (
    traits    => ['Hash'],
    is        => 'ro',
    isa       => 'HashRef[Int]',
    default   => sub { {} },
    handles   => {
        uid_set     => 'set',
        uid_get     => 'get',
        uid_has     => 'exists',
        uid_defined => 'defined',
        uid_num     => 'count',
        uid_keys    => 'keys',
        uid_pairs   => 'kv',
        clear       => 'clear',
    },
);

sub reset {
    my ($self) = @_;
    $self->logger->warn("Resetting UID record for type '".$self->for_type."' !","".(caller(0))[3]."");
    $self->clear;
}

sub registerUID{
    my ($self, $uid) = @_;

    if( !$self->uid_defined($uid) ){
        $self->uid_set($uid => 1);
        $self->logger->lowdebug("Registered uid '$uid' for type '".$self->for_type."'.","".(caller(0))[3]."");
    }
    else{
        my $msg = "Cannot registerUID for type '".$self->for_type."'. It exists already! Wanted to reg: $uid. Existing: ". join(' ', sort $self->uid_keys);
        $self->logger->error($msg,"".(caller(0))[3]."");
        die $msg;
    }
}

sub last_id {
    my ( $self ) = @_;
    my $curr_max           = 0;                     # starting default id
    my $curr_max_candidate = max $self->uid_keys;
    if ( defined $curr_max_candidate and $curr_max_candidate > 0 ) {
        $curr_max = $curr_max_candidate;
    }
    return $curr_max;
}


sub generateUID{
    my ($self) = @_;

    my $curr_max  = $self->last_id;
    my $new_uid = $curr_max + 1;
    $self->uid_set($new_uid => 1);
    $self->logger->debug(__PACKAGE__." (".refaddr($self).") has generated uid '$new_uid' for type '".$self->for_type."'","".(caller(0))[3]."");
    return $new_uid;
}


no Moose;
1;