package RedisWrapper;

use Data::Dumper;
use 5.010;           #because of ~~ and say
use Try::Tiny;
use Mojo::Redis2;
use Moose;

extends 'Mojo::Redis2';

has 'cache_enabled' => ( is => 'ro' );


# sub set {
# 		my ($self) = @_;
# 		return $self->SUPER::set() if $self->cache_enabled;
# }


no Moose;
__PACKAGE__->meta->make_immutable;
1;
