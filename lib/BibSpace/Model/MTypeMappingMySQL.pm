package MTypeMappingMySQL;

use List::MoreUtils qw(any uniq);
use BibSpace::Model::StorageBase;

use Data::Dumper;
use utf8;

use 5.010;    #because of ~~ and say
use DBI;
use Try::Tiny;

use Moose;
use MooseX::Storage;
use BibSpace::Model::MTypeMappingBase;
use BibSpace::Model::Persistent;

extends 'MTypeMappingBase';
with 'Persistent';

####################################################################################
sub load {
    my $self    = shift;
    my $dbh     = shift;
    my $storage = shift;

    # there is nothing to load so far
}
####################################################################################
sub static_all {
    my $self = shift;
    my $dbh  = shift;

    my $qry = "SELECT bibtex_type, our_type, landing, description
           FROM OurType_to_Type";

    my $sth = $dbh->prepare($qry);
    $sth->execute();

    # key = our_type
    # values = bibtex_types
    my %data_bibtex;
    my %data_desc;
    my %data_landing;

    while ( my $row = $sth->fetchrow_hashref() ) {
      if( $data_bibtex{$row->{our_type}} ){
        push @{ $data_bibtex{$row->{our_type}} }, $row->{bibtex_type};
      }
      else{
        $data_bibtex{$row->{our_type}} = [ $row->{bibtex_type} ];
      }
      $data_desc{$row->{our_type}} = $row->{decription};
      $data_landing{$row->{our_type}} = $row->{landing};
    }
    
    my @mappings;
    foreach my $k (keys %data_bibtex){
      my @bibtex_types = @{ $data_bibtex{$k} };
      my $desc         = $data_desc{$k};
      my $landing      = $data_landing{$k};

      my $obj = MTypeMapping->new( 
        our_type=>$k,
        description => $desc,
        landing => $landing
      );
      $obj->bibtexTypes_add(@bibtex_types);
      push @mappings, $obj;
    }
    return @mappings;
}
####################################################################################

no Moose;
__PACKAGE__->meta->make_immutable;
1;
