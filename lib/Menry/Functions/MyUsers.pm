package Menry::Functions::MyUsers;
use Menry::Controller::DB;
use Menry::Schema;

use strict;
use warnings;
use Crypt::Eksblowfish::Bcrypt qw(bcrypt bcrypt_hash en_base64); # sudo cpanm Crypt::Eksblowfish::Bcrypt
use Crypt::Random; # sudo cpanm Crypt::Random
use LWP::UserAgent;
use Session::Token;
use WWW::Mailgun;

use feature 'say';


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
    print "call Menry::Functions::MyUsers check \n";
    my ($self, $user, $pass, $dbh) = @_;

    $self->insert_admin($dbh);

    my $hash_from_db = $self->get_user_hash($user, $dbh);
    return undef if !defined $hash_from_db;

    if(defined $hash_from_db and defined $pass and $self->check_password($pass, $hash_from_db)==1){
        $self->record_logging_in($user, $dbh);
        return 1;
    }

    # Fail
    return undef;
}
####################################################################################################
sub send_email{
    my $self = shift;
    my $token = shift;
    my $email = shift;

    my $msg = "
    To reset the password on the production server, click: 
    http://se2.informatik.uni-wuerzburg.de/pa/forgot/reset/$token 

    If you intend to reset your password on the TEST server, follow this link: 
    http://146.185.144.116:8080/forgot/reset/$token";

    my $subject = 'Publiste password reset';

    

    my $mg = WWW::Mailgun->new({ 
        key => 'key-63d3ad88cb84764a78730eda3aee0973',
        domain => 'sandbox438e3009fd1e48f9b6d9315567d7808d.mailgun.org',
        from => 'Mailgun Sandbox <postmaster@sandbox438e3009fd1e48f9b6d9315567d7808d.mailgun.org>' # Optionally set here, you can set it when you send
    });

     $mg->send({
          to => $email,
          subject => $subject,
          text => $msg,
    });
  
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
    my $dbh = shift;

    my $new_token = $dbh->resultset('Token')->find_or_create({ 
                                                    requested => undef,
                                                    email => $email,
                                                    token => $token,
                                                    });
    return $new_token->in_storage();
}
####################################################################################################
sub get_token_for_email {  #### FOR TESTING ONLY
    my $self = shift;
    my $email = shift; 
    my $dbh = shift;

    return $dbh->resultset('Token')->search({ email => $email })->get_column('token')->first;
};
####################################################################################################
sub remove_all_tokens_for_email{
    my $self = shift;
    my $email = shift; 
    my $dbh = shift;

    return $dbh->resultset('Token')->search({ email => $email })->delete;
};
####################################################################################################
sub remove_token{
    my $self = shift;
    my $token = shift; 
    my $dbh = shift;

    return $dbh->resultset('Token')->search({ token => $token })->delete;
};
####################################################################################################
sub get_email_for_token{
    my $self = shift;
    my $token = shift; 
    my $dbh = shift;

    return $dbh->resultset('Token')->search({ token => $token })->get_column('email')->first;
};
####################################################################################################
sub get_login_for_id{
    my $self = shift;
    my $id = shift; 
    my $dbh = shift;

    my $u = $dbh->resultset('Login')->find({ id => $id });
    return $u->login if defined $u;
    return undef;
};
####################################################################################################
sub get_email{
    my $self = shift;
    say "!!! OBSOLETE !!! call Menry::Functions::MyUsers: get_email";

    return $self->get_email_for_uname(shift, shift);
};
####################################################################################################
sub get_registration_time{
    my $self = shift;
    my $login = shift; 
    my $dbh = shift;

    return $dbh->resultset('Login')->search({ login => $login })->get_column('registration_time')->first;
};
####################################################################################################
sub get_last_login{
    my $self = shift;
    my $login = shift; 
    my $dbh = shift;

    return $dbh->resultset('Login')->search({ login => $login })->get_column('last_login')->first;
};
####################################################################################################
sub get_rank{
    my $self = shift;
    my $login = shift; 
    my $dbh = shift;

    return $dbh->resultset('Login')->search({ login => $login })->get_column('rank')->first;
};
####################################################################################################
sub login_exists{
    my $self = shift;
    my $uname = shift; 
    my $dbh = shift;

    my $num = $dbh->resultset('Login')->search({ login => $uname })->count;
    return $num>0;
};
####################################################################################################
sub email_exists{
    my $self = shift;
    my $email = shift; 
    my $dbh = shift;

    my $num = $dbh->resultset('Login')->search({ email => $email })->count;
    return $num>0;
    
};
####################################################################################################
sub get_email_for_uname{
    my $self = shift;
    my $uname = shift; 
    my $dbh = shift;

    return $dbh->resultset('Login')->search({ login => $uname })->get_column('email')->first;
};
####################################################################################################
sub set_new_password{
    my $self = shift; 
    my $email = shift; 
    my $pass_plaintext = shift;
    my $dbh = shift;

    if(defined $email and length($email)>3 and defined $pass_plaintext and length($pass_plaintext)>3){
        my $salt = salt();
        my $hash = encrypt_password($pass_plaintext, $salt);

        my $u = $dbh->resultset('Login')->search({ email => $email });
        my $result = $u->update({pass => $hash, pass2 => $salt});
        return 1 if defined $result;
    }
    return 0;
};

