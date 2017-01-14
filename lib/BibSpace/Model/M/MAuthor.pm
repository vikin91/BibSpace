package MAuthor;

use Moose;
use BibSpace::Model::M::MAuthorMySQL;
extends 'MAuthorMySQL';

no Moose;
__PACKAGE__->meta->make_immutable;
1;
