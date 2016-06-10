package BibSpace::Functions::MyUsers;

use strict;
use warnings;
use Crypt::Eksblowfish::Bcrypt qw(bcrypt bcrypt_hash en_base64); # sudo cpanm Crypt::Eksblowfish::Bcrypt
use Crypt::Random; # sudo cpanm Crypt::Random
use LWP::UserAgent;
use Session::Token;

use BibSpace::Functions::FDB;
use BibSpace::Functions::UserObj; 



####################################################################################################
sub new { 
    my $class = shift;
    my $self = {};
    bless $self, $class;

    return $self;
    # bless {}, shift # the same but shorter :)
};
####################################################################################################
sub check {
    my ($self, $user, $pass, $dbh) = @_;
    $self->insert_admin($dbh);

    my $hash_from_db = $self->get_user_hash($user, $dbh);
    return 0 if !defined $hash_from_db;

    if(defined $hash_from_db and defined $pass and $self->check_password($pass, $hash_from_db)==1){
        $self->record_logging_in($user, $dbh);
        return 1;
    }

    # Fail
    return 0;
}

####################################################################################################
sub generate_token{
    my $self = shift;

    my $token = Session::Token->new(length => 32)->get;
    return $token

}
####################################################################################################
sub save_token_email{
    my $self = shift;
    my $token = shift; 
    my $email = shift; 
    my $user_dbh = shift;

    my $sth = $user_dbh->prepare("INSERT INTO Token (requested, email, token) VALUES (CURRENT_TIMESTAMP, ?,?)");
    $sth->execute($email, $token);  
}
####################################################################################################
sub get_token_for_email {  #### FOR TESTING ONLY
    my $self = shift;
    my $email = shift; 
    my $user_dbh = shift;

    my $sth = $user_dbh->prepare("SELECT token, email FROM Token WHERE email=?");
    $sth->execute($email);

    my $row = $sth->fetchrow_hashref();
    return $row->{token} || -1;
}
####################################################################################################
sub remove_all_tokens_for_email{
    my $self = shift;
    my $email = shift; 
    my $user_dbh = shift;

    my $sth = $user_dbh->prepare("DELETE FROM Token WHERE email=?");
    $sth->execute($email);  
}
####################################################################################################
sub remove_token{
    my $self = shift;
    my $token = shift; 
    my $user_dbh = shift;

    my $sth = $user_dbh->prepare("DELETE FROM Token WHERE token=?");
    $sth->execute($token);  
}
####################################################################################################
sub get_email_for_token{
    my $self = shift;
    my $token = shift; 
    my $user_dbh = shift;

    my $sth = $user_dbh->prepare("SELECT email FROM Token WHERE token=?");
    $sth->execute($token);

    my $row = $sth->fetchrow_hashref();
    return $row->{email};
};
####################################################################################################
sub get_login_for_id{
    my $self = shift;
    my $id = shift; 
    my $user_dbh = shift;

    my $sth = $user_dbh->prepare("SELECT login FROM Login WHERE id=?");
    $sth->execute($id);

    my $row = $sth->fetchrow_hashref();
    return $row->{login} || 0;
};
####################################################################################################
sub get_email{
    my $self = shift;
    my $login = shift; 

    my $user_dbh = shift;
    my $sth = $user_dbh->prepare("SELECT email FROM Login WHERE login=?");
    $sth->execute($login);

    my $row = $sth->fetchrow_hashref();
    return $row->{email} || 0;
};
####################################################################################################
sub get_registration_time{
    my $self = shift;
    my $login = shift; 

    my $user_dbh = shift;
    my $sth = $user_dbh->prepare("SELECT registration_time FROM Login WHERE login=?");
    $sth->execute($login);

    my $row = $sth->fetchrow_hashref();
    return $row->{registration_time};
};
####################################################################################################
sub get_last_login{
    my $self = shift;
    my $login = shift; 

    my $user_dbh = shift;
    my $sth = $user_dbh->prepare("SELECT last_login FROM Login WHERE login=?");
    $sth->execute($login);

    my $row = $sth->fetchrow_hashref();
    return $row->{last_login};
};
####################################################################################################
sub get_rank{
    my $self = shift;
    my $login = shift; 
    my $user_dbh = shift;

    my $sth = $user_dbh->prepare("SELECT rank FROM Login WHERE login=?");
    $sth->execute($login);

    my $row = $sth->fetchrow_hashref();
    return $row->{rank} || 0;
};
####################################################################################################
sub login_exists{
    my $self = shift;
    my $uname = shift; 
    my $user_dbh = shift;

    my $sth = $user_dbh->prepare("SELECT COUNT(*) AS num FROM Login WHERE login=?");
    $sth->execute($uname);
    my $row = $sth->fetchrow_hashref();
    my $num = $row->{num} || 0;
    return $num>0;
};
####################################################################################################
sub email_exists{
    my $self = shift;
    my $email = shift; 
    my $user_dbh = shift;

    my $sth = $user_dbh->prepare("SELECT COUNT(*) AS num FROM Login WHERE email=?");
    $sth->execute($email);
    my $row = $sth->fetchrow_hashref();
    my $num = $row->{num} || 0;
    return $num>0;
};
####################################################################################################
sub get_email_for_uname{
    my $self = shift;
    my $uname = shift; 

    my $user_dbh = shift;
    my $sth = $user_dbh->prepare("SELECT email FROM Login WHERE login=?");
    $sth->execute($uname);
    my $row = $sth->fetchrow_hashref();
    return $row->{email};
};
####################################################################################################
sub set_new_password{
    my $self = shift; 
    my $email = shift; 
    my $pass_plaintext = shift;
    my $user_dbh = shift;

    if(defined $email and length($email)>3 and defined $pass_plaintext and length($pass_plaintext)>3){
        my $salt = salt();
        my $hash = encrypt_password($pass_plaintext, $salt);

        my $sth = $user_dbh->prepare("UPDATE Login SET pass=?, pass2=? WHERE email=?");
        $sth->execute($hash, $salt, $email);
        return 1;
    }
    return 0;
};

