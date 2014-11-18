package TagCloud;

use utf8;
use v5.16;
use Moose;

has 'count' => (is => 'rw', isa => 'Int');    # number in parenthesis
has 'url'   => (is => 'rw', isa => 'Str');    # url to click in
has 'name'  => (is => 'rw', isa => 'Str');    # name of the tag to click in

sub getHTML {
  my $self = shift;

  my $code
    = '<a href="'
    . $self->url
    . '" target="blank" class="tclink">'
    . $self->name . '</a>';
  $code .= '<span class="tctext">(' . $self->count . ')</span>';
  return $code;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
