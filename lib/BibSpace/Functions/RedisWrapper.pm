package RedisWrapper;

use Data::Dumper;
use 5.010;           #because of ~~ and say
use Try::Tiny;
use Mojo::Redis2;
use Moose;

extends 'Mojo::Redis2';

has 'cache_enabled' => ( is => 'ro' );

sub enable_cache {
	shift->{cache_enabled} = 1;
}

sub disable_cache {
	shift->{cache_enabled} = 0;
}

sub set {
		my $self = shift;
		# print "Using set from " . __PACKAGE__ . ". Cache enabled = " . $self->cache_enabled . "\n";
		return $self->SUPER::set(@_) if $self->cache_enabled;
		return undef;
}

sub get {
		my $self = shift;
		# print "Using get from " . __PACKAGE__ . ". Cache enabled = " . $self->cache_enabled . "\n";
		return $self->SUPER::get(@_) if $self->cache_enabled;
		return undef;
}

sub on {
		my $self = shift;
		return $self->SUPER::on(@_) if $self->cache_enabled;
		return undef;
}

sub subscribe {
		my $self = shift;
		return $self->SUPER::subscribe(@_) if $self->cache_enabled;
		return undef;
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;