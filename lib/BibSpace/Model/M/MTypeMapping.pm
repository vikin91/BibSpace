package MTypeMapping;

use Moose;
use BibSpace::Model::M::MTypeMappingMySQL;
extends 'MTypeMappingMySQL';

no Moose;
__PACKAGE__->meta->make_immutable;
1;
