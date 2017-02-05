package BibSpace::Controller::Preferences;

use strict;
use warnings;
use utf8;
use 5.010;    #because of ~~
use File::Slurp;
use Try::Tiny;

use Data::Dumper;


use Mojo::Base 'Mojolicious::Controller';
use Storable;
use BibSpace::Functions::Core;
use BibSpace::Model::Preferences;

use Class::MOP;
use Moose::Util qw/does_role/;


use BibSpace::Model::Converter::IHtmlBibtexConverter;

#################################################################################
sub index {
    my $self = shift;

    # http://search.cpan.org/~ether/Moose-2.2004/lib/Moose/Util.pm#does_role($class_or_obj,_$role_or_obj)
    my @converterClasses = grep { does_role($_ , 'IHtmlBibtexConverter') } Class::MOP::get_all_metaclasses;
    @converterClasses = grep { $_ ne 'IHtmlBibtexConverter' } @converterClasses;
    

    $self->stash( converters => \@converterClasses );
    $self->render( template => 'display/preferences' );
}
#################################################################################
sub save {
    my $self = shift;
    my $bibitex_html_converter = $self->param('bibitex_html_converter');
    my $local_time_zone = $self->param('local_time_zone');
    my $output_time_format = $self->param('output_time_format');

    # TODO: validate inputs

    Preferences->bibitex_html_converter($bibitex_html_converter);
    Preferences->local_time_zone($local_time_zone);
    Preferences->output_time_format($output_time_format);

    $self->flash( msg_type=>'success', msg => 'Preferences saved!' );
    # $self->render( template => 'display/preferences' );
    $self->redirect_to( $self->get_referrer );
}
#################################################################################
1;
