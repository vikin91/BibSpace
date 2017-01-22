package Authorship;

use Data::Dumper;
use utf8;
use 5.010;    #because of ~~ and say
use BibSpace::Model::Author;
use BibSpace::Model::Entry;

use Try::Tiny;
use Moose;
use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );


# the fileds below are crucial, beacuse static_all has access only to team/author ids and not to objects
# MTeamMembership->load($dbh) should then fill the objects based on ids
has 'entry_id'   => ( is => 'ro', isa => 'Int' );
has 'author_id' => ( is => 'ro', isa => 'Int' );
has 'entry' => (
    is     => 'rw',
    isa    => 'Maybe[Entry]',
    traits => ['DoNotSerialize']    # due to cycyles
);
has 'author' => (
    is     => 'rw',
    isa    => 'Maybe[Author]',
    traits => ['DoNotSerialize']    # due to cycyles
);
####################################################################################
sub toString {
    my $self = shift;
    my $str  = $self->freeze;
    $str .= "\n";
    $str .= "\n\t (ENTRY): " . $self->entry->id if defined $self->entry;
    $str .= "\n\t (AUTHOR): " . $self->author->id
        if defined $self->author;
    $str;
}
####################################################################################

=item equals
    In case of any strange problems: this must return 1 or 0! 
=cut

sub equals {
    my $self = shift;
    my $obj  = shift;

    die "Comparing apples to peaches! ".ref($self)." against ".ref($obj) unless ref($self) eq ref($obj);

    if (    $self->entry
        and $self->author
        and $obj->entry
        and $obj->author )
    {
        return $self->equals_obj($obj);
    }
    return $self->equals_id($obj);
}
####################################################################################
sub equals_id {
    my $self = shift;
    my $obj  = shift;
    die "Comparing apples to peaches!!" unless ref($self) eq ref($obj);
    return if $self->entry_id != $obj->entry_id;
    return if $self->author_id != $obj->author_id;
    return 1;
}
####################################################################################
sub equals_obj {
    my $self = shift;
    my $obj  = shift;
    die "Comparing apples to peaches!!" unless ref($self) eq ref($obj);
    return if !$self->entry->equals( $obj->entry );
    return if !$self->author->equals( $obj->author );
    return 1;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
