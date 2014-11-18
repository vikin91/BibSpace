package AdminApi::Types;

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

use AdminApi::Core;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;


#  ALTER TABLE OurType_to_Type ADD COLUMN description TEXT DEFAULT NULL;
#  ALTER TABLE OurType_to_Type ADD COLUMN landing INTEGER DEFAULT 0;

####################################################################################
sub all_our {
    my $self = shift;
    my $dbh = $self->db;

    my @otypes = get_all_our_types($dbh);
  
    $self->stash(otypes  => \@otypes);
    $self->render(template => 'types/types');
}
####################################################################################
sub add_type{
    my $self = shift;
    my $dbh = $self->db;

    $self->stash();
    $self->render(template => 'types/add');   
}
####################################################################################
sub post_add_type{
    my $self = shift;
    my $new_type = $self->param('new_type');
    
    my $dbh = $self->db;
    my $back_url = $self->param('back_url') || '/types';

    if(defined $new_type and length($new_type)>0 ){
        my $sth = $dbh->prepare("INSERT OR IGNORE INTO OurType_to_Type (our_type, bibtex_type, description, landing) VALUES(?,?,?,?)");  
        $sth->execute($new_type, "misc", "Publications of type ".$new_type, 0);    
    }

    $self->redirect_to($back_url);
}
####################################################################################
sub manage {
    my $self = shift;
    my $type = $self->param('type');
    my $dbh = $self->db;
    my $back_url = $self->param('back_url') || '/types';

    my @all_otypes = get_all_our_types($dbh);
    my @all_btypes = get_all_bibtex_types($dbh);
    my @assigned_btypes = get_bibtex_types_for_our_type($dbh, $type);

  
    $self->stash(all_otypes  => \@all_otypes, all_btypes => \@all_btypes, assigned_btypes => \@assigned_btypes, type => $type, back_url => $back_url);
    $self->render(template => 'types/manage_types');
}

####################################################################################
sub toggle_landing{
    my $self = shift;
    my $type = $self->param('type');
    
    my $dbh = $self->db;
    my $back_url = $self->param('back_url') || '/types';

    toggle_landing_for_our_type($dbh, $type);

    $self->redirect_to($back_url);
}
####################################################################################
sub post_store_description{
    my $self = shift;
    my $type = $self->param('our_type');
    my $description = $self->param('new_description');
    
    my $dbh = $self->db;
    my $back_url = $self->param('back_url') || '/types';

    if(defined $type and defined $description ){
        my $sth = $dbh->prepare("UPDATE OurType_to_Type SET description=? WHERE our_type=?");  
        $sth->execute($description, $type);    
    }

    $self->redirect_to('/types/manage/'.$type."?back_url=".$back_url);
}
####################################################################################
sub delete_type {
    my $self = shift;
    my $type2del = $self->param('type_to_delete');
    my $msg = "";
    my $dbh = $self->db;
    my $back_url = $self->param('back_url') || '/types';

    my $type_str = join '', $self->get_bibtex_types_aggregated_for_type($type2del);
    if($self->num_bibtex_types_aggregated_for_type($type2del) == 1 and $type_str eq $type2del){
        $msg = "<strong>DELETE ERROR</strong>: $type2del is native BibTeX type and cannot be deleted!";        
        $self->flash(back_url => $back_url, message => $msg);
        $self->redirect_to($back_url);
    }
    elsif($self->num_bibtex_types_aggregated_for_type($type2del) > 1){
        $msg = "<strong>DELETE ERROR</strong>: please unmap BibTeX types first";        
        $self->flash(back_url => $back_url, message => $msg);
        $self->redirect_to($back_url);
    }
    elsif(defined $type2del){
        do_delete_type($dbh, $type2del);
    }
    $self->redirect_to($back_url);
}
####################################################################################

sub do_delete_type{
    my $dbh = shift;
    my $type2del = shift;

    my $sth = $dbh->prepare("DELETE FROM OurType_to_Type WHERE our_type=?");  
    $sth->execute($type2del);
}
####################################################################################
sub map_types {
    my $self = shift;
    my $o_type = $self->param('our_type');
    my $b_type = $self->param('bibtex_type');
    my $msg = "";

    my $dbh = $self->db;
    my $back_url = $self->param('back_url') || '/types';

    if(defined $o_type and length $o_type > 0 and defined $b_type and length $b_type > 0){
        # inputs OK
        # checkin if bibtex type exists
        my @all_b_types = get_all_existing_bibtex_types();
        if( $b_type ~~ @all_b_types){
            do_map_types($dbh, $o_type, $b_type);
        }
        else{
            $msg = "<strong>MAP ERROR</strong>: $b_type is not a valid bibtex type!";        
            $self->flash(back_url => $back_url, message => $msg);
            $self->redirect_to($back_url);
        }
    }
    $self->redirect_to($back_url);
}

####################################################################################

sub do_create_type{
    my $dbh = shift;
    my $o_type = shift;

    my $sth = $dbh->prepare("INSERT INTO OurType_to_Type(our_type, bibtex_type) VALUES (?,NULL)");  
    $sth->execute($o_type);
}
####################################################################################

sub do_map_types{
    my $dbh = shift;
    my $o_type = shift;
    my $b_type = shift;

    my $sth = $dbh->prepare("INSERT INTO OurType_to_Type(our_type, bibtex_type) VALUES (?,?)");  
    $sth->execute($o_type, $b_type);
}

####################################################################################
sub unmap_types {
    my $self = shift;
    my $o_type = $self->param('our_type');
    my $b_type = $self->param('bibtex_type');
    my $dbh = $self->db;
    my $back_url = $self->param('back_url') || '/types';
    my $msg = "";

    if(defined $o_type and length $o_type > 0 and defined $b_type and length $b_type > 0){
        # inputs OK
        # checkin if bibtex type exists
        my @all_b_types = get_all_existing_bibtex_types();
        if( $b_type ~~ @all_b_types){
            do_unmap_types($dbh, $o_type, $b_type);
        }
        else{
            $msg = "<strong>UNMAP ERROR</strong>: $b_type is not a valid bibtex type!";        
            $self->flash(back_url => $back_url, message => $msg);
            $self->redirect_to($back_url);
        }
    }

    $self->redirect_to($back_url);

}
####################################################################################
sub do_unmap_types{
    my $dbh = shift;
    my $o_type = shift;
    my $b_type = shift;

    my $sth = $dbh->prepare("DELETE FROM OurType_to_Type WHERE our_type=? AND bibtex_type=?");  
    $sth->execute($o_type, $b_type);
}
####################################################################################
1;