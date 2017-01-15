package IntegerUidProvider;
use Moose;
use BibSpace::Model::IUidProvider;
with 'IUidProvider';
use List::Util qw(max);
use BibSpace::Model::SimpleLogger;

use MooseX::ClassAttribute;

class_has 'data' => (
    traits    => ['Hash'],
    is        => 'ro',
    isa       => 'HashRef[ArrayRef[Str]]',
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
    my ($self, $entity, $uid) = @_;


    if( !IntegerUidProvider->uid_defined($entity) ){
        IntegerUidProvider->uid_set($entity => []);
    }
    my $arrayref = IntegerUidProvider->uid_get($entity);
    my $exists = any { $_ == $uid } @{$arrayref};
    if( $exists ){
        die "Cannot registerUID for $entity. It exists already!";
    }
    SimpleLogger->new()->debug("Registered uid $uid for $entity.");
    push $arrayref, $uid;
    IntegerUidProvider->uid_set($entity, $arrayref);
}

sub generateUID{
    my ($self, $entity) = @_;
    if( !IntegerUidProvider->uid_defined($entity) ){
        IntegerUidProvider->uid_set($entity => []);
    }
    my $arrayref = IntegerUidProvider->uid_get($entity);
    my $curr_max = max @{$arrayref} // 0;
    my $new_uid = $curr_max + 1;
    push $arrayref, $new_uid;

    SimpleLogger->new()->debug("Generated uid $new_uid for $entity.");
    return $new_uid;
}


no Moose;
1;