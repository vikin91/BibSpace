package MEntry;



use Moose;
use BibSpace::Model::MEntryMySQL;
extends 'MEntryMySQL';

no Moose;
__PACKAGE__->meta->make_immutable;
1;
