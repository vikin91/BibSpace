package BibSpace::Controller::Search;

use Data::Dumper;
use utf8;
use 5.010; #because of ~~
use strict;
use warnings;
use DBI;

use BibSpace::Controller::Core;
use BibSpace::Controller::Set;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';



sub search {
    my $self = shift;

    my $q = $self->param('q');
    my $type = $self->param('type');
    my $dbh = $self->app->db;

    my $log_str = "call: search. Type: $type, q: $q";
    say $log_str;

    my $return = -1;


    if($type eq "tagtype"){
        my $obj = TagTypeObj->getByName($dbh, $q);
        $return = $obj->{id} || -1;
    }
    else{

    }

    # $self->write_log($log_str);
    $self->render(text => "$return");
};

1;