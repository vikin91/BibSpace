package IntegerUidProvider;
use Moose;
use BibSpace::Model::IUidProvider;
with 'IUidProvider';
use List::Util qw(max);
use List::MoreUtils qw(any uniq);
use BibSpace::Model::SimpleLogger;

# use MooseX::ClassAttribute;

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
        uid_pairs   => 'kv',
    },
);

sub registerUID{
    my ($self, $uid) = @_;

    if( !$self->uid_defined($uid) ){
        $self->uid_set($uid => 1);
        SimpleLogger->new()->debug("Registered uid $uid.");
    }
    else{
        die "Cannot registerUID. It exists already!";
    }
}

sub generateUID{
    my ($self) = @_;

    my $curr_max = 1; # starting default id
    my $curr_max_candidate = max keys $self->data;
    if(defined $curr_max_candidate and $curr_max_candidate > 0){
        $curr_max = $curr_max_candidate;
    }
    my $new_uid = $curr_max + 1;
    $self->uid_set($new_uid => 1);
    SimpleLogger->new()->debug("Generated uid $new_uid.");
    return $new_uid;
}


no Moose;
1;