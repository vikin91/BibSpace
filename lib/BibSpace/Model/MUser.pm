package MUser;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use 5.010;           #because of ~~ and say
use DBI;
use Moose;
use MooseX::ClassAttribute;

class_has 'admin_rank'   => ( is => 'ro', default => 2 );
class_has 'manager_rank' => ( is => 'ro', default => 1 );

has 'id'                => ( is => 'rw' );
has 'login'             => ( is => 'rw' );
has 'registration_time' => ( is => 'rw' );
has 'last_login'        => ( is => 'rw' );
has 'real_name'         => ( is => 'rw', default => "unnamed" );
has 'email'             => ( is => 'rw' );
has 'pass'              => ( is => 'rw' );
has 'pass2'             => ( is => 'rw' );
has 'pass3'             => ( is => 'rw' );
has 'rank'              => ( is => 'rw', default => 0 );
has 'master_id'         => ( is => 'rw', default => 0 );
has 'tennant_id'        => ( is => 'rw', default => 0 );

####################################################################################
sub static_all {
    my $self = shift;
    my $dbh  = shift;

    my $qry
        = "SELECT id, login, registration_time, last_login, real_name, email, pass, pass2, pass3, rank, master_id, tennant_id
                FROM Login
                ORDER BY last_login DESC";
    my $sth = $dbh->prepare($qry);
    $sth->execute();

    my @objs;

    while ( my $row = $sth->fetchrow_hashref() ) {
        push @objs,
            MUser->new(
            id                => $row->{id},
            login             => $row->{login},
            registration_time => $row->{registration_time},
            last_login        => $row->{last_login},
            real_name         => $row->{real_name},
            email             => $row->{email},
            pass              => $row->{pass},
            pass2             => $row->{pass2},
            pass3             => $row->{pass3},
            rank              => $row->{rank},
            master_id         => $row->{master_id},
            tennant_id        => $row->{tennant_id},
            );
    }
    return @objs;
}
####################################################################################
sub static_get {
    my $self = shift;
    my $dbh  = shift;
    my $id   = shift;

    my $qry
        = "SELECT DISTINCT id, login, registration_time, last_login, real_name, email, pass, pass2, pass3, rank, master_id, tennant_id
               FROM Login
               WHERE id = ?";

    my $sth = $dbh->prepare($qry);
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref();

    if ( !defined $row ) {
        return undef;
    }

    return MUser->new(
        id                => $row->{id},
        login             => $row->{login},
        registration_time => $row->{registration_time},
        last_login        => $row->{last_login},
        real_name         => $row->{real_name},
        email             => $row->{email},
        pass              => $row->{pass},
        pass2             => $row->{pass2},
        pass3             => $row->{pass3},
        rank              => $row->{rank},
        master_id         => $row->{master_id},
        tennant_id        => $row->{tennant_id},
    );
}
####################################################################################
sub static_get_by_login {
    my $self = shift;
    my $dbh  = shift;
    my $login   = shift;

    my $qry
        = "SELECT DISTINCT id, login, registration_time, last_login, real_name, email, pass, pass2, pass3, rank, master_id, tennant_id
               FROM Login
               WHERE login = ?";

    my $sth = $dbh->prepare($qry);
    $sth->execute($login);
    my $row = $sth->fetchrow_hashref();

    if ( !defined $row ) {
        return undef;
    }

    return MUser->new(
        id                => $row->{id},
        login             => $row->{login},
        registration_time => $row->{registration_time},
        last_login        => $row->{last_login},
        real_name         => $row->{real_name},
        email             => $row->{email},
        pass              => $row->{pass},
        pass2             => $row->{pass2},
        pass3             => $row->{pass3},
        rank              => $row->{rank},
        master_id         => $row->{master_id},
        tennant_id        => $row->{tennant_id},
    );
}
########################################################################################################################
sub is_manager {
    my $self = shift;
    return 1 if $self->{rank} >= MUser->manager_rank;
    return 0;
}
####################################################################################
# for _under_ -checking
sub is_admin {
    my $self = shift;
    return 1 if $self->{rank} >= MUser->admin_rank;
    return 0;
}
####################################################################################
sub make_admin {
    my $self = shift;
    my $dbh  = shift;
    $self->{rank} = 2;
    my $qry = "UPDATE Login SET rank=2 WHERE id=?";
    my $sth = $dbh->prepare($qry);
    $sth->execute( $self->{id} );
}

####################################################################################
sub make_manager {
    my $self = shift;
    my $dbh  = shift;

    if ( $self->{id} != 1 ) {
        $self->{rank} = 1;
        my $qry = "UPDATE Login SET rank=1 WHERE id=?";
        my $sth = $dbh->prepare($qry);
        $sth->execute( $self->{id} );
    }
}
####################################################################################
sub make_user {
    my $self = shift;
    my $dbh  = shift;

    if ( $self->{id} != 1 ) {
        $self->{rank} = 0;
        my $qry = "UPDATE Login SET rank=0 WHERE id=?";
        my $sth = $dbh->prepare($qry);
        $sth->execute( $self->{id} );
    }
}
####################################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
