package UserObj;

use Data::Dumper;
use utf8;
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010; #because of ~~
use strict;
use warnings;
use DBI;

use AdminApi::Core;


sub new
{
    my ($class, $args) = @_;
    my $self = {
        id    => $args->{id},
        login  => $args->{login} || "",
        registration_time  => $args->{registration_time} || "",
        last_login  => $args->{last_login} || "",
        real_name => $args->{real_name} || "unnamed",
        email  => $args->{email},
        pass  => $args->{pass} || "",
        pass2  => $args->{pass2} || "",
        pass3  => $args->{pass3} || "",
        rank  => $args->{rank} || 0,
        master_id  => $args->{master_id} || 0,
        tennant_id  => $args->{tennant_id} || 0,
    };
    return bless $self, $class;
}

########################################################################################################################

sub initFromDB{
    my $self = shift;
    my $dbh = shift;

    my $qry = "SELECT DISTINCT id, login, registration_time, last_login, real_name, email, pass, pass2, pass3, rank, master_id, tennant_id
               FROM Login
               WHERE id = ?";

    my $sth = $dbh->prepare( $qry );  
    $sth->execute($self->{id});  

  
    my $row = $sth->fetchrow_hashref();
    $self->{id} = $row->{id};
    $self->{login} = $row->{login};
    $self->{registration_time} = $row->{registration_time};
    $self->{last_login} = $row->{last_login} || "0000-00-00 00:00:00",
    $self->{real_name} = $row->{real_name} || "unnamed",
    $self->{email} = $row->{email};
    $self->{pass} = $row->{pass};
    $self->{pass2} = $row->{pass2};
    $self->{pass3} = $row->{pass3} || "";
    $self->{rank} = $row->{rank};
    $self->{master_id} = $row->{master_id} || 0;
    $self->{tennant_id} = $row->{tennant_id} || 0;
}

########################################################################################################################
sub is_manager {
    my $self = shift;
    return 1 if $self->{rank} > 0;
    return undef;
}
####################################################################################
# for _under_ -checking
sub is_admin {
    my $self = shift;
    return 1 if $self->{rank} > 1;
    return undef;
}
####################################################################################
sub make_admin {
    my $self = shift;
    my $dbh = shift;
    $self->{rank} = 2;
    my $qry = "UPDATE Login SET rank=2 WHERE id=?";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute($self->{id});   
}
####################################################################################
sub make_manager {
    my $self = shift;
    my $dbh = shift;
    if($self->{id} != 1){
        $self->{rank} = 1;
        my $qry = "UPDATE Login SET rank=1 WHERE id=?";
        my $sth = $dbh->prepare( $qry );  
        $sth->execute($self->{id});
    }
}
####################################################################################
sub make_user {
    my $self = shift;
    my $dbh = shift;
    if($self->{id} != 1){
        $self->{rank} = 0;
        my $qry = "UPDATE Login SET rank=0 WHERE id=?";
        my $sth = $dbh->prepare( $qry );  
        $sth->execute($self->{id});
    }
}
########################################################################################################################
sub getAll{
    my $self = shift;
    my $dbh = shift;

    my $qry = "SELECT id, login, registration_time, last_login, real_name, email, pass, pass2, pass3, rank, master_id, tennant_id
                FROM Login
                ORDER BY last_login DESC";
    my $sth = $dbh->prepare( $qry );  
    $sth->execute();  

    my @objs;

    while(my $row = $sth->fetchrow_hashref()) {
        my $obj = UserObj->new({
                                id => $row->{id},
                                login => $row->{login},
                                registration_time => $row->{registration_time},
                                last_login => $row->{last_login},
                                real_name => $row->{real_name},
                                email => $row->{email},
                                pass => $row->{pass},
                                pass2 => $row->{pass2},
                                pass3 => $row->{pass3},
                                rank => $row->{rank},
                                master_id => $row->{master_id},
                                tennant_id => $row->{tennant_id},
                            });
        push @objs, $obj;
    }
    return @objs;
}
########################################################################################################################

1;