package SimpleLogger;
use namespace::autoclean;

use feature qw( state say );
use Mojo::Log;
use Path::Tiny;
use Term::ANSIColor;
use feature qw(current_sub);
use Moose;
use BibSpace::Util::ILogger;
with 'ILogger';


# this is stored in the fixture - for tests, this must be relative path!!

has '_log_dir' => ( is => 'rw', isa => 'Maybe[Str]', reader => 'log_dir' );

sub set_log_dir {
  my ( $self, $dir ) = @_;

  $self->{_log_dir} = Path::Tiny->new($dir)->relative();

}

# # Log messages
# $log->debug('Not sure what is happening here');
# $log->info('FYI: it happened again');
# $log->warn('This might be a problem');
# $log->error('Garden variety error');
# $log->fatal('Boom');

sub log_mojo {
  my $self = shift;
  my $type = shift;    # info, warn, error, debug
  my $msg  = shift;    # text to log

  $type =~ s/warning/warn/;
  $type =~ s/LOW_LEVEL_DEBUG/debug/;

  if ( $self->log_dir ) {
    my $mojo_log = Mojo::Log->new( level => 'info' );

    my $file = Path::Tiny->new( $self->log_dir, $type . '.log' );
    $mojo_log->path($file);
    $mojo_log->emit( 'message', $type, $msg );
  }
}

sub log {
  my $self   = shift;
  my $type   = shift;               # info, warn, error, debug
  my $msg    = shift;               # text to log
  my $origin = ( caller(2) )[3];    # method from where the msg originates

  $self->log_mojo( lc($type), $msg );

  my $time = localtime;
  print "[$time] $type: $msg (Origin: $origin).";
  print color('reset');
  print "\n";
}

sub debug {
  my $self   = shift;
  my $msg    = shift;
  my $origin = ( caller(2) )[3];
  print color('bright_blue');
  $self->log( 'DEBUG', $msg, $origin );
}

sub lowdebug {
  my $self   = shift;
  my $msg    = shift;
  my $origin = ( caller(2) )[3];

  # $self->log( 'LOW_LEVEL_DEBUG', $msg, $origin );
}

sub entering {
  my $self   = shift;
  my $msg    = shift;
  my $origin = ( caller(2) )[3];

  # print color('black on_yellow');
  # $self->log('ENTER', $msg, $origin);
}

sub exiting {
  my $self   = shift;
  my $msg    = shift;
  my $origin = ( caller(2) )[3];

  # print color('black on_yellow');
  # $self->log('EXIT', $msg, $origin);
}

sub info {
  my $self   = shift;
  my $msg    = shift;
  my $origin = ( caller(2) )[3];
  print color('yellow on_blue');
  $self->log( 'INFO', $msg, $origin );
}

sub warn {
  my $self   = shift;
  my $msg    = shift;
  my $origin = ( caller(2) )[3];
  print color('black on_yellow');
  $self->log( 'WARNING', $msg, $origin );
}

sub error {
  my $self   = shift;
  my $msg    = shift;
  my $origin = ( caller(2) )[3];
  print color('bright_red');
  $self->log( 'ERROR', $msg, $origin );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
