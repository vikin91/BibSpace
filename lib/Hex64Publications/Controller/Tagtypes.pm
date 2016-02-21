package Hex64Publications::Controller::Tagtypes;

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

use Hex64Publications::Controller::Core;
use Hex64Publications::Functions::TagTypeObj;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;


####################################################################################
sub index{
    my $self = shift;
    my $dbh = $self->app->db;

    my @objs = Hex64Publications::Functions::TagTypeObj->getAll($dbh);

    $self->render(template => 'tagtypes/tagtypes', tto => \@objs);
}



####################################################################################
sub add{
    my $self = shift;
    my $dbh = $self->app->db;


    $self->render(template => 'tagtypes/add');
}

####################################################################################
sub add_post{
    my $self = shift;
    my $dbh = $self->app->db;
    my $name = $self->param('new_name');
    my $comment = $self->param('new_comment');

    my $qry = 'INSERT INTO TagType(name, comment) VALUES (?,?)';
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($name, $comment); 
    
    $self->redirect_to("/tagtypes");
}

####################################################################################
sub delete{
    my $self = shift;
    my $dbh = $self->app->db;
    my $id = $self->param('id');

    if($id == 1 or $id == 2){
        $self->redirect_to("/tagtypes");
        return;        
    }

    my $qry = 'DELETE FROM Tag WHERE type=?';
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($id); 

    my $qry2 = 'DELETE FROM TagType WHERE id=?';
    my $sth2 = $dbh->prepare( $qry2 );  
    $sth2->execute($id); 

    $self->redirect_to("/tagtypes");
}

####################################################################################
sub edit{
    my $self = shift;
    my $dbh = $self->app->db;
    my $id = $self->param('id');

    my $name = $self->param('new_name');
    my $comment = $self->param('new_comment');
    my $saved = 0;

    if(defined $name and defined $comment){
        my $qry = 'UPDATE TagType SET name=?, comment=? WHERE id=?';
        my $sth = $dbh->prepare( $qry );  
        $sth->execute($name, $comment, $id); 
        $saved = 1;
    }

    my $obj = Hex64Publications::Functions::TagTypeObj->new();
    $obj = $obj->getById($dbh, $id);


    $self->stash(id => $id, obj => $obj, saved  => $saved);
    $self->render(template => 'tagtypes/edit');

}



1;
