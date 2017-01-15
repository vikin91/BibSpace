package IBibSpaceBackend;
use 5.010;    #because of ~~ and say
use Try::Tiny;
use Data::Dumper;
use Moose::Role;

requires 'all'; # my ($self) = @_;
requires 'count'; # my ($self) = @_;
requires 'empty'; # my ($self) = @_;
requires 'exists'; # my ($self, $object) = @_;
requires 'save'; # my ($self, @objects) = @_;
requires 'update'; # my ($self, @objects) = @_;
requires 'delete'; # my ($self, @objects) = @_; 
requires 'filter'; # my ($self, $coderef) = @_;
requires 'find'; #   my ($self, $coderef) = @_;


sub all { 
    my ($self) = @_;
    die "Method unimplemented!";
}
sub count { 
    my ($self) = @_;
    die "Method unimplemented!";
}
sub empty { 
    my ($self) = @_;
    die "Method unimplemented!";
}
sub exists { 
    my ($self, $object) = @_;
    die "Method unimplemented!";
}
sub save { 
    my ($self, @objects) = @_;
    die "Method unimplemented!";
}
sub update { 
    my ($self, @objects) = @_;
    die "Method unimplemented!";
}
sub delete { 
    my ($self, @objects) = @_; 
    die "Method unimplemented!";
}
sub filter { 
    my ($self, $coderef) = @_;
    die "Method unimplemented!";
}
sub find { 
  my ($self, $coderef) = @_;
  die "Method unimplemented!";
}

1;

