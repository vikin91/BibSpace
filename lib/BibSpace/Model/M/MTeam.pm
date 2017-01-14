package MTeam;

use Moose;
use BibSpace::Model::M::MTeamMySQL;
extends 'MTeamMySQL';

no Moose;
__PACKAGE__->meta->make_immutable;
1;
