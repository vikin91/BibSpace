package BibSpace::Controller::Cron;

use BibSpace::Functions::FDB;
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

use Mojo::Base 'Mojolicious::Controller';

# use Mojo::UserAgent;

# crontab -e
# 0 4,12,20 * * * curl http://146.185.144.116:8080/cron/day
# 0 2 * * * curl http://146.185.144.116:8080/cron/night
# 5 2 * * 0 curl http://146.185.144.116:8080/cron/week
# 10 2 1 * * curl http://146.185.144.116:8080/cron/month

##########################################################################################
sub index {
    my $self = shift;
    my $dbh  = $self->app->db;

    prepare_cron_table($dbh);
    $self->render(
        template => 'display/cron',
        lr_0     => get_last_cron_run_in_hours( $dbh, 0 ),
        lr_1     => get_last_cron_run_in_hours( $dbh, 1 ),
        lr_2     => get_last_cron_run_in_hours( $dbh, 2 ),
        lr_3     => get_last_cron_run_in_hours( $dbh, 3 )
    );
}
##########################################################################################
sub get_server_address {
    my $self = shift;

    my $str1 = $self->req->url->to_abs;
    my $str2 = $self->req->url;
    $str1 =~ s/$str2//g;
    $str1;
}
##########################################################################################
sub cron {
    my $self = shift;
    my $level_param = $self->param('level') or shift;

    my $num_level = -1;    # just in case

    $num_level = 0 if $level_param eq 'day'   or $level_param eq '0';
    $num_level = 1 if $level_param eq 'night' or $level_param eq '1';
    $num_level = 2 if $level_param eq 'week'  or $level_param eq '2';
    $num_level = 3 if $level_param eq 'month' or $level_param eq '3';

    # say "Cron level: $level_param (numeric: $num_level)";

    my $result = $self->cron_level($num_level);
    if ( $result eq "" ) {
        $self->render(
            text =>
                "Incorrect cron job level: $level_param (numeric: $num_level)",
            status => 404
        );
    }
    else {
        $self->render( text => $result, status => 200 );
    }

}
##########################################################################################
sub cron_level {
    my $self  = shift;
    my $level = shift;

    if ( !defined $level or $level < 0 or $level > 3 ) {
        return "";
    }

    my $call_freq = 999;

    if ( $level == 0 ) {
        $call_freq = $self->config->{cron_day_freq_lock};
    }
    elsif ( $level == 1 ) {
        $call_freq = $self->config->{cron_night_freq_lock};
    }
    elsif ( $level == 2 ) {
        $call_freq = $self->config->{cron_week_freq_lock};
    }
    elsif ( $level == 3 ) {
        $call_freq = $self->config->{cron_month_freq_lock};
    }
    else {
        # should never happen
    }

    my $message_string = $self->cron_run( $level, $call_freq );

    # place to debug
    return $message_string;
}
##########################################################################################
sub cron_run {
    my $self      = shift;
    my $level     = shift;
    my $call_freq = shift;

    my $last_call = get_last_cron_run_in_hours( $self->app->db, $level ) // 3;
    my $left = $call_freq - $last_call;

    my $text_to_render = "";

    ############ Cron ACTIONS
    if ( $last_call < $call_freq and $last_call > -1 ) {
        $text_to_render
            = "Cron level $level called too often. Last call $last_call hours ago. Come back in $left hours\n";
        return $text_to_render;
    }
    else {
        $text_to_render = "Cron level $level here\n";
    }

    ############ Cron ACTIONS
    log_cron_usage( $self->app->db, $level );
    $self->write_log("Cron level $level started");

    if ( $level == 0 ) {
        $self->do_cron_day();
    }
    elsif ( $level == 1 ) {
        Mojo::IOLoop->stream( $self->tx->connection )->timeout(3600);
        $self->do_cron_night();
    }
    elsif ( $level == 2 ) {
        Mojo::IOLoop->stream( $self->tx->connection )->timeout(3600);
        $self->do_cron_week();
    }
    elsif ( $level == 3 ) {
        Mojo::IOLoop->stream( $self->tx->connection )->timeout(3600);
        $self->do_cron_month();
    }
    else {
        # do nothing
    }
    $self->write_log("Cron level $level finished");

    return $text_to_render;
}
##########################################################################################
sub do_cron_day {
    my $self = shift;
    my $dbh  = $self->app->db;

    $self->helper_do_mysql_backup_current_state("cron");
}
##########################################################################################
sub do_cron_night {
    my $self = shift;
    my $dbh  = $self->app->db;

    my @entries = MEntry->static_all($dbh);
    for my $e (@entries) {
        $e->regenerate_html($dbh, 0);
    }
}
##########################################################################################
sub do_cron_week {
    my $self = shift;
    my $dbh  = $self->app->db;

# $self->helper_reassign_papers_to_authors();  #can be anbled later
# $self->helper_$self->helper_clean_ugly_bibtex_fields_for_all_entries(); #can be enabled later
    $self->helper_do_delete_broken_or_old_backup();
}
##########################################################################################
sub do_cron_month {
    my $self = shift;
    my $dbh  = $self->app->db;

# $self->helper_reassign_papers_to_authors();  #can be enabled later
# $self->helper_$self->helper_clean_ugly_bibtex_fields_for_all_entries(); #can be enabled later
}
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
sub log_cron_usage {
    my $dbh   = shift;
    my $level = shift;

    prepare_cron_table($dbh);
    my $sth = $dbh->prepare("REPLACE INTO Cron (type) VALUES (?)");
    $sth->execute($level);
}
##########################################################################################
sub get_last_cron_run_in_hours {
    my $dbh   = shift;
    my $level = shift;
    prepare_cron_table($dbh);

    my $sth
        = $dbh->prepare(
        "SELECT ABS(TIMESTAMPDIFF(HOUR, CURRENT_TIMESTAMP, last_run_time)) as age FROM Cron WHERE type=?"
        );
    $sth->execute($level);
    my $row = $sth->fetchrow_hashref();
    my $age = $row->{age};

    return $age // 0;    # returns 0 if age is undefined
}

##########################################################################################
1;
