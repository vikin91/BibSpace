# package CMObjectStore;


# use strict;
# use warnings;

# use BibSpace::Model::MUser;
# use BibSpace::Model::MEntry;
# use BibSpace::Model::MTag;
# use BibSpace::Model::MAuthor;
# use BibSpace::Model::MTeam;

# use Moose;
# use MooseX::Storage;
# with Storage( 'format' => 'JSON', 'io' => 'File' );

# has 'entries' => (
#     is      => 'rw',
#     isa     => 'ArrayRef[MEntry]',
#     traits  => ['Array'],
#     default => sub { [] },
#     handles => {
#         entries_all    => 'elements',
#         entries_add    => 'push',
#         entries_map    => 'map',
#         entries_filter => 'grep',
#         entries_find   => 'first',
#         entries_get    => 'get',
#         entries_join   => 'join',
#         entries_count  => 'count',
#         entries_has    => 'count',
#         entries_has_no => 'is_empty',
#         entries_sorted => 'sort',
#     },
# );

# has 'authors' => (
#     is      => 'rw',
#     isa     => 'ArrayRef[MAuthor]',
#     traits  => ['Array'],
#     default => sub { [] },
#     handles => {
#         authors_all        => 'elements',
#         authors_add        => 'push',
#         authors_map        => 'map',
#         authors_filter     => 'grep',
#         authors_find       => 'first',
#         authors_find_index => 'first_index',
#         authors_delete     => 'delete',
#         authors_clear      => 'clear',
#         authors_get        => 'get',
#         authors_insert_at  => 'set',
#         authors_join       => 'join',
#         authors_count      => 'count',
#         authors_has        => 'count',
#         authors_has_no     => 'is_empty',
#         authors_sorted     => 'sort',
#     },
# );
# has 'tags' => (
#     is      => 'rw',
#     isa     => 'ArrayRef[MTag]',
#     traits  => ['Array'],
#     default => sub { [] },
#     handles => {
#         tags_all        => 'elements',
#         tags_add        => 'push',
#         tags_map        => 'map',
#         tags_filter     => 'grep',
#         tags_find       => 'first',
#         tags_get        => 'get',
#         tags_find_index => 'first_index',
#         tags_delete     => 'delete',
#         tags_clear      => 'clear',
#         tags_join       => 'join',
#         tags_count      => 'count',
#         tags_has        => 'count',
#         tags_has_no     => 'is_empty',
#         tags_sorted     => 'sort',
#     },
# );

# has 'teams' => (
#     is      => 'rw',
#     isa     => 'ArrayRef[MTeam]',
#     traits  => ['Array'],
#     default => sub { [] },
#     handles => {
#         teams_all        => 'elements',
#         teams_add        => 'push',
#         teams_map        => 'map',
#         teams_filter     => 'grep',
#         teams_find       => 'first',
#         teams_get        => 'get',
#         teams_find_index => 'first_index',
#         teams_delete     => 'delete',
#         teams_clear      => 'clear',
#         teams_join       => 'join',
#         teams_count      => 'count',
#         teams_has        => 'count',
#         teams_has_no     => 'is_empty',
#         teams_sorted     => 'sort',
#     },
# );

# ####################################################################################################
# sub deleteObj {
#     my $self = shift;
#     my $obj = shift;

#     if( !blessed( $obj ) ){
#         warn "Object not blessed!";
#         return 0;
#     }
#     if($obj->isa("MEntry") ){
#         my $index = $self->entries_find_index(
#             sub {
#                 defined $_->{id} and defined $obj->{id} and $_->{id} eq $obj->{id};
#             }
#         );
#         $self->entries_delete($index) if $index > -1;
#         return 1 if $index > -1;
#     }
#     elsif( $obj->isa("MAuthor") ){
#         my $index = $self->authors_find_index(
#             sub {
#                 defined $_->{id} and defined $obj->{id} and $_->{id} eq $obj->{id};
#             }
#         );
#         $self->authors_delete($index) if $index > -1;
#         return 1 if $index > -1;
#     }
#     elsif( $obj->isa("MTeam") ){
#         my $index = $self->teams_find_index(
#             sub {
#                 defined $_->{id} and defined $obj->{id} and $_->{id} eq $obj->{id};
#             }
#         );
#         $self->teams_delete($index) if $index > -1;
#         return 1 if $index > -1;
#     }
#     elsif( $obj->isa("MTag") ){
#         my $index = $self->tags_find_index(
#             sub {
#                 defined $_->{id} and defined $obj->{id} and $_->{id} eq $obj->{id};
#             }
#         );
#         $self->tags_delete($index) if $index > -1;
#         return 1 if $index > -1;
#     }
#     else{
#         warn "I dont know how to delete ".$obj;
#         return 0;
#     }
# }

# ####################################################################################################
# sub loadData {
#     my $self = shift;
#     my $dbh  = shift;

#     warn "CMObjectStore is loading data from DB...";

#     my @allEntries = MEntry->static_all($dbh);
#     my @allAuthors = MAuthor->static_all($dbh);
#     my @allTags    = MTag->static_all($dbh);
#     my @allTeams   = MTeam->static_all($dbh);

#     map { $_->load($dbh) } @allEntries;
#     map { $_->load($dbh) } @allAuthors;
#     map { $_->load($dbh) } @allTags;

#     # map { $_->load($dbh) } @allTeams;

#     # push @{ $self->storage }, @allEntries;
#     $self->entries( \@allEntries );
#     $self->authors( \@allAuthors );
#     $self->tags( \@allTags );
#     $self->teams( \@allTeams );
# }
# ####################################################################################################
# no Moose;
# __PACKAGE__->meta->make_immutable;
# 1;
