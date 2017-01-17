package Exception;

use Data::Dumper;
use utf8;
use 5.010;    #because of ~~ and say
use BibSpace::Model::Team;

use DBI;
use Try::Tiny;
use Devel::StackTrace;
use Moose;
use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );

# the fileds below are crucial, beacuse static_all has access only to team/author ids and not to objects
# MTeamMembership->load($dbh) should then fill the objects based on ids
has 'entry_id'   => ( is => 'ro', isa => 'Int' );
has 'team_id' => ( is => 'ro', isa => 'Int' );
has 'entry' => (
    is     => 'rw',
    isa    => 'Maybe[Entry]',
    traits => ['DoNotSerialize']    # due to cycyles
);
has 'team' => (
    is     => 'rw',
    isa    => 'Maybe[Team]',
    traits => ['DoNotSerialize']    # due to cycyles
);
####################################################################################
sub toString {
    my $self = shift;
    my $str  = $self->freeze;
    $str .= "\n";
    $str .= "\n\t (ENTRY): " . $self->entry->id if defined $self->entry;
    $str .= "\n\t (TEAM): " . $self->team->id
        if defined $self->team;
    $str;
}
####################################################################################

=item equals
    In case of any strange problems: this must return 1 or 0! 
=cut

sub equals {
    my $self = shift;
    my $obj  = shift;

    if (    $self->{entry}
        and $self->{team}
        and $obj->{entry}
        and $obj->{team} )
    {
        return $self->equals_obj($obj);
    }
    return $self->equals_id($obj);
}
####################################################################################
sub equals_id {
    my $self = shift;
    my $obj  = shift;
    return 0 if $self->{entry_id} != $obj->{entry_id};
    return 0 if $self->{team_id} != $obj->{team_id};
    return 1;
}
####################################################################################
sub equals_obj {
    my $self = shift;
    my $obj  = shift;
    return 0 if !$self->{entry}->equals( $obj->{entry} );
    return 0 if !$self->{team}->equals( $obj->{team} );
    return 1;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;