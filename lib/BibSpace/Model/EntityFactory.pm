# This code was auto-generated using ArchitectureGenerator.pl on 2017-01-15T14:47:33
package EntityFactory;

use namespace::autoclean;
use Moose;
use BibSpace::Model::ILogger;
use BibSpace::Model::PreferencesInstance;
use BibSpace::Model::IUidProvider;

use BibSpace::Model::Entry;

# this class has logger, because it may want to log somethig as well 
# thic code forces to instantiate the abstract factory first and then calling getInstance
has 'logger' => ( is => 'ro', does => 'ILogger', required => 1);
has 'id_provider' => ( is => 'ro', isa => 'SmartUidProvider', required => 1);
has 'preferences' => ( is => 'ro', isa => 'PreferencesInstance', required => 1);


sub new_Entry {
    my ($self, %args) = @_;
    return Entry->new( 
        idProvider => $self->id_provider->get_provider('Entry'),
        preferences => $self->preferences,
        %args
    );
}
# before 'new_Entry' => sub { shift->logger->entering( "", "" . __PACKAGE__ . "->new_Entry" ); };

sub new_TagType {
    my ($self, %args) = @_;
    return TagType->new(
        idProvider => $self->id_provider->get_provider('TagType'),
        preferences => $self->preferences,
        %args                        
    );
} 

sub new_Team {
    my ($self, %args) = @_;
    return Team->new(
        idProvider => $self->id_provider->get_provider('Team'),
        preferences => $self->preferences,
        %args                     
    );
} 

sub new_Author {
    my ($self, %args) = @_;
    return Author->new(
        idProvider => $self->id_provider->get_provider('Author'),
        preferences => $self->preferences,
        %args                       
    );
} 

sub new_Tag {
    my ($self, %args) = @_;
    return Tag->new(
        idProvider => $self->id_provider->get_provider('Tag'),
        preferences => $self->preferences,
        %args                    
    );
} 

sub new_Type {
    my ($self, %args) = @_;
    return Type->new(
        idProvider => $self->id_provider->get_provider('Type'),
        preferences => $self->preferences,
        %args                     
    );
} 

sub new_User {
    my ($self, %args) = @_;
    return User->new(
        idProvider => $self->id_provider->get_provider('User'),
        preferences => $self->preferences,
        %args                     
    );
} 


__PACKAGE__->meta->make_immutable;
no Moose;
1;
