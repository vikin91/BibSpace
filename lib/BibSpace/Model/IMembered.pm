package IMembered;

use namespace::autoclean;
use Moose::Role;

has 'memberships' => (
  is      => 'rw',
  isa     => 'ArrayRef[Membership]',
  traits  => [ 'Array', 'DoNotSerialize' ],
  default => sub { [] },
  handles => {
      memberships_all        => 'elements',
      memberships_add        => 'push',
      memberships_count      => 'count',
      memberships_find       => 'first',
      memberships_find_index => 'first_index',
      memberships_filter     => 'grep',
      memberships_delete     => 'delete',
      memberships_clear      => 'clear',
  },
);

####################################################################################
sub has_membership {
    my ( $self, $membership ) = @_;
    my $idx = $self->memberships_find_index( sub { $_->equals($membership) } );
    return $idx >= 0;
}
####################################################################################
sub add_membership {
    my ( $self, $membership ) = @_;
    
    if( !$self->has_membership($membership) ){
      $self->memberships_add($membership);  
    }
}
####################################################################################
sub remove_membership {
    my ( $self, $membership ) = @_;
    # $membership->validate;
    
    my $index = $self->memberships_find_index( sub { $_->equals($membership) } );
    return if $index == -1;
    return 1 if $self->memberships_delete($index);
    return ;
}
####################################################################################
1;
