package CMUsers;


# C - Container
# M - Model

# TODO: this should be refactored to MUser. Only container-related functions should remain
# TODO: refactor-out Tokens and security functions

use strict;
use warnings;
use Crypt::Eksblowfish::Bcrypt qw(bcrypt bcrypt_hash en_base64);
use Crypt::Random;
use LWP::UserAgent;
use Session::Token;

use BibSpace::Functions::FDB;
use BibSpace::Model::MUser;

use Moose;

####################################################################################################
sub check {
    my ( $self, $user, $input_pass, $dbh ) = @_;


    $self->insert_admin($dbh);

    my $usrobj = MUser->static_get_by_login($dbh, $user);

    return 0 if !defined $usrobj->{pass};

    if ($self->check_password( $input_pass, $usrobj->{pass} ) == 1 ){
        $self->record_logging_in( $user, $dbh );
        return 1;
    }
    # bad password
    return 0;
}


####################################################################################################
sub email_exists {
    my $self     = shift;
    my $email    = shift;
    my $user_dbh = shift;

    my $sth = $user_dbh->prepare(
        "SELECT COUNT(*) AS num FROM Login WHERE email=?");
    $sth->execute($email);
    my $row = $sth->fetchrow_hashref();
    my $num = $row->{num} || 0;
    return $num > 0;
}

####################################################################################################
sub set_new_password {
    my $self           = shift;
    my $email          = shift;
    my $pass_plaintext = shift;
    my $dbh       = shift;

    if (    defined $email
        and length($email) > 3
        and defined $pass_plaintext
        and length($pass_plaintext) > 3 )
    {
        my $salt = salt();
        my $hash = encrypt_password( $pass_plaintext, $salt );

        my $sth = $dbh->prepare(
            "UPDATE Login SET pass=?, pass2=? WHERE email=?");
        $sth->execute( $hash, $salt, $email );
        return 1;
    }
    return 0;
}

####################################################################################################
sub do_delete_user {
    my $self = shift;
    my $id   = shift;
    my $dbh  = shift;

    my $usr_obj = MUser->static_get( $dbh, $id );

    if (    defined $usr_obj
        and $usr_obj->is_admin() == 0 )
    {
        my $sth = $dbh->prepare("DELETE FROM Login WHERE id=?");
        $sth->execute($id);
        return 1;
    }
    return 0;
}


####################################################################################################
sub add_new_user {
    my $self           = shift;
    my $uname          = shift;
    my $email          = shift;
    my $name           = shift || "unnamed";
    my $pass_plaintext = shift;
    my $rank           = shift || "0";
    my $user_dbh       = shift;

    if (    defined $uname
        and length($uname) > 1
        and defined $email
        and length($email) > 3
        and defined $pass_plaintext
        and length($pass_plaintext) > 3 )
    {
        my $salt = salt();
        my $hash = encrypt_password( $pass_plaintext, $salt );


        my $sth = $user_dbh->prepare(
            "INSERT IGNORE INTO Login 
                                     (login, email, pass, pass2, real_name, rank, registration_time, last_login) 
                                     VALUES (?,?,?,?,?,?,NOW(),'1970-01-01 01:01:01')
                                     "
        );
        $sth->execute( $uname, $email, $hash, $salt, $name, $rank );
    }
}
####################################################################################################
sub insert_admin {
    my $self = shift;
    my $dbh  = shift;
    $self->add_new_user( "pub_admin", 'your_email@email.com', "Admin",
        "asdf", "3", $dbh );
}
####################################################################################################
sub get_user_real_name {
    my $self     = shift;
    my $login    = shift;
    my $user_dbh = shift;

    return 0 if !defined $login or $login eq '';


    my $sth = $user_dbh->prepare("SELECT real_name FROM Login WHERE login=?");
    $sth->execute($login);
    my $row       = $sth->fetchrow_hashref();
    my $real_name = $row->{real_name};

    return $real_name;
}
####################################################################################################
sub record_logging_in {
    my $self     = shift;
    my $login    = shift;
    my $user_dbh = shift;

    return 0 if !defined $login or $login eq '';

    my $sth = $user_dbh->prepare(
        "UPDATE Login SET last_login=CURRENT_TIMESTAMP WHERE login=?");
    $sth->execute($login);
}


################################################################
############################ BCRYPT ############################
################################################################


####################################################################################################
sub encrypt_password {
    my $password = shift;

    # Generate a salt if one is not passed
    my $salt = shift || salt();

    # Set the cost to 8 and append a NUL
    my $settings = '$2a$08$' . $salt;

    # Encrypt it
    return Crypt::Eksblowfish::Bcrypt::bcrypt( $password, $settings );
}

####################################################################################################
sub check_password {
    my ( $self, $plain_password, $hashed_password ) = @_;

    return 0 if !defined $plain_password or $plain_password eq '';

    # Regex to extract the salt
    if ( $hashed_password =~ m!^\$2a\$\d{2}\$([A-Za-z0-9+\\.\/]{22})! ) {

# Use a letter by letter match rather than a complete string match to avoid timing attacks
        my $match = encrypt_password( $plain_password, $1 );
        my $bad = 0;
        for ( my $n = 0; $n < length $match; $n++ ) {
            $bad++
                if substr( $match, $n, 1 ) ne
                substr( $hashed_password, $n, 1 );
        }

        return $bad == 0;
    }
    else {
        return 0;
    }
}
####################################################################################################
sub salt {
    return Crypt::Eksblowfish::Bcrypt::en_base64(
        Crypt::Random::makerandom_octet( Length => 16 ) );
}
####################################################################################################


################################################################
############################ TOKENS ############################
################################################################


####################################################################################################
sub generate_token {
    my $self = shift;

    my $token = Session::Token->new( length => 32 )->get;
    return $token

}
####################################################################################################
sub save_token_email {
    my $self     = shift;
    my $token    = shift;
    my $email    = shift;
    my $user_dbh = shift;

    # there should be only one active token!
    my $sth = $user_dbh->prepare("DELETE FROM Token WHERE email=?");
    $sth->execute($email);

    my $sth2
        = $user_dbh->prepare(
        "INSERT INTO Token (requested, email, token) VALUES (CURRENT_TIMESTAMP, ?,?)"
        );
    $sth2->execute( $email, $token );
}
####################################################################################################
sub get_token_for_email {    #### FOR TESTING ONLY
    my $self     = shift;
    my $email    = shift;
    my $user_dbh = shift;

    my $sth
        = $user_dbh->prepare("SELECT token, email FROM Token WHERE email=?");
    $sth->execute($email);

    my $row = $sth->fetchrow_hashref();
    return $row->{token} || -1;
}
####################################################################################################
sub remove_all_tokens_for_email {
    my $self     = shift;
    my $email    = shift;
    my $user_dbh = shift;

    my $sth = $user_dbh->prepare("DELETE FROM Token WHERE email=?");
    $sth->execute($email);
}
####################################################################################################
sub remove_token {
    my $self     = shift;
    my $token    = shift;
    my $user_dbh = shift;

    my $sth = $user_dbh->prepare("DELETE FROM Token WHERE token=?");
    $sth->execute($token);
}
####################################################################################################
sub get_email_for_token {
    my $self     = shift;
    my $token    = shift;
    my $user_dbh = shift;

    my $sth = $user_dbh->prepare("SELECT email FROM Token WHERE token=?");
    $sth->execute($token);

    my $row = $sth->fetchrow_hashref();
    return $row->{email};
}
1;
