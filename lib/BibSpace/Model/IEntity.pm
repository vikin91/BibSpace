package IEntity;
use namespace::autoclean;

use BibSpace::Model::IntegerUidProvider;
use Moose::Role;
use MooseX::StrictConstructor;


sub _generateUIDEntry {
    my $self = shift;
  
    if ( defined $self->old_mysql_id and $self->old_mysql_id > 0 ) {
        $self->idProvider->registerUID( $self->old_mysql_id );
        return $self->old_mysql_id;
    }
    return $self->idProvider->generateUID();
}

has 'idProvider' => (
    is       => 'ro',
    does     => 'IUidProvider',
    required => 1,
);
has 'old_mysql_id'    => ( is => 'ro', isa => 'Maybe[Int]', default => undef );
has 'id'              => ( is => 'ro', isa => 'Int', builder => '_generateUIDEntry', lazy=>1, init_arg => undef );

requires 'equals';
####################################################################################
# called after the default constructor
sub BUILD {
    my $self = shift;
    $self->id; # trigger lazy execution of idProvider
}
####################################################################################
1;
