package BibSpace::Controller::Set;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010;           #because of ~~
use strict;
use warnings;
use DBI;

use BibSpace::Controller::Core;
use BibSpace::Model::MTeam;

use BibSpace::Functions::FSet
    ;  # the functions that do not rely on controller should be exported there

use Set::Scalar;

use Exporter;
our @ISA = qw( Exporter );

our @EXPORT = qw(
    get_set_of_papers_for_author_id
    get_set_of_authors_for_team
    get_set_of_papers_for_all_authors_of_team_id
    get_set_of_papers_for_team
    
    get_set_of_tagged_papers
    get_set_of_teams_for_author_id
    get_set_of_teams_for_author_id_w_year
    get_set_of_teams_for_entry_id
    get_set_of_all_team_ids
    get_set_of_papers_with_exceptions
);

####################################################################################

sub get_set_of_all_team_ids {
    my $dbh = shift;
    return Fget_set_of_all_team_ids($dbh);
}
####################################################################################

sub get_set_of_papers_for_team {
    my $self = shift;
    my $tid  = shift;
    my $dbh  = $self->app->db;

    return Fget_set_of_papers_for_team( $dbh, $tid );
}

####################################################################################

sub get_set_of_papers_with_exceptions {
    my $self = shift;
    return Fget_set_of_papers_with_exceptions( $self->app->db );
}

####################################################################################

sub get_set_of_tagged_papers {
    my $self = shift;
    return Fget_set_of_tagged_papers( $self->app->db );
}
####################################################################################

# sub get_set_of_papers_with_no_tags {
#     my $self = shift;
#     return Fget_set_of_papers_with_no_tags( $self->app->db );
# }

####################################################################################

sub get_set_of_papers_for_all_authors_of_team_id {
    my $self = shift;
    my $tid  = shift;

    return Fget_set_of_papers_for_all_authors_of_team_id( $self->app->db,
        $tid );
}
####################################################################################

sub get_set_of_teams_for_author_id_w_year {
    my $self = shift;
    my $aid  = shift;
    my $year = shift;

    return Fget_set_of_teams_for_author_id_w_year( $self->app->db, $aid, $year );
}
####################################################################################

sub get_set_of_teams_for_author_id {
    my $self = shift;
    my $aid  = shift;

    return Fget_set_of_teams_for_author_id( $self->app->db, $aid );
}
####################################################################################

sub get_set_of_authors_for_entry_id {
    my $self = shift;
    my $eid  = shift;

    return Fget_set_of_authors_for_entry_id( $self->app->db, $eid );
}
####################################################################################
sub get_set_of_teams_for_entry_id {
    my $self = shift;
    my $eid  = shift;

    return Fget_set_of_teams_for_entry_id( $self->app->db, $eid );
}

1;
