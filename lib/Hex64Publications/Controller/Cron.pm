package Hex64Publications::Controller::Cron;
use Hex64Publications::Controller::DB;


use Data::Dumper;
use utf8;
use Text::BibTeX; # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010; #because of ~~
use strict;
use warnings;
use DBI;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::UserAgent;

# crontab -e
# 0 4,12,20 * * * curl http://146.185.144.116:8080/cron/day
# 0 2 * * * curl http://146.185.144.116:8080/cron/night
# 5 2 * * 0 curl http://146.185.144.116:8080/cron/week
# 10 2 1 * * curl http://146.185.144.116:8080/cron/month

##########################################################################################
sub index {
	my $self = shift;
    my $dbh = $self->app->db;
	
	prepare_cron_table($dbh);
    $self->render(template => 'display/cron', 
        lr_0 => get_last_cron_run_in_hours($dbh, 0), 
        lr_1 => get_last_cron_run_in_hours($dbh, 1), 
        lr_2 => get_last_cron_run_in_hours($dbh, 2), 
        lr_3 => get_last_cron_run_in_hours($dbh, 3)
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
sub cron_day {
    my $self = shift;
    my $level = 0;
    my $call_freq = $self->config->{cron_day_freq_lock};

    my $last_call = get_last_cron_run_in_hours($self->app->db, $level);
    my $left = $call_freq - $last_call;
    $self->render(text => "Cron day called too often. Last call $last_call hours ago. Come back in $left hours\n") if $last_call < $call_freq and $last_call > -1;
    return if $last_call < $call_freq and $last_call > -1;
    
    log_cron_usage($self->app->db, $level);
    $self->write_log("Cron day started");
    
    ############ CRON ACTIONS
    $self->helper_do_mysql_backup_current_state("cron");
    ############ CRON ACTIONS STOP

    $self->write_log("Cron day finished");
    $self->render(text => "Cron day here\n");
}

##########################################################################################
sub cron_night {
    my $self = shift;
    my $level = 1;
    my $call_freq = $self->config->{cron_night_freq_lock};

    my $last_call = get_last_cron_run_in_hours($self->app->db, $level);
    my $left = $call_freq - $last_call;
    $self->render(text => "Cron night called too often. Last call $last_call hours ago. Come back in $left hours\n") if $last_call < $call_freq and $last_call > -1;
    return if $last_call < $call_freq and $last_call > -1;

    log_cron_usage($self->app->db, $level);
    $self->write_log("Cron night started");

    ############ CRON ACTIONS
    $self->helper_regenerate_html_for_all();
    ############ CRON ACTIONS STOP

    $self->write_log("Cron night finished");
    $self->render(text => "Cron night here\n");
}
##########################################################################################
sub cron_week {
    my $self = shift;
    my $level = 2;
    my $call_freq = $self->config->{cron_week_freq_lock};

    my $last_call = get_last_cron_run_in_hours($self->app->db, $level);
    my $left = $call_freq - $last_call;
    $self->render(text => "Cron week called too often. Last call $last_call hours ago. Come back in $left hours\n") if $last_call < $call_freq and $last_call > -1;
    return if $last_call < $call_freq and $last_call > -1;

    log_cron_usage($self->app->db, $level);
    $self->write_log("Cron week started");

    ############ CRON ACTIONS 
    # $self->helper_reassign_papers_to_authors();  #can be anbled later
    # $self->helper_clean_ugly_bibtex_fileds_for_all_entries(); #can be enabled later
    $self->helper_do_delete_broken_or_old_backup();
    ############ CRON ACTIONS STOP
    
    $self->write_log("Cron week finished");
    $self->render(text => "Cron week here\n");
}
##########################################################################################
sub cron_month {
    my $self = shift;
    my $level = 3;
    my $call_freq = $self->config->{cron_month_freq_lock};

    my $last_call = get_last_cron_run_in_hours($self->app->db, $level);
    my $left = $call_freq - $last_call;
    $self->render(text => "Cron month called too often. Last call $last_call hours ago. Come back in $left hours\n") if $last_call < $call_freq and $last_call > -1;
    return if $last_call < $call_freq and $last_call > -1;

    log_cron_usage($self->app->db, $level);
    $self->write_log("Cron month started");

    ############ CRON ACTIONS
    $self->helper_do_delete_broken_or_old_backup();
    ############ CRON ACTIONS STOP

    $self->write_log("Cron month finished");
    $self->render(text => "Cron month here\n");
}




##########################################################################################
sub log_cron_usage{
    my $dbh = shift;
    my $level = shift;

    prepare_cron_table($dbh);
    my $sth = $dbh->prepare( "REPLACE INTO CRON (type) VALUES (?)" );  
    $sth->execute($level);
};
##########################################################################################
sub get_last_cron_run_in_hours{
    my $dbh = shift;
    my $level = shift;
    prepare_cron_table($dbh);

    my $sth = $dbh->prepare("SELECT ABS(TIMESTAMPDIFF(HOUR, CURRENT_TIMESTAMP, last_run_time)) as age FROM Cron WHERE type=?");
    $sth->execute($level);
    my $row = $sth->fetchrow_hashref();

    my $ret = -1;
    $ret = $row->{age} if $row->{age} >= 0;
    return $ret;

};

##########################################################################################
1;