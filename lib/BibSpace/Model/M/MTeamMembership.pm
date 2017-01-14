package MTeamMembership;


use Moose;
use BibSpace::Model::M::MTeamMembershipMySQL;
extends 'MTeamMembershipMySQL';

no Moose;
__PACKAGE__->meta->make_immutable;
1;
