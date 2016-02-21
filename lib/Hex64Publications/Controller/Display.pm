package Hex64Publications::Controller::Display;

use Data::Dumper;
use utf8;
use Text::BibTeX; # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';


sub index {
  my $self = shift;
   # create_view();

   $self->render(template => 'display/start');
 }
#################################################################################
sub test500 {
    my $self = shift;
    $self->render(text => 'Oops 500.', status => 500);
}
#################################################################################
sub test404 {
    my $self = shift;
    $self->render(text => 'Oops 404.', status => 404);
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

1;