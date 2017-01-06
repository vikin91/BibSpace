package MAuthor;

use Moose;
use BibSpace::Model::MAuthorMySQL;
extends 'MAuthorMySQL';

no Moose;
__PACKAGE__->meta->make_immutable;
1;
