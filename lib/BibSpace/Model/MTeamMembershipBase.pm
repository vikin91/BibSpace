package MTeamMembershipBase;

use Data::Dumper;
use utf8;
use BibSpace::Model::MAuthor;
use Text::BibTeX;    # parsing bib files
use 5.010;           #because of ~~ and say
use DBI;
use Moose;
use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );

has 'team'   => ( 
  is => 'rw', 
  isa => 'Maybe[MTeam]',
  traits  => ['DoNotSerialize'] # due to cycyles
);
has 'author' => ( 
  is => 'rw', 
  isa => 'Maybe[MAuthor]',
  traits  => ['DoNotSerialize'] # due to cycyles
);

# the fileds below are crucial, beacuse static_all has access only to team/author ids and not to objects
# MTeamMembership->load($dbh) should then fill the objects based on ids
has 'team_id'   => ( is => 'rw', isa => 'Int' );
has 'author_id' => ( is => 'rw', isa => 'Int' );

has 'start'  => ( is => 'rw', isa => 'Int', default => 0 );
has 'stop'   => ( is => 'rw', isa => 'Int', default => 0 );


####################################################################################
sub toString {
    my $self = shift;
    my $str = $self->freeze;
    $str .= "\n\t (TEAM OBJ): ". $self->team->id if defined $self->team;
    $str .= "\n\t (AUTHOR OBJ): ". $self->author->id if defined $self->author;
    $str;
}
####################################################################################
sub equals {
    my $self   = shift;
    my $obj    = shift;

    # return 0 unless $obj->isa("MTeamMembershipBase");
    
    my $result = $self->team->equals($obj->team) and
                    $self->author->equals($obj->author) and
                    $self->{start} == $obj->{start} and
                    $self->{stop} == $obj->{stop};

    return $result == 0;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
