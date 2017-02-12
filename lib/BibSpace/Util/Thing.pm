package Thing;


use Moose;
has 'id' => ( is => 'rw', isa => 'Int', default => 1);
has 'str' => ( is => 'rw', isa => 'Str', default => "I am a thing");

sub equals {
	my ($self, $obj) = @_;
	return $self->id == $obj->id;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;