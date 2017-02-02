package Labeling;

use Data::Dumper;
use utf8;
use 5.010;    #because of ~~ and say
use BibSpace::Model::Author;

use DBI;
use DBIx::Connector;
use Try::Tiny;
use Devel::StackTrace;
use Moose;
use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );

# the fileds below are crucial, beacuse static_all has access only to tag/author ids and not to objects
# MTagMembership->load($dbh) should then fill the objects based on ids
has 'entry_id'   => ( is => 'ro', isa => 'Int' );
has 'tag_id' => ( is => 'ro', isa => 'Int' );
has 'entry' => (
    is     => 'rw',
    isa    => 'Maybe[Entry]',
    traits => ['DoNotSerialize']    # due to cycyles
);
has 'tag' => (
    is     => 'rw',
    isa    => 'Maybe[Tag]',
    traits => ['DoNotSerialize']    # due to cycyles
);
####################################################################################
sub id {
    my $self = shift;
    return "(".$self->entry_id."-".$self->tag->name.")" if defined $self->tag;
    return "(".$self->entry_id."-".$self->tag_id.")";
}
####################################################################################
sub validate {
    my $self = shift;
    if(defined $self->entry and defined $self->tag){
        if($self->entry->id != $self->entry_id){
            die "Label has been built wrongly entry->id and entry_id differs.\n"
            ."label->entry->id: ".$self->entry->id.", label->entry_id: ".$self->entry_id;
        }
        if($self->tag->id != $self->tag_id){
            die "Label has been built wrongly tag->id and tag_id differs.\n"
            ."label->tag->id: ".$self->tag->id.", label->tag_id: ".$self->tag_id;
        }
    }
    return 1;
}
####################################################################################
sub toString {
    my $self = shift;
    my $str  = $self->freeze;
    $str .= "\n";
    $str .= "\n\t (ENTRY): " . $self->entry->id if defined $self->entry;
    $str .= "\n\t (TEAM): " . $self->tag->id
        if defined $self->tag;
    $str;
}
####################################################################################

=item equals
    In case of any strange problems: this must return 1 or 0! 
=cut

sub equals {
    my $self = shift;
    my $obj  = shift;

    my $trace = Devel::StackTrace->new;
    my $trace_str = "\n=== TRACE ===\n" . $trace->as_string . "\n=== END TRACE ===\n";

    die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj) . "Trace: $trace_str" unless ref($self) eq ref($obj);
    
    if (    $self->entry
        and $self->tag
        and $obj->entry
        and $obj->tag )
    {
        return $self->equals_obj($obj);
    }
    return $self->equals_id($obj);
}
####################################################################################
sub equals_id {
    my $self = shift;
    my $obj  = shift;
    return if $self->entry_id != $obj->entry_id;
    return if $self->tag_id != $obj->tag_id;
    return 1;
}
####################################################################################
sub equals_obj {
    my $self = shift;
    my $obj  = shift;
    return 0 if !$self->entry->equals( $obj->entry );
    return 0 if !$self->tag->equals( $obj->tag );
    return 1;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;