####################################################################################################
sub do_delete_user{
    my $self = shift;
    my $id = shift; 
    my $dbh = shift;

    my $user_rs = $dbh->resultset('Login')->find({ id => $id });
    return undef if !defined $user_rs;

    my $usr = $user_rs;
    
    if($self->login_exists($usr->login, $dbh)){ # and !defined $usr_obj->is_admin()){

        return $dbh->resultset('Login')->search({ id => $id })->first->delete;
    }
};

####################################################################################################
sub promote_to_manager{
    my $self = shift;
    my $id = shift; 
    my $dbh = shift;

    my $u = $dbh->resultset('Login')->search({ id => $id });
    my $result = $u->update({rank => 1});
    return 1 if defined $result;
};
####################################################################################################
sub add_new_user{
    my $self = shift; 
    my $uname = shift; 
    my $email = shift; 
    my $name = shift || "unnamed"; 
    my $pass_plaintext = shift;
    my $rank = shift || "0"; 

    my $schema = shift; 

    print "call Menry::Functions::MyUsers add_new_user \n";

    if(defined $uname 
        and length($uname)>1 
        and defined $email 
        and length($email)>3 
        and defined $pass_plaintext 
        and length($pass_plaintext)>3){

        my $salt = salt();
        my $hash = encrypt_password($pass_plaintext, $salt);
        
        my $new_user = $schema->resultset('Login')->find_or_create({ 
                                                    login => $uname,
                                                    email => $email,
                                                    pass => $hash,
                                                    pass2 => $salt,
                                                    real_name => $name,
                                                    rank => $rank
                                                    });
        return $new_user->in_storage();
        # $new_user->insert;
    }
    return 0;
};
####################################################################################################
sub insert_admin{
    my $self = shift;
    my $dbh = shift;

    print "call Menry::Functions::MyUsers insert_admin \n";

    return $self->add_new_user("pub_admin", 'your_email@email.com', "Admin", "asdf", "3", $dbh);
};
####################################################################################################
sub get_user_hash{
    my $self = shift;
    my $login = shift;
    my $dbh = shift;

    return undef if !defined $login;
    return $dbh->resultset('Login')->search({ login => $login })->get_column('pass')->first;
    # return $u->pass if defined $u;
};
####################################################################################################
sub get_user_real_name{
    my $self = shift;
    my $login = shift;
    my $dbh = shift;

    return undef if !defined $login;
    return $dbh->resultset('Login')->search({ login => $login })->get_column('real_name')->first;
}
####################################################################################################
sub record_logging_in{
    my $self = shift;
    my $login = shift;
    my $dbh = shift;

    return undef if !defined $login;

    # my $u = $dbh->resultset('Login')->search({ email => $email });
    #     my $result = $u->update({pass => $hash, pass2 => $salt});
    #     return 1 if defined $result;
  
    my $row = $dbh->resultset('Login')->search({ login => $login });
    return $row->update({last_login => \"current_timestamp"});
    
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