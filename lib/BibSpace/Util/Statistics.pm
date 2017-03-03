package Statistics;
use namespace::autoclean;

use feature qw( state say );

use Moose;
use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );

has 'url_history' => (
    traits    => ['Hash'],
    is        => 'ro',
    isa       => 'HashRef[Int]',
    default   => sub { {} },
    handles   => {
        set     => 'set',
        get     => 'get',
        has     => 'exists',
        defined => 'defined',
        keys    => 'keys',
        # values  => 'values',
        num     => 'count',
        pairs   => 'kv',
        _clear  => 'clear',
    },
);

has 'filename' =>( is => 'ro', isa => 'Str', default => "bibspace_stats.json");

sub load_maybe {
  my $self = shift;
  if ( -e $self->filename ) {
    return Statistics->load($self->filename);
  }
  return $self;
}


sub log_url {
  my $self   = shift;
  my $url    = shift;

  if( !$self->defined($url) ){
    $self->set($url, 1);
  }
  else{
    my $num = $self->get($url); 
    $self->set($url, $num+1); 
  }
  $self->store($self->filename);
}

sub toString {
  my $self   = shift;
  return join("\n", $self->toLines);
}


sub toLines {
  my $self   = shift;
  my @lines;
  my @keys = reverse sort { $self->url_history->{$a} <=> $self->url_history->{$b} } keys(%{ $self->url_history });
  foreach my $key (@keys){
    my $str;
    my $num_calls = $self->get($key);
    $str .= sprintf " %-5s ", $num_calls;
    $str .= $key;
    push @lines, $str;
  }
  return @lines;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
