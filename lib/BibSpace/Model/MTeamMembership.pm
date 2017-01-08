package MTeamMembership;


use Moose;
use BibSpace::Model::MTeamMembershipMySQL;
extends 'MTeamMembershipMySQL';

no Moose;
__PACKAGE__->meta->make_immutable;
1;
