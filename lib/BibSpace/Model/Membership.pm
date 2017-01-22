package Membership;

use Data::Dumper;
use utf8;
use 5.010;    #because of ~~ and say
use BibSpace::Model::Author;

use DBI;
use Try::Tiny;
use Devel::StackTrace;
use Moose;
use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );


has 'team' => (
    is     => 'rw',
    isa    => 'Maybe[Team]',
    traits => ['DoNotSerialize']    # due to cycyles
);
has 'author' => (
    is     => 'rw',
    isa    => 'Maybe[Author]',
    traits => ['DoNotSerialize']    # due to cycyles
);

# the fileds below are crucial, beacuse static_all has access only to team/author ids and not to objects
# MTeamMembership->load($dbh) should then fill the objects based on ids
has 'team_id'   => ( is => 'ro', isa => 'Int' );
has 'author_id' => ( is => 'ro', isa => 'Int' );

has 'start' => ( is => 'rw', isa => 'Int', default => 0 );
has 'stop'  => ( is => 'rw', isa => 'Int', default => 0 );
####################################################################################
sub id {
    my $self = shift;
    return "(".$self->team->name."-".$self->author->uid.")" if defined $self->author and defined $self->team;
    return "(".$_->team_id."-".$_->author_id.")";
}
####################################################################################
sub validate {
    my $self = shift;
    if(defined $self->author and defined $self->team){
        if($self->author->id != $self->author_id){
            die "Label has been built wrongly author->id and author_id differs.\n"
            ."label->author->id: ".$self->author->id.", label->author_id: ".$self->author_id;
        }
        if($self->team->id != $self->team_id){
            die "Label has been built wrongly team->id and team_id differs.\n"
            ."label->team->id: ".$self->team->id.", label->team_id: ".$self->team_id;
        }
    }
    return 1;
}
####################################################################################
sub toString {
    my $self = shift;
    my $str  = $self->freeze;
    $str .= "\n\t (TEAM OBJ): " . $self->team->id if defined $self->team;
    $str .= "\n\t (AUTHOR OBJ): " . $self->author->id
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
    if (    $self->team
        and $self->author
        and $obj->team
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

    #<<<
    # Remeber to use 'and' properly!!
    # ---------------------------------------------------------
    # $this && $that   |    If $this is true, return $that,          
    # $this and $that  |    else return $this.
    # -----------------+---------------------------------------
    # $this || $that   |    If $this is true, return $this,
    # $this or $that   |    else return $that.
    # ---------------------------------------------------------

    # my $result; 
    # $result = 1==1 and 5==6; # gives 1!!!
    # say      "1==1 and 5==6: ".$result;

    # $result =  5==6 and 1==1; # gives undef - as expected
    # say       "5==6 and 1==1: ".$result;

    # $result = (1==1 and 5==6); # gives undef! - as expected
    # say      "(1==1 and 5==6): ".$result;

    # $result = (1==1) and (5==6); # gives 1!!!
    # say      "(1==1) and (5==6): ".$result;

    # $result = ((1==1) and (5==6)); # gives undef - as expected
    # say      "((1==1) and (5==6)): ".$result;

    # $result = ((5==6) and (1==1)); # gives undef - as expected
    # say      "((5==6) and (1==1)): ".$result;
    #>>>

# this is wrong!!
# return ( $self->{team_id} == $obj->{team_id} && $self->{team_id} == $obj->{team_id} );

    # this is correct
    return 0 if $self->{team_id} != $obj->{team_id};
    return 0 if $self->{author_id} != $obj->{author_id};
    return 1;
}
####################################################################################
sub equals_obj {
    my $self = shift;
    my $obj  = shift;

    return 0 if !$self->{team}->equals( $obj->{team} );
    return 0 if !$self->{author}->equals( $obj->{author} );
    return 1;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
