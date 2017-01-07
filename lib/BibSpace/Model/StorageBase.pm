package StorageBase;


use strict;
use warnings;

use BibSpace::Model::CMObjectStore;

my $storage; 


sub init {
    $storage = CMObjectStore->new if !defined $storage ;
}

sub load {
    my $dbh = shift;
    if( !defined $storage ){
        init();
    }
    $storage->loadData($dbh);
}

sub get {
    $storage;
}

1;
