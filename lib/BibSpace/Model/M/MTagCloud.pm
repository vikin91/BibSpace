package MTagCloud;

    use Data::Dumper;
    use utf8;
    use 5.010; #because of ~~ and say
    use Moose;

   has 'tag' => (is => 'rw');   # just a pointer to the tag - either id or name #FIXME!
   has 'count' => (is => 'rw');  # number in parenthesis
   has 'url' => (is => 'rw'); # url to click in
   has 'name' => (is => 'rw'); # name of the tag to click in

####################################################################################
sub getHTML {
    my $self = shift;

    my $code = '<a href="'.$self->{url}.'" target="blank" class="tclink">'.$self->{name}.'</a>';
    $code .= '<span class="tctext">('.$self->{count}.')</span>';
    return $code;
}
####################################################################################

no Moose;
__PACKAGE__->meta->make_immutable;
1;