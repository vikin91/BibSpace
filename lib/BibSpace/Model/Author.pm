package Author;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use v5.16;           # because of ~~ and say

use List::MoreUtils qw(any uniq);
use BibSpace::Model::Membership;

use feature qw(current_sub);
use Moose;
require BibSpace::Model::IEntity;
require BibSpace::Model::IAuthored;
require BibSpace::Model::IMembered;
with 'IEntity', 'IAuthored', 'IMembered';
use feature qw(current_sub);
use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );


has 'uid' => ( is => 'rw', isa => 'Str', documentation => q{Author name} );
has 'display' => (
    is            => 'rw',
    default       => 0,
    documentation => q{If 1, the author will be displayed in menu.}
);
has 'master' => (
    is            => 'rw',
    isa           => 'Maybe[Str]',
    default       => sub { shift->{uid} },
    documentation => q{Author master name. Redundant field.}
);
has 'master_id' => (
    is            => 'rw',
    isa           => 'Maybe[Int]',
    documentation => q{Id of author's master object}
);
has 'masterObj' => (
    is      => 'rw',
    isa     => 'Maybe[Author]',
    default => sub {undef},

    # traits  => ['DoNotSerialize'],
    documentation => q{Author's master author object.}
);


####################################################################################
# called after the default constructor
sub BUILD {
    my $self = shift;
    $self->id;    # trigger lazy execution of idProvider
    if ( !defined $self->master or $self->master eq '' ) {
        $self->master( $self->uid );
    }
    if ( !defined $self->master_id and defined $self->{id} ) {
        $self->master_id( $self->id );
    }
    if ( defined $self->masterObj and $self->masterObj == $self ) {
        $self->masterObj(undef);
    }
}
####################################################################################
sub toString {
    my $self = shift;
    my $str  = $self->freeze;
    $str .= "\n\t (MASTER): " . $self->masterObj->freeze
        if defined $self->masterObj;
    return $str;
}
####################################################################################
sub equals {
    my $self = shift;
    my $obj  = shift;

    return undef if !defined $obj;
    die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj)
        unless ref($self) eq ref($obj);


    my $result = $self->uid eq $obj->uid;
    return $result;
}
####################################################################################
####################################################################################

####################################################################################
####################################################################################
sub set_master {
    my $self          = shift;
    my $master_author = shift;

    $self->masterObj($master_author);

    $self->master( $master_author->uid );
    $self->master_id( $master_author->id );
}
####################################################################################
sub get_master {
    my $self = shift;

    return $self if $self->is_master;
    return $self->masterObj if $self->masterObj;

    warn "SERIOUS WARNING! Cannot derive master for "
        . $self->uid
        . ". Author is not master, but masterObj is undef. id '"
        . $self->id
        . "' master_id '"
        . $self->master_id . "'.";
    return;
}
####################################################################################
sub is_master {
    my $self = shift;

    if ( $self->equals( $self->masterObj ) or $self->master_id == $self->id )
    {
        return 1;
    }
    return;
}
####################################################################################
sub is_minion {
    my $self = shift;
    return not $self->is_master;
}
####################################################################################
sub is_minion_of {
    my $self   = shift;
    my $master = shift;


    if ( $self->masterObj and $self->masterObj->equals($master) ) {
        return 1;
    }
    return;
}
####################################################################################
sub update_master_name {
    my $self       = shift;
    my $new_master = shift;

    $self->uid($new_master);

    if ( $self->is_minion ) {
        #
    }
    else {
        $self->master($new_master);
    }
    return 1;
}
####################################################################################
sub remove_master {
    my $self = shift;

    $self->masterObj(undef);
    $self->master( $self->uid );
    $self->master_id( $self->id );
}
####################################################################################
sub add_minion {
    my $self   = shift;
    my $minion = shift;

    return if !defined $minion;
    $minion->set_master($self);
    return 1;
}
##############################################################################################################
sub can_merge_authors {
    my $self          = shift;
    my $source_author = shift;


    if (    defined $source_author
        and $source_author->id != $self->id
        and !$self->equals($source_author) )
    {
        return 1;
    }
    return;
}
####################################################################################
####################################################################################
####################################################################################
sub toggle_visibility {
    my $self = shift;

    if ( $self->display == 0 ) {
        $self->display(1);
    }
    else {
        $self->display(0);
    }
}
####################################################################################
sub is_visible {
    my $self = shift;

    return $self->display == 1;
}
####################################################################################
sub can_be_deleted {
    my $self = shift;

    return if $self->display == 1;

    my @teams = $self->get_teams;

    return 1 if scalar @teams == 0 and $self->display == 0;
    return;
}
####################################################################################
####################################################################################
####################################################################################
sub has_entry {
    my $self = shift;
    my $e    = shift;

    return defined $self->authorships_find( sub { $_->equals($e) } );
}
####################################################################################
sub take_entries_from_author {
    my $self        = shift;
    my $from_author = shift;

    die "this function must be called from controller-level!";

    # $self->entries_add( $from_author->entries );
    $from_author->abandon_all_entries;
}


################################################################################
sub abandon_all_entries {
    my $self = shift;
    die "this function must be called from controller-level!";
    $self->authorships_clear;
}
################################################################################
################################################################################ TEAMS
################################################################################
####################################################################################
sub joined_team {
    my $self = shift;
    my $team = shift;

    return -1 if !defined $team;

    my $mem = $self->memberships_find(
        sub {
            $_->team_id == $team->id and $_->author_id == $self->id;
        }
    );
    return -1 if !defined $mem;
    return $mem->start;
}
####################################################################################
sub left_team {
    my $self = shift;
    my $team = shift;

    return -1 if !defined $team;

    my $mem = $self->memberships_find(
        sub {
            $_->team_id == $team->id and $_->author_id == $self->id;
        }
    );
    return -1 if !defined $mem;
    return $mem->stop;
}
################################################################################
sub abandon_all_teams {
    my $self = shift;
    $self->memberships_clear;
}
################################################################################
sub update_membership {
    my $self  = shift;
    my $team  = shift;
    my $start = shift;
    my $stop  = shift;

    my $mem = $self->memberships_find(
        sub {
            $_->team_id == $team->id and $_->author_id == $self->id;
        }
    );

    if ( $start < 0 ) {
        die "Invalid start $start: start must be 0 or greater";
    }
    if ( $stop < 0 ) {
        die "Invalid stop $stop: stop must be 0 or greater";
    }
    if ( $stop > 0 and $start > 0 and $stop < $start ) {
        die "Invalid range: stop must me non-smaller than start";
    }
    if ( !$mem ) {
        die "Invalid team. Cannot find author membership in that team.";
    }

    if ($mem) {
        $mem->start($start) if defined $start;
        $mem->stop($stop)   if defined $stop;
    }
}


####################################################################################
#################################################################################### TAGS
####################################################################################
sub get_tags {

    my $self = shift;
    my $type = shift // 1;

    my @myTags;

    map { push @myTags, $_->get_tags($type) } $self->get_entries;
    @myTags = uniq @myTags;

    return @myTags;
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
