package Menry::Controller::CronHelpers;

use utf8;
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010; #because of ~~
use strict;
use warnings;
use DBI;
use File::Copy qw(copy);

use Menry::Controller::Core;
use Menry::Controller::Set;
use Menry::Controller::Publications;
use Menry::Functions::PublicationsFunctions;
use Menry::Functions::BackupFunctions;

use base 'Mojolicious::Plugin';
sub register {

	my ($self, $app) = @_;

        # TODO: Move all implementations to a separate files to avoid code redundancy! Here only function calls should be present, not theirs implementation
        # helper_do_mysql_backup_current_state is a positive example
        # helper_regenerate_html_for_all is a negative example

    $app->helper(helper_do_mysql_backup_current_state => sub {
        my $self = shift;
        my $fname_prefix = shift || "normal";
        return do_mysql_db_backup($self, $fname_prefix);
    });

    $app->helper(helper_regenerate_html_for_all => sub {
        my $self = shift;
        my $dbh = $self->app->db;
        generate_html_for_all_need_regen($dbh);
    });

    $app->helper(helper_do_delete_broken_or_old_backup => sub {
        my $self = shift;
        do_delete_broken_or_old_backup($self);
    });
    

    

    $app->helper(helper_reassign_papers_to_authors => sub {
        my $self = shift;
        postprocess_all_entries_after_author_uids_change($self);
    });

    $app->helper(helper_reassign_papers_to_authors_and_create_authors => sub {
        my $self = shift;
        postprocess_all_entries_after_author_uids_change_w_creating_authors($self);
    });

    

    $app->helper(helper_clean_ugly_bibtex_fileds_for_all_entries => sub {
        my $self = shift;
        clean_ugly_bibtex_fileds_for_all_entries($self);
    });

    

}

1;
