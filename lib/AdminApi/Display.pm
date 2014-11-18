package AdminApi::Display;

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

our $db_name = "sensor.db";

sub index {
  my $self = shift;
   # create_view();

   $self->render(template => 'display/start');
 }
#################################################################################
sub test500 {
    my $self = shift;
    $self->render(text => 'Oops.', status => 500);
}
sub test404 {
    my $self = shift;
    $self->render(text => 'Oops.', status => 404);
}
#################################################################################
sub show_log {
    my $self = shift;
    my $num = $self->param('num');
    my $back_url = $self->param('back_url') || '/';

    $num = 100 unless $num;

    my @lines = read_file('log/my.log');
    # @lines = reverse(@lines);
    @lines = @lines[ $#lines-$num .. $#lines ];
    chomp(@lines);

    $self->stash(lines => \@lines, back_url => $back_url);
    $self->render(template => 'display/log');
}

#################################################################################

sub prepare_private_db{

	my $pdbh = DBI->connect('dbi:SQLite:dbname='.$db_name, '', '') or die $DBI::errstr;
	
	$pdbh->do("CREATE TABLE IF NOT EXISTS Sensor(
      	id INTEGER PRIMARY KEY,
      	alarm INTEGR DEFAULT 0,
      	timestamp INTEGER,
      	zwave_timestamp INTEGER,
      	temp REAL,
      	temp_ut INTEGER,
      	temp_it INTEGER,
      	water INTEGER,
      	water_ut INTEGER,
      	water_it INTEGER,
		tilt INTEGER,
		tilt_ut INTEGER,
		tilt_it INTEGER,
		last_wakeup INTEGER
    )");

    $pdbh->disconnect();
}



sub private{
	my $self = shift;

	# my $now_date = localtime($self->param('now'))->strftime('%F %T');
	# my $tt = $self->param('tt');
	# my $ttu_date = localtime($self->param('ttu'))->strftime('%F %T');
	# my $tti_date = localtime($self->param('tti'))->strftime('%F %T');
	# my $wa = $self->param('wa');
	# my $wau_date = localtime($self->param('wau'))->strftime('%F %T');
	# my $wai_date = localtime($self->param('wai'))->strftime('%F %T');
	# my $ti = $self->param('ti');
	# my $tiu_date = localtime($self->param('tiu'))->strftime('%F %T');
	# my $tii_date = localtime($self->param('tii'))->strftime('%F %T');
	prepare_private_db();

	my $now = $self->param('now');
	my $tt = $self->param('tt');
	my $ttu = $self->param('ttu');
	my $tti = $self->param('tti');
	my $wa = $self->param('wa');
	my $wau = $self->param('wau');
	my $wai = $self->param('wai');
	my $ti = $self->param('ti');
	my $tiu = $self->param('tiu');
	my $tii = $self->param('tii');
	my $lw = $self->param('lw');

	$tt *= 100;
	$tt =~ s/\./_/g;
	# my @temp = split('_', $tt);

	# $tt = $temp[0];

	my $pdbh = DBI->connect('dbi:SQLite:dbname='.$db_name, '', '') or die $DBI::errstr;

	my $prow = get_recent_row($pdbh);

	my $sth = $pdbh->prepare("INSERT INTO Sensor(timestamp, zwave_timestamp, temp, temp_ut, temp_it, water, water_ut, water_it, tilt, tilt_ut, tilt_it, last_wakeup)
	 						VALUES (datetime('now','localtime'), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )");
    $sth->execute($now, $tt, $ttu, $tti, $wa, $wau, $wai, $ti, $tiu, $tii, $lw);

    my $crow = get_recent_row($pdbh);

    my $alm_level = 0;

	if(change_reported($prow, $crow) == 1){
		$alm_level = 1;
		$self->write_log("PRIVATE: FOUND CHANGE by timestamp: $now");
	}
	if($crow->{zwave_timestamp} - $crow->{water_ut} < 600){
		$alm_level = 2;    
		$self->write_log("!!!! WATER change in the last 10 minutes !!!!! PRIVATE: FOUND CHANGE by timestamp: $now");
	}
	if($wa==255){
		$alm_level = 3;    
		$self->write_log("!!!! WATER - sensor is swimming in WATER !!!!! PRIVATE: FOUND CHANGE by timestamp: $now");
	}

	my $sth2 = $pdbh->prepare("UPDATE Sensor SET alarm=? WHERE zwave_timestamp = ?");
	$sth2->execute($alm_level, $now);
	
    

	$pdbh->disconnect();

	$self->render(text => "OK");
}


sub private_read{
	my $self = shift;
	my $num = $self->param('num') || undef;

	prepare_private_db();

	my $pdbh = DBI->connect('dbi:SQLite:dbname='.$db_name, '', '') or die $DBI::errstr;

	my $qry = "SELECT alarm, timestamp, zwave_timestamp, temp, temp_ut, temp_it, water, water_ut, water_it, tilt, tilt_ut, tilt_it, last_wakeup 
							FROM Sensor
							ORDER BY timestamp DESC";
	

	if( defined $num and $num > 0){
		$qry .= " LIMIT $num";
	}

	my $sth = $pdbh->prepare($qry);
    $sth->execute();
	

	my @rr;
	while(my $row = $sth->fetchrow_hashref()) {
		push @rr, $row;
	}

	$pdbh->disconnect();

	$self->stash(rr => \@rr);
    $self->render(template => 'display/sensor');
}

sub private_read_alm{
	my $self = shift;
	my $lvl = $self->param('num') || 0;

	prepare_private_db();

	my $pdbh = DBI->connect('dbi:SQLite:dbname='.$db_name, '', '') or die $DBI::errstr;

	my $qry = "SELECT alarm, timestamp, zwave_timestamp, temp, temp_ut, temp_it, water, water_ut, water_it, tilt, tilt_ut, tilt_it, last_wakeup 
							FROM Sensor
							WHERE alarm >= ?
							ORDER BY timestamp DESC";
	

	my $sth = $pdbh->prepare($qry);
    $sth->execute($lvl);
	

	my @rr;
	while(my $row = $sth->fetchrow_hashref()) {
		push @rr, $row;
	}

	$pdbh->disconnect();

	$self->stash(rr => \@rr);
    $self->render(template => 'display/sensor');
}


sub get_recent_row{
	my $pdbh = shift;
	

	my $qry = "SELECT timestamp, zwave_timestamp, temp, temp_ut, temp_it, water, water_ut, water_it, tilt, tilt_ut, tilt_it, last_wakeup 
							FROM Sensor
							ORDER BY timestamp DESC
							LIMIT 1";

	my $sth = $pdbh->prepare($qry);
    $sth->execute();
	
	my $row = $sth->fetchrow_hashref();
	$sth->finish();
	return $row;
}

sub change_reported{
	my $r1 = shift;
	my $r2 = shift;

	if(defined $r1 and defined $r2){

		if($r1->{tilt_ut} ne $r2->{tilt_ut} or $r1->{water_ut} ne $r2->{water_ut} or $r1->{temp_ut} ne $r2->{temp_ut}){
			return 1;
		}
		if($r1->{tilt_it} ne $r2->{tilt_it} or $r1->{water_it} ne $r2->{water_it} or $r1->{temp_it} ne $r2->{temp_it}){
			return 1;
		}
	}
	return 0;
}



1;