package AdminApi::Cron;

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
    my $backup_dbh = $self->backup_db;
	
	prepare_cron_table($backup_dbh);
    $self->render(template => 'display/cron', 
        lr_0 => get_last_cron_run_in_hours($self->backup_db, 0), 
        lr_1 => get_last_cron_run_in_hours($self->backup_db, 1), 
        lr_2 => get_last_cron_run_in_hours($self->backup_db, 2), 
        lr_3 => get_last_cron_run_in_hours($self->backup_db, 3)
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
    my $call_freq = 2;

    my $last_call = get_last_cron_run_in_hours($self->backup_db, $level);
    my $left = $call_freq - $last_call;
    $self->render(text => "Cron day called too often. Last call $last_call hours ago. Come back in $left hours\n") if $last_call < $call_freq and $last_call > -1;
    return if $last_call < $call_freq and $last_call > -1;
    
    log_cron_usage($self->backup_db, $level);
    $self->write_log("Cron day started");
    
    ############ CRON ACTIONS
    $self->helper_do_backup_current_state("cron");
    ############ CRON ACTIONS STOP

    $self->write_log("Cron day finished");
    $self->render(text => "Cron day here\n");
}

##########################################################################################
sub cron_night {
    my $self = shift;
    my $level = 1;
    my $call_freq = 12;

    my $last_call = get_last_cron_run_in_hours($self->backup_db, $level);
    my $left = $call_freq - $last_call;
    $self->render(text => "Cron night called too often. Last call $last_call hours ago. Come back in $left hours\n") if $last_call < $call_freq and $last_call > -1;
    return if $last_call < $call_freq and $last_call > -1;

    log_cron_usage($self->backup_db, $level);
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
    my $call_freq = 144;

    my $last_call = get_last_cron_run_in_hours($self->backup_db, $level);
    my $left = $call_freq - $last_call;
    $self->render(text => "Cron week called too often. Last call $last_call hours ago. Come back in $left hours\n") if $last_call < $call_freq and $last_call > -1;
    return if $last_call < $call_freq and $last_call > -1;

    log_cron_usage($self->backup_db, $level);
    $self->write_log("Cron week started");

    ############ CRON ACTIONS 
    $self->helper_reassign_papers_to_authors();
    $self->helper_clean_ugly_bibtex_fileds_for_all_entries();
    $self->helper_do_delete_broken_or_old_backup();
    ############ CRON ACTIONS STOP
    
    $self->write_log("Cron week finished");
    $self->render(text => "Cron week here\n");
}
##########################################################################################
sub cron_month {
    my $self = shift;
    my $level = 3;
    my $call_freq = 648;

    my $last_call = get_last_cron_run_in_hours($self->backup_db, $level);
    my $left = $call_freq - $last_call;
    $self->render(text => "Cron month called too often. Last call $last_call hours ago. Come back in $left hours\n") if $last_call < $call_freq and $last_call > -1;
    #return if $last_call < $call_freq and $last_call > -1;

    log_cron_usage($self->backup_db, $level);
    $self->write_log("Cron month started");

    ############ CRON ACTIONS
    $self->helper_do_delete_broken_or_old_backup();
    ############ CRON ACTIONS STOP

    $self->write_log("Cron month finished");
    $self->render(text => "Cron month here\n");
}




##########################################################################################
sub log_cron_usage{
    my $backup_dbh = shift;
    my $level = shift;

    prepare_cron_table($backup_dbh);
    my $sth = $backup_dbh->prepare( "REPLACE INTO CRON (type) VALUES (?)" );  
    $sth->execute($level);
};
##########################################################################################
sub get_last_cron_run_in_hours{
    my $backup_dbh = shift;
    my $level = shift;

    prepare_cron_table($backup_dbh);

    my $sth = $backup_dbh->prepare("SELECT (strftime('%s', datetime('now', 'localtime')) - strftime('%s', last_run_time))/3600 as age FROM Cron WHERE type=?");
    $sth->execute($level);
    my $row = $sth->fetchrow_hashref();
    my $age = $row->{age}; 
    return -1 if !defined $age;
    return $age;
    
};
##########################################################################################
sub prepare_cron_table{
   my $backup_dbh = shift;

    $backup_dbh->do("CREATE TABLE IF NOT EXISTS Cron(
      type INTEGER PRIMARY KEY,
      last_run_time INTEGER DEFAULT (datetime('now','localtime'))
      )");

    $backup_dbh->do("INSERT OR IGNORE INTO CRON (type) VALUES (0)");
    $backup_dbh->do("INSERT OR IGNORE INTO CRON (type) VALUES (1)");
    $backup_dbh->do("INSERT OR IGNORE INTO CRON (type) VALUES (2)");
    $backup_dbh->do("INSERT OR IGNORE INTO CRON (type) VALUES (3)");
};
##########################################################################################
1;