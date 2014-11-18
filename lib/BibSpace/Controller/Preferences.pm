package BibSpace::Controller::Preferences;

use strict;
use warnings;
use utf8;
use v5.16;    #because of ~~

# use File::Slurp;
use Try::Tiny;

use Data::Dumper;

use Mojo::Base 'Mojolicious::Controller';
use BibSpace::Functions::Core;
use BibSpace::Util::Preferences;

use Class::MOP;

use Moose::Util qw/does_role/;

use BibSpace::Converter::IHtmlBibtexConverter;

sub index {
  my $self = shift;

# http://search.cpan.org/~ether/Moose-2.2004/lib/Moose/Util.pm#does_role($class_or_obj,_$role_or_obj)
  my @converterClasses = grep { does_role($_, 'IHtmlBibtexConverter') }
    Class::MOP::get_all_metaclasses;
  @converterClasses = grep { $_ ne 'IHtmlBibtexConverter' } @converterClasses;

  $self->stash(
    preferences => $self->app->preferences,
    converters  => \@converterClasses
  );
  $self->render(template => 'display/preferences');
}

sub save {
  my $self                   = shift;
  my $bibitex_html_converter = $self->param('bibitex_html_converter');
  my $local_time_zone        = $self->param('local_time_zone');
  my $output_time_format     = $self->param('output_time_format');
  my $run_in_demo_mode       = $self->param('run_in_demo_mode');

  if ($run_in_demo_mode and $run_in_demo_mode eq 'on') {
    $run_in_demo_mode = 1;
  }
  else {
    $run_in_demo_mode = 0;
  }

  my $msg      = "Preferences saved!";
  my $msg_type = "success";

  # TODO: validate inputs
  $self->app->preferences->run_in_demo_mode($run_in_demo_mode);
  $self->app->preferences->bibitex_html_converter($bibitex_html_converter);
  $self->app->preferences->local_time_zone($local_time_zone);
  $self->app->preferences->output_time_format($output_time_format);

  $self->stash(
    preferences => $self->app->preferences,
    msg_type    => $msg_type,
    msg         => $msg
  );

  # $self->render( template => 'display/preferences' );
  $self->redirect_to($self->get_referrer);
}

1;
