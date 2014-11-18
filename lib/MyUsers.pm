package MyUsers;

use strict;
use warnings;


# use Crypt::PBKDF2;  # sudo cpanm Crypt::PBKDF2
use Crypt::Eksblowfish::Bcrypt qw(bcrypt bcrypt_hash en_base64); # sudo cpanm Crypt::Eksblowfish::Bcrypt
use Crypt::Random; # sudo cpanm Crypt::Random
use LWP::UserAgent;

# use Email::Send;
# use Email::Send::Gmail;
# use Email::Simple::Creator;

# my $USERS = {
#   pub_admin    => 'asdf'
# };
####################################################################################################
sub new { 
    my $class = shift;
    my $self = {};
    bless $self, $class;

    prepare_backup_table();

    return $self;
    # bless {}, shift # the same but shorter :)
};
####################################################################################################
sub check {
    my ($self, $user, $pass) = @_;

    $self->insert_admin();

    my $hash_from_db = $self->get_user_hash($user);
    return undef if !defined $hash_from_db;

    if(defined $hash_from_db and defined $pass and $self->check_password($pass, $hash_from_db)==1){
        $self->record_logging_in($user);
        return 1;
    }

    # Fail
    return undef;
}



####################################################################################################
sub db{
    my $dbh = DBI->connect('dbi:SQLite:dbname=user.db', '', '') or die $DBI::errstr;
    return $dbh;
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

    use WWW::Mailgun;

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

    my @chars = ('0'..'9', 'A'..'Z', 'a'..'z');
    my $len = 32;
    my $string;
    while($len--){ 
        $string .= $chars[rand @chars] 
    };
    return $string;
}

####################################################################################################
sub prepare_backup_table{
    my $self = shift;
    my $user_dbh = db();


   $user_dbh->do("CREATE TABLE IF NOT EXISTS Login(
        id INTEGER PRIMARY KEY,
        registration_time DATE DEFAULT (datetime('now','localtime')),
        last_login DATE DEFAULT (datetime('now','localtime')),
        login TEXT NOT NULL,
        real_name TEXT DEFAULT 'unnamed',
        email TEXT NOT NULL,
        pass TEXT NOT NULL,
        pass2 TEXT DEFAULT NULL,
        pass3 TEXT DEFAULT NULL,
        rank INTEGER DEFAULT 0,
        master_id INTEGER DEFAULT 0,
        tennant_id INTEGER DEFAULT 0,
        UNIQUE(login) ON CONFLICT IGNORE
      )");

      $user_dbh->do("CREATE TABLE IF NOT EXISTS Token(
        id INTEGER PRIMARY KEY,
        token TEXT NOT NULL,
        email TEXT NOT NULL,
        UNIQUE(token) ON CONFLICT IGNORE
      )");
};
####################################################################################################
sub save_token_email{
    my $self = shift;
    my $token = shift; 
    my $email = shift; 
    my $user_dbh = db();

    my $sth = $user_dbh->prepare("REPLACE INTO Token (id, email, token) VALUES (null, ?,?)");
    $sth->execute($email, $token);  
}
####################################################################################################
sub remove_token{
    my $self = shift;
    my $token = shift; 
    my $user_dbh = db();

    my $sth = $user_dbh->prepare("DELETE FROM Token WHERE token=?");
    $sth->execute($token);  
}
####################################################################################################
sub get_email_for_token{
    my $self = shift;
    my $token = shift; 

    my $user_dbh = db();
    my $sth = $user_dbh->prepare("SELECT email FROM Token WHERE token=?");
    $sth->execute($token);

    my $row = $sth->fetchrow_hashref();
    return $row->{email};
};
####################################################################################################
sub get_email{
    my $self = shift;
    my $login = shift; 

    my $user_dbh = db();
    my $sth = $user_dbh->prepare("SELECT email FROM Login WHERE login=?");
    $sth->execute($login);

    my $row = $sth->fetchrow_hashref();
    return $row->{email} || 0;
};
####################################################################################################
sub get_registration_time{
    my $self = shift;
    my $login = shift; 

    my $user_dbh = db();
    my $sth = $user_dbh->prepare("SELECT registration_time FROM Login WHERE login=?");
    $sth->execute($login);

    my $row = $sth->fetchrow_hashref();
    return $row->{registration_time};
};
####################################################################################################
sub get_last_login{
    my $self = shift;
    my $login = shift; 

    my $user_dbh = db();
    my $sth = $user_dbh->prepare("SELECT last_login FROM Login WHERE login=?");
    $sth->execute($login);

    my $row = $sth->fetchrow_hashref();
    return $row->{last_login};
};
####################################################################################################
sub get_rank{
    my $self = shift;
    my $login = shift; 

    my $user_dbh = db();
    my $sth = $user_dbh->prepare("SELECT rank FROM Login WHERE login=?");
    $sth->execute($login);

    my $row = $sth->fetchrow_hashref();
    return $row->{rank} || 0;
};
####################################################################################################
sub login_exists{
    my $self = shift;
    my $uname = shift; 

    my $user_dbh = db();
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

    my $user_dbh = db();
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

    my $user_dbh = db();
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
    my $user_dbh = db();

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
sub add_new_user{
    my $self = shift; 
    my $uname = shift; 
    my $email = shift; 
    my $name = shift || "unnamed"; 
    my $pass_plaintext = shift;
    my $rank = shift || "0"; 
    my $user_dbh = db();

    if(defined $uname and length($uname)>1 and defined $email and length($email)>3 and defined $pass_plaintext and length($pass_plaintext)>3){
        my $salt = salt();
        my $hash = encrypt_password($pass_plaintext, $salt);

        my $sth = $user_dbh->prepare("REPLACE INTO Login (login, email, pass, pass2, real_name, rank) VALUES (?,?,?,?,?,?)");
        $sth->execute($uname, $email, $hash, $salt, $name, $rank);
    }
};
####################################################################################################
sub insert_admin{
    my $self = shift;
    # $self->add_new_user("pub_admin", 'piotr.rygielski@uni-wuerzburg.de', "Admin", "asdf", "3");
};
####################################################################################################
sub get_user_hash{
    my $self = shift;
    my $login = shift;

    return undef if !defined $login;

    my $user_dbh = db();

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

    return undef if !defined $login;

    my $user_dbh = db();

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

    return undef if !defined $login;
    
    my $user_dbh = db();

    my $sth = $user_dbh->prepare("UPDATE Login SET last_login=datetime('now','localtime') WHERE login=?");
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