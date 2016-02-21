package Hex64Publications::Controller::Example;
use Mojo::Base 'Mojolicious::Controller';
use Hex64Publications::Schema;

use Data::Dumper;


# This action will render a template
sub welcome {
    my $self = shift;

    my $schema = $self->app->db;

    $schema->resultset('Entry')->search({ bibtex_key => 'Spoon' })->delete;
    my $new_paper = $self->app->db->resultset('Entry')->new({ bibtex_key => 'Spoon',
                                                    bib => '@atricle{abc, year={20155}}',
                                                     bibtex_type => 'shit' });
    $new_paper->insert;

    my @all = $schema->resultset('Entry')->all;
    my $all_rs = $schema->resultset('Entry');


    my $str = "AAA: ";
    foreach my $e (@all) {
        # Dumper($e);
        $str .= $e->bibtex_key;
    }


  # Render template "example/welcome.html.ep" with message
  $self->render(msg => $str);
}




1;