####################################################################################################
sub do_delete_user{
    my $self = shift;
    my $id = shift; 
    my $dbh = shift;

    my $usr_obj = BibSpace::Functions::UserObj->new({id => $id});
    $usr_obj->initFromDB($dbh);
    
    if($self->login_exists($usr_obj->{login}, $dbh) and $usr_obj->is_admin() == 0){
        my $sth = $dbh->prepare("DELETE FROM Login WHERE id=?");
        $sth->execute($id);   
        return 1; 
    }
    return 0;
};

####################################################################################################
sub promote_to_manager{
    my $self = shift;
    my $id = shift; 
    my $dbh = shift;

    my $usr_obj = UserObj->new({id => $id});
    $usr_obj->initFromDB($dbh);
    
    if($self->login_exists($usr_obj->{login}, $dbh) and $usr_obj->is_admin() == 0){
        my $sth = $dbh->prepare("DELETE FROM Login WHERE id=?");
        $sth->execute($id);    
    }
};
####################################################################################################
sub add_new_user{
    my $self = shift; 
    my $uname = shift; 
    my $email = shift; 
    my $name = shift || "unnamed"; 
    my $pass_plaintext = shift;
    my $rank = shift || "0"; 
    my $user_dbh = shift;

    if(defined $uname and length($uname)>1 and defined $email and length($email)>3 and defined $pass_plaintext and length($pass_plaintext)>3){
        my $salt = salt();
        my $hash = encrypt_password($pass_plaintext, $salt);


        my $sth = $user_dbh->prepare("INSERT IGNORE INTO Login (login, email, pass, pass2, real_name, rank) VALUES (?,?,?,?,?,?)");
        $sth->execute($uname, $email, $hash, $salt, $name, $rank);
    }
};
####################################################################################################
sub insert_admin{
    my $self = shift;
    my $dbh = shift;
    $self->add_new_user("pub_admin", 'your_email@email.com', "Admin", "asdf", "3", $dbh);
};
####################################################################################################
sub get_user_hash{
    my $self = shift;
    my $login = shift;
    my $user_dbh = shift;

    return 0 if !defined $login or $login eq '';

    

    my $sth = $user_dbh->prepare("SELECT login, pass FROM Login WHERE login=?");
    $sth->execute($login);
    my $row = $sth->fetchrow_hashref();
    my $hash = $row->{pass};

    return $hash;
};
####################################################################################################
sub get_user_real_name{
    my $self = shift;
    my $login = shift;
    my $user_dbh = shift;

    return 0 if !defined $login or $login eq '';


    my $sth = $user_dbh->prepare("SELECT real_name FROM Login WHERE login=?");
    $sth->execute($login);
    my $row = $sth->fetchrow_hashref();
    my $real_name = $row->{real_name};

    return $real_name;
}
####################################################################################################
sub record_logging_in{
    my $self = shift;
    my $login = shift;
    my $user_dbh = shift;

    return 0 if !defined $login or $login eq '';

    my $sth = $user_dbh->prepare("UPDATE Login SET last_login=CURRENT_TIMESTAMP WHERE login=?");
    $sth->execute($login);
};



################################################################
############################ BCRYPT ############################
################################################################

sub encrypt_password {
    my $password = shift;
     
    # Generate a salt if one is not passed
    my $salt = shift || salt();
     
    # Set the cost to 8 and append a NUL
    my $settings = '$2a$08$'.$salt;
     
    # Encrypt it
    return Crypt::Eksblowfish::Bcrypt::bcrypt($password, $settings);
}


sub check_password {
    my ($self, $plain_password, $hashed_password) = @_;
     
    # Regex to extract the salt
    if ($hashed_password =~ m!^\$2a\$\d{2}\$([A-Za-z0-9+\\.\/]{22})!) {
     
        # Use a letter by letter match rather than a complete string match to avoid timing attacks
        my $match = encrypt_password($plain_password, $1);
        my $bad = 0;
        for (my $n=0; $n < length $match; $n++) {
            $bad++ if substr($match, $n, 1) ne substr($hashed_password, $n, 1);
        }
         
        return $bad == 0;
    } 
    else {
        return 0;
    }
}

sub salt {
    return Crypt::Eksblowfish::Bcrypt::en_base64(Crypt::Random::makerandom_octet(Length=>16));
}

1;