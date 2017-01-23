package IAuthored;

use namespace::autoclean;
use Moose::Role;

has 'authorships' => (
    is      => 'rw',
    isa     => 'ArrayRef[Authorship]',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        authorships_all        => 'elements',
        authorships_add        => 'push',
        authorships_count      => 'count',
        authorships_find       => 'first',
        authorships_find_index => 'first_index',
        authorships_filter     => 'grep',
        authorships_delete     => 'delete',
        authorships_clear      => 'clear',
    },  
);

####################################################################################
sub has_authorship {
    my ( $self, $authorship ) = @_;
    my $idx = $self->authorships_find_index( sub { $_->equals($authorship) } );
    return $idx >= 0;
}
####################################################################################
sub add_authorship {
    my ( $self, $authorship ) = @_;
    if( !$self->has_authorship($authorship) ){
      $self->authorships_add($authorship);  
    }
}
####################################################################################
sub remove_authorship {
    my ( $self, $authorship ) = @_;
    my $index = $self->authorships_find_index( sub { $_->equals($authorship) } );
    return if $index == -1;
    return 1 if $self->authorships_delete($index);
    return ;
}
####################################################################################
sub authors {
    my $self = shift;
    SimpleLogger->new->warn("IAuthored->authors is deprecated in favor of IAuthored->get_authors");
    return $self->get_authors;
}
####################################################################################
sub get_authors {
    my $self = shift;
    return map {$_->author} $self->authorships_all;
}
####################################################################################
sub entries {
    my $self = shift;
    SimpleLogger->new->warn("IAuthored->entries is deprecated in favor of IAuthored->get_entries");
    return $self->get_entries;
}
####################################################################################
sub get_entries {
    my $self = shift;
    return map {$_->entry} $self->authorships_all;
}
####################################################################################
1;
