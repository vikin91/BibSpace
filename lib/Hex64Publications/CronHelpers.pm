package Hex64Publications::CronHelpers;

use utf8;
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010; #because of ~~
use strict;
use warnings;
use DBI;
use File::Copy qw(copy);

use Hex64Publications::Core;
use Hex64Publications::Set;
use Hex64Publications::Publications;
use Hex64Publications::BackupFunctions;

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

        my $sth = $dbh->prepare( "SELECT DISTINCT id FROM Entry WHERE need_html_regen = 1" );  
        $sth->execute(); 

        my @ids;

        while(my $row = $sth->fetchrow_hashref()) {
            my $eid = $row->{id};
            push @ids, $eid if defined $eid;
        }
        for my $id (@ids){
           generate_html_for_id($dbh, $id);
           # $self->write_log("HTML regen from helper  for eid $id");
        }
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
