package Hex64Publications::Functions::LoginFunctions;

use strict;
use warnings;
use Crypt::Eksblowfish::Bcrypt qw(bcrypt bcrypt_hash en_base64); # sudo cpanm Crypt::Eksblowfish::Bcrypt
use Crypt::Random; # sudo cpanm Crypt::Random
use WWW::Mailgun;

use Exporter;
our @ISA= qw( Exporter );

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw( 
    check
    add_new_user
    insert_admin
    set_new_password
    encrypt_password
    check_password
    salt
    generate_token
    send_email
    );

# ####################################################################################
####################################################################################################
sub check {
    print "call Hex64Publications::Controller::Login check \n";
    my ($user, $pass, $dbh) = @_;

    insert_admin($dbh);

    my $hash = $dbh->resultset('Login')->search({ login => $user })->get_column('pass')->first;
    return undef if !defined $hash;

    return 1 if defined $pass and check_password($pass, $hash)==1;
    return undef;
}
####################################################################################################
sub add_new_user{
    my $uname = shift; 
    my $email = shift; 
    my $name = shift || "unnamed"; 
    my $pass_plaintext = shift;
    my $rank = shift || "0"; 
    my $schema = shift; 

    print "call Hex64Publications::Functions::MyUsers add_new_user \n";

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
    my $dbh = shift;
    return add_new_user("pub_admin", 'your_email@email.com', "Admin", "asdf", "3", $dbh);
};
####################################################################################################
sub set_new_password{
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

################################################################
############################ BCRYPT ############################
################################################################
####################################################################################################
sub encrypt_password {
    my $password = shift;
     
    # Generate a salt if one is not passed
    my $salt = shift || salt();
     
    # Set the cost to 8 and append a NUL
    my $settings = '$2a$08$'.$salt;
     
    # Encrypt it
    return Crypt::Eksblowfish::Bcrypt::bcrypt($password, $settings);
}

####################################################################################################
sub check_password {
    my ($plain_password, $hashed_password) = @_;
     
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
####################################################################################################
sub salt {
    return Crypt::Eksblowfish::Bcrypt::en_base64(Crypt::Random::makerandom_octet(Length=>16));
}
####################################################################################################
sub generate_token{
    my $token = Session::Token->new(length => 32)->get;
    return $token

}
####################################################################################################
####################################################################################################
####################################################################################################
sub send_email{
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



1;