package Team;

use Try::Tiny;
use Devel::StackTrace;
use Data::Dumper;
use utf8;
use BibSpace::Model::Author;
use 5.010;    #because of ~~ and say
use List::MoreUtils qw(any uniq);
use Moose;
use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );

has 'id'   => ( is => 'rw', isa => 'Int' );
has 'name' => ( is => 'rw', isa => 'Str' );
has 'parent' => ( is => 'rw' );

has 'bteamMemberships' => (
    is      => 'rw',
    isa     => 'ArrayRef[MTeamMembership]',
    traits  => [ 'Array', 'DoNotSerialize' ],
    default => sub { [] },
    handles => {
        teamMemberships_all        => 'elements',
        teamMemberships_add        => 'push',
        teamMemberships_map        => 'map',
        teamMemberships_filter     => 'grep',
        teamMemberships_find       => 'first',
        teamMemberships_get        => 'get',
        teamMemberships_find_index => 'first_index',
        teamMemberships_delete     => 'delete',
        teamMemberships_clear      => 'clear',
        teamMemberships_join       => 'join',
        teamMemberships_count      => 'count',
        teamMemberships_has        => 'count',
        teamMemberships_has_no     => 'is_empty',
        teamMemberships_sorted     => 'sort',
    },
);

has 'bauthors' => (
    is      => 'rw',
    isa     => 'ArrayRef[MAuthor]',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        authors_all        => 'elements',
        authors_add        => 'push',
        authors_map        => 'map',
        authors_filter     => 'grep',
        authors_find       => 'first',
        authors_find_index => 'first_index',
        authors_delete     => 'delete',
        authors_clear      => 'clear',
        authors_get        => 'get',
        authors_join       => 'join',
        authors_count      => 'count',
        authors_has        => 'count',
        authors_has_no     => 'is_empty',
        authors_sorted     => 'sort',
    },
);

################################################################################
sub init_storage {
    my $self = shift;
    
    if( $self->authors_count == 0){
        $self->bauthors([]);
    }
    if( $self->teamMemberships_count == 0){
        $self->bteamMemberships([]);
    }
}
####################################################################################
sub replaceFromStorage {
    my $self    = shift;
    my $storage = shift;    # dependency injection
                            # use BibSpace::Model::M::StorageBase;

    my $storageItem = $storage->teams_find( sub { $_->equals($self) } );

    die "Cannot find " . ref($self) . ": " . Dumper($self) . " in storage "
        unless $storageItem;
    return $storageItem;
}
####################################################################################
sub toString {
    my $self = shift;
    $self->freeze;
}
####################################################################################
sub equals {
    my $self = shift;
    my $obj  = shift;

    my $result = 1;    # default not-equal
    $result = $self->{name} cmp $obj->{name};
    return $result == 0;
}
####################################################################################
sub can_be_deleted {
    my $self = shift;

    return 0 if $self->teamMemberships_count > 0;
    return 1;
}
################################################################################
sub has_author {
    my $self   = shift;
    my $author = shift;

    my $found = $self->authors_find( sub { $_->equals($author) } );
    return 1 if $found;
    return 0;
}
################################################################################
sub add_author {
    my $self   = shift;
    my $author = shift;

    return 0 if !defined $author and $author->{id} <= 0;


    if ( !$self->has_author($author) ) {

        $self->authors_add($author);
        $self->teamMemberships_add(
            MTeamMembership->new(
                author_id => $author->id,
                team_id   => $self->id,
                author    => $author,
                team      => $self,
                start     => 0,
                stop      => 0
            )
        );
        return 1;
    }
    return 0;


}
################################################################################
sub remove_all_authors {
    my $self   = shift;

    $self->teamMemberships_clear;
    $self->authors_clear;
}
################################################################################
sub remove_author {
    my $self   = shift;
    my $author = shift;

    return 0 if !defined $author and $author->{id} <= 0;

    my $mem_index = $self->teamMemberships_find_index(
        sub {
            $_->{author_id} == $author->id and $_->{team_id} == $self->id;
        }
    );
    return 0 if $mem_index == -1;
    $self->teamMemberships_delete($mem_index);

    my $index = $self->authors_find_index( sub { $_->equals($author) } );
    return 0 if $index == -1;
    return 1 if $self->authors_delete($index);
    return 0;

}
################################################################################
sub members {
    my $self = shift;
    return $self->authors_all;
}
####################################################################################
sub get_membership_beginning {
    my $self   = shift;
    my $author = shift;

    die("Author is undefined") unless defined $author;

    return $author->joined_team($self);
}
####################################################################################
sub get_membership_end {
    my $self   = shift;
    my $author = shift;

    die("Author is undefined") unless defined $author;

    return $author->left_team($self);
}
####################################################################################
sub tags {
    my $self = shift;
    my $type = shift // 1;

    my @myTags;
    my @members = $self->authors_all;
    foreach my $author (@members) {
        push @myTags, $author->tags($type);
    }
    @myTags = uniq @myTags;

    return @myTags;
}
####################################################################################
sub entries {
    my $self = shift;

    my @myEntries;
    my @members = $self->authors_all;
    foreach my $author (@members) {
        push @myEntries, $author->entries;
    }
    @myEntries = uniq @myEntries;

    return @myEntries;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
