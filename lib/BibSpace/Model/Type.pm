package Type;

use List::MoreUtils qw(any uniq);
use BibSpace::Model::M::StorageBase;

use Data::Dumper;
use utf8;

use 5.010;           #because of ~~ and say
use DBI;
use Try::Tiny;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );

has 'our_type'     => ( is => 'ro', isa => 'Str');
has 'description'  => ( is => 'rw', isa => 'Maybe[Str]');
has 'onLanding'    => ( is => 'rw', isa => 'Int', default => 0);
has 'bibtexTypes' => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        bibtexTypes_all        => 'elements',
        bibtexTypes_add        => 'push',
        bibtexTypes_map        => 'map',
        bibtexTypes_filter     => 'grep',
        bibtexTypes_find       => 'first',
        bibtexTypes_find_index => 'first_index',
        bibtexTypes_delete     => 'delete',
        bibtexTypes_clear      => 'clear',
        bibtexTypes_get        => 'get',
        bibtexTypes_join       => 'join',
        bibtexTypes_count      => 'count',
        bibtexTypes_has        => 'count',
        bibtexTypes_has_no     => 'is_empty',
        bibtexTypes_sorted     => 'sort',
    },
);

####################################################################################
sub toString {
    my $self = shift;
    return "TypeMapping. our: ".$self->our_type." mapsto: [".join(',', $self->bibtexTypes_all)."]\n";
}
####################################################################################
sub equals {
    my $self = shift;
    my $obj  = shift;
    die "Comparing apples to peaches! ".ref($self)." against ".ref($obj) unless ref($self) eq ref($obj);
    return $self->our_type eq $obj->our_type;
}
####################################################################################

no Moose;
__PACKAGE__->meta->make_immutable;
1;
