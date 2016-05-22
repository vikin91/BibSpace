package BibSpace::Functions::TagCloudClass;

use Data::Dumper;
use utf8;
use 5.010; #because of ~~
use strict;
use warnings;


# class
# tag
# count
# url
# name

#
# New Structure containing all data
# 
sub new {
    my $class = shift;

    my $self = {
        _tag => shift,
        _count => undef,
        _url => undef,
        _name => undef,
    };

    bless $self, $class;
    return $self;
}

######################
sub setCount{
    my $self = shift;
    my $cnt = shift; 

    $self->{_count} = $cnt if defined $cnt;
    return $self->{_count};
}   

sub setURL{
    my $self = shift;
    my $url = shift; 

    $self->{_url} = $url if defined $url;
    return $self->{_url};
}

sub setName{
    my $self = shift;
    my $name = shift; 

    $self->{_name} = $name if defined $name;
    return $self->{_name};
}

######################

sub getCount{
    my $self = shift;
    return $self->{_count};
}   

sub getURL{
    my $self = shift;
    return $self->{_url};
}

sub getName{
    my $self = shift;
    return $self->{_name};
}

######################

sub getHTML {
    my $self = shift;
    my $css = shift || undef;

    my $code = '<a href="'.$self->{_url}.'" target="blank" class="tclink">'.$self->{_name}.'</a><span class="tctext">('.$self->{_count}.')</span>';
    # $code = '<a href="'.$self->{_url}.'" target="blank" style="'.$css.'">'.$self->{_name}.'</a>('.$self->{_count}.')' if defined $css;

    return $code;
}

######################

1;