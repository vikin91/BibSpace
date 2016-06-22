package BibSpace::Controller::CronHelpers;

use strict;
use warnings;
use utf8;
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010;    #because of ~~

use DBI;
use File::Copy qw(copy);

use BibSpace::Controller::Core;
use BibSpace::Controller::Set;
use BibSpace::Controller::Publications;
use BibSpace::Controller::BackupFunctions;

use BibSpace::Functions::FPublications;

use base 'Mojolicious::Plugin';

sub register {

    my ( $self, $app ) = @_;

    $app->helper(
        helper_do_mysql_backup_current_state => sub {
            my $self = shift;
            my $fname_prefix = shift || "normal";
            return do_mysql_db_backup( $self, $fname_prefix );
        }
    );

    $app->helper(
        helper_do_delete_broken_or_old_backup => sub {
            my $self = shift;
            do_delete_broken_or_old_backup($self);
        }
    );

    $app->helper(
        helper_reassign_papers_to_authors => sub {
            my $self = shift;
            postprocess_all_entries_after_author_uids_change($self);
        }
    );

    $app->helper(
        helper_reassign_papers_to_authors_and_create_authors => sub {
            my $self = shift;
            postprocess_all_entries_after_author_uids_change_w_creating_authors(
                $self);
        }
    );

    $app->helper(
        helper_clean_ugly_bibtex_fields_for_all_entries => sub {
            my $self = shift;
            Fclean_ugly_bibtex_fields_for_all_entries( $self->app->db );
        }
    );

}

1;
