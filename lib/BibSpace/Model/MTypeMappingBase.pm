package MTypeMappingBase;

use List::MoreUtils qw(any uniq);
use BibSpace::Model::StorageBase;

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


################################################################################
sub init_storage {
    my $self = shift;

    if( $self->bibtexTypes_count == 0){
        $self->bibtexTypes([]);
    }
}
####################################################################################
sub replaceFromStorage {
    my $self = shift;
    my $storage  = shift; # dependency injection
    # use BibSpace::Model::StorageBase;

    my $storageItem = $storage->typeMappings_find( sub{ $_->equals($self) } );

    die "Cannot find ".ref($self).": ".Dumper($self)." in storage " unless $storageItem;
    return $storageItem;
}
####################################################################################
sub toString {
    my $self = shift;
    return "TypeMapping. our: ".$self->our_type." mapsto: [".join(',', $self->bibtexTypes_all)."]\n";
}
####################################################################################
sub equals {
    my $self = shift;
    my $obj  = shift;
    return ($self->our_type cmp $obj->our_type) == 0;
}
####################################################################################

no Moose;
__PACKAGE__->meta->make_immutable;
1;
