package MEntry;



use Moose;
use BibSpace::Model::MEntryMySQL;
use BibSpace::Model::MEntryMySQLDirty;
extends 'MEntryMySQLDirty';

no Moose;
__PACKAGE__->meta->make_immutable;
1;
