package BibSpace::Controller::Types;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010;           #because of ~~
use strict;
use warnings;
use DBI;
use DBIx::Connector;

use List::MoreUtils qw(any uniq);
use BibSpace::Controller::Core;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;

#  ALTER TABLE OurType_to_Type ADD COLUMN description TEXT DEFAULT NULL;
#  ALTER TABLE OurType_to_Type ADD COLUMN landing INTEGER DEFAULT 0;

####################################################################################
sub all_our {
    my $self = shift;
    

    my @types = $self->app->repo->getTypesRepository->all;
    
    $self->stash( otypes => \@types );
    $self->render( template => 'types/types' );
}
####################################################################################
sub add_type {
    my $self = shift;
    $self->render( template => 'types/add' );
}
####################################################################################
sub post_add_type {
    my $self     = shift;
    my $new_type = $self->param('new_type');

    my $type = Type->new(our_type => $new_type);

    $self->app->repo->types_save($type);

    $self->redirect_to( $self->url_for('types') );
}
####################################################################################
sub manage {
    my $self = shift;
    my $type_id = $self->param('type');

    my @all = $self->app->repo->getTypesRepository->all;
    my $type = $self->app->repo->types_find( sub {$_->id == $type_id});

    my %bibtex_types = {};

    foreach my $t (@all){
        foreach my $bib_t ($t->bibtexTypes){
            $bibtex_types{"$bib_t"} = 1;
        }
    }

    my @all_our_types        = uniq map{$_->our_type} @all;
    my @all_bibtex_types      = keys %bibtex_types;
    my @assigned_bibtex_types = $type->bibtexTypes_all;


    # # cannot use objects as keysdue to stringification!
    my %types_hash = map { $_ => 1 } @assigned_bibtex_types;
    my @unassigned_btypes
        = grep { not $types_hash{ $_ } } @all_bibtex_types;


    $self->stash(
        all_otypes        => \@all_our_types,
        unassigned_btypes => \@unassigned_btypes,
        all_btypes        => \@all_bibtex_types,
        assigned_btypes   => \@assigned_bibtex_types,
        type              => $type
    );
    $self->render( template => 'types/manage_types' );
}

####################################################################################
sub toggle_landing {
    my $self = shift;
    my $type = $self->param('type');

    my $dbh = $self->app->db;

    toggle_landing_for_our_type( $dbh, $type );

    $self->redirect_to( $self->get_referrer );
}
####################################################################################
sub post_store_description {
    my $self        = shift;
    my $type        = $self->param('our_type');
    my $description = $self->param('new_description');

    my $dbh = $self->app->db;

    if ( defined $type and defined $description ) {
        my $sth = $dbh->prepare(
            "UPDATE OurType_to_Type SET description=? WHERE our_type=?");
        $sth->execute( $description, $type );
    }

    $self->redirect_to( $self->url_for( 'typesmanagetype', type => $type ) );
}
####################################################################################
sub delete_type {
    my $self     = shift;
    my $type2del = $self->param('type_to_delete');
    my $msg      = "";
    my $dbh      = $self->app->db;

    my $type_str = join '',
        $self->get_bibtex_types_aggregated_for_type($type2del);
    if (    $self->num_bibtex_types_aggregated_for_type($type2del) == 1
        and $type_str eq $type2del )
    {
        $msg
            = "<strong>DELETE ERROR</strong>: $type2del is native BibTeX type and cannot be deleted!";
        $self->flash( message => $msg );
        $self->redirect_to( $self->get_referrer );
    }
    elsif ( $self->num_bibtex_types_aggregated_for_type($type2del) > 1 ) {
        $msg
            = "<strong>DELETE ERROR</strong>: please unmap BibTeX types first";
        $self->flash( message => $msg );
        $self->redirect_to( $self->get_referrer );
    }
    elsif ( defined $type2del ) {
        do_delete_type( $dbh, $type2del );
    }
    $self->redirect_to( $self->url_for('types') );
}
####################################################################################

sub do_delete_type {
    my $dbh      = shift;
    my $type2del = shift;

    my $sth = $dbh->prepare("DELETE FROM OurType_to_Type WHERE our_type=?");
    $sth->execute($type2del);
}
####################################################################################
sub map_types {
    my $self   = shift;
    my $o_type = $self->param('our_type');
    my $b_type = $self->param('bibtex_type');
    my $msg    = "";

    my $dbh = $self->app->db;

    if (    defined $o_type
        and length $o_type > 0
        and defined $b_type
        and length $b_type > 0 )
    {
        # inputs OK
        # checkin if bibtex type exists
        my @all_b_types = get_all_existing_bibtex_types();
        if ( $b_type ~~ @all_b_types ) {
            do_map_types( $dbh, $o_type, $b_type );
        }
        else {
            $msg
                = "<strong>MAP ERROR</strong>: $b_type is not a valid bibtex type!";
            $self->flash( message => $msg );
            $self->redirect_to( $self->get_referrer );
            return;
        }
    }
    $self->redirect_to( $self->get_referrer );
}

####################################################################################

sub do_create_type {
    my $dbh    = shift;
    my $o_type = shift;

    my $sth = $dbh->prepare(
        "INSERT INTO OurType_to_Type(our_type, bibtex_type) VALUES (?,NULL)");
    $sth->execute($o_type);
}
####################################################################################

sub do_map_types {
    my $dbh    = shift;
    my $o_type = shift;
    my $b_type = shift;

    my $sth = $dbh->prepare(
        "INSERT INTO OurType_to_Type(our_type, bibtex_type) VALUES (?,?)");
    $sth->execute( $o_type, $b_type );
}

####################################################################################
sub unmap_types {
    my $self   = shift;
    my $o_type = $self->param('our_type');
    my $b_type = $self->param('bibtex_type');
    my $dbh    = $self->app->db;
    my $msg    = "";

    say "unmapping o $o_type b $b_type";

    if (    defined $o_type
        and length $o_type > 0
        and defined $b_type
        and length $b_type > 0 )
    {
        if ( $o_type eq $b_type ) {
            $msg
                = "<strong>UNMAP ERROR</strong>: Unmapping $b_type from $o_type this would delete $o_type! $o_type cannot be deleted because it is a bibtex type.";
            $self->flash( message => $msg );
            $self->redirect_to( $self->get_referrer );
            return;
        }

        # inputs OK
        # checkin if bibtex type exists
        my @all_b_types = get_all_existing_bibtex_types();
        if ( $b_type ~~ @all_b_types ) {
            do_unmap_types( $dbh, $o_type, $b_type );
        }
        else {
            $msg
                = "<strong>UNMAP ERROR</strong>: $b_type is not a valid bibtex type!";
            $self->flash( message => $msg );
            $self->redirect_to( $self->get_referrer );
        }
    }

    $self->redirect_to( $self->get_referrer );

}
####################################################################################
sub do_unmap_types {
    my $dbh    = shift;
    my $o_type = shift;
    my $b_type = shift;

    my $sth = $dbh->prepare(
        "DELETE FROM OurType_to_Type WHERE our_type=? AND bibtex_type=?");
    $sth->execute( $o_type, $b_type );
}
####################################################################################
1;
