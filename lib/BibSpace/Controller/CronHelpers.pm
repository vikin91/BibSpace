package BibSpace::Controller::CronHelpers;

use strict;
use warnings;
use utf8;
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010;    #because of ~~

use DBI;
use DBIx::Connector;
use File::Copy qw(copy);

use BibSpace::Functions::Core;
use BibSpace::Functions::MySqlBackupFunctions;

use BibSpace::Functions::FPublications;

use base 'Mojolicious::Plugin';

sub register {

    my ( $self, $app ) = @_;

    # will stay here, because do_delete_broken_or_old_backup is not refactored yet
    $app->helper(
        helper_do_delete_broken_or_old_backup => sub {
            my $self = shift;
            do_delete_broken_or_old_backup($self);
        }
    );

    # will stay here, because do_mysql_db_backup is not refactored yet
    $app->helper(
        helper_do_mysql_db_backup => sub {
            my $self = shift;
            do_mysql_db_backup($self, "cron");
        }
    );

}

1;
