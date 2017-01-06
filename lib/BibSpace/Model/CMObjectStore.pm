package CMObjectStore;


use strict;
use warnings;

use BibSpace::Model::MUser;
use BibSpace::Model::MEntry;
use BibSpace::Model::MTag;
use BibSpace::Model::MAuthor;
use BibSpace::Model::MTeam;

use Moose;
use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');

has 'entries' => (is => 'rw', isa => 'ArrayRef[MEntry]');
has 'authors' => (is => 'rw', isa => 'ArrayRef[MAuthor]');
has 'tags'    => (is => 'rw', isa => 'ArrayRef[MTag]');


####################################################################################################
sub loadData {
    my $self = shift;
    my $dbh = shift;

    my @allEntries = MEntry->static_all($dbh);
    my @allAuthors = MAuthor->static_all($dbh);
    my @allTags    = MTag->static_all($dbh);

    # push @{ $self->storage }, @allEntries;
    $self->entries( \@allEntries );
    $self->authors( \@allAuthors );
    $self->tags( \@allTags );
}
####################################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
