package MAuthorMySQL2;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use 5.010;           # because of ~~ and say
use DBI;
use Try::Tiny;
use Devel::StackTrace;

use BibSpace::Model::MAuthorBase;
use BibSpace::Model::Persistent;
use BibSpace::Model::StorageBase;

use Moose;
with 'Persistent';

has object => (
    is => 'ro',
    isa => 'MAuthorBase',
    default => sub {
        MAuthorBase->new(@_)
    }
);
# In your test:

# my $request = Test::MockObject->new;
# $request->mock(…);
# my $tested_class = MyClass->new(request => $request, ...);


# or maybe I should Inject the SQL classes into *Base?
# Then, an SQL class (thet e.g. implements interface persistable) would provide methods for persistence
# and the logic when to save an object would be placed in the base... this might be better than the idea above!


####################################################################################
sub load {
    my $self = shift;
    my $dbh  = shift;
    my $storage  = shift; # dependency injection

    # my @authorMemberships = $self->load_memberships($dbh); # authors from DB
    # # in case there is a mess in DB
    # @authorMemberships = grep { defined $_->team_id and defined $_->author_id } @authorMemberships;
    # @authorMemberships = map {$_->replaceFromStorage($storage) } @authorMemberships;
    # map { $_->load($dbh, $storage) } @authorMemberships;
    # $self->bteamMemberships( [ @authorMemberships ] );
    

    # # now, there are teams loaded from storage
    # my @myTeams = map{ $_->team } grep { defined $_->team } $self->teamMemberships_all;
    # $self->bteams( [ @myTeams ] );
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
