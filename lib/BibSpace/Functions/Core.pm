package BibSpace::Functions::Core;

use BibSpace::Functions::FDB;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
# use File::Slurp;
use File::Find;

use v5.16;           #because of ~~
use Cwd;
use strict;
use warnings;


### Security
use Crypt::Eksblowfish::Bcrypt qw(bcrypt bcrypt_hash en_base64);
use Crypt::Random;
use Session::Token;

### Posting to Mailgun
use WWW::Mechanize;

# for latex decode
require TeX::Encode;
use Encode;


# use BibSpace::Functions::FPublications;

use Exporter;
our @ISA = qw( Exporter );
use List::MoreUtils qw(any uniq);

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw(
  sort_publications
  fix_bibtex_national_characters
  get_dir_size
  validate_registration_data
  check_password_policy
  generate_token
  encrypt_password
  salt
  check_password
  send_email
  split_bibtex_entries
  decodeLatex
  official_bibtex_types
  random_string
  create_user_id
  uniqlc
  get_generic_type_description
  nohtml
  clean_tag_name
  get_month_numeric
  get_current_year
  get_current_month
);


####################################################################################################
sub sort_publications {
  my (@pubs) = @_;
  return reverse sort{ $a->year <=> $b->year or $a->month <=> $b->month or $a->bibtex_key cmp $b->bibtex_key } @pubs;
}
####################################################################################################
=item fix_bibtex_national_characters
  This function should help to avoid bibtex=>html warnings of BibStyle, like this:
  line 5, warning: found " at brace-depth zero in string (TeX accents in BibTeX should be inside braces)
=cut
sub fix_bibtex_national_characters {
    my $str  = shift;
    
    # matches / not followed by bob: /^\/(?!bob\/)/
    # matches a word that follows a tab /(?<=\t)\w+/ 

    # s/(foo)bar/$1/g; - removes bar after foo
    # s/foo\Kbar//g; - removes bar after foo

    # /(?<!bar)foo/ matches any occurrence of "foo" that does not follow "bar"

    use utf8; # for \w

    # makes sth \'x sth --> sth {\'x} sth
    $str =~ s/(?<!\{)(\\'\w)(?!\})/\{$1\}/g;

    # makes sth \'{x} sth --> sth {\'x} sth
    $str =~ s/\\'\{(\w+)\}/\{\\'$1\}/g;

    # makes sth \"{x} sth --> sth {\"x} sth
    $str =~ s/\\"\{(\w+)\}/\{\\"$1\}/g;

    # makes sth \"x sth --> sth {\"x} sth
    $str =~ s/(?<!\{)(\\"\w)(?!\})/\{$1\}/g;

    # makes sth \^x sth --> sth {\^x} sth
    $str =~ s/(?<!\{)(\\^\w)(?!\})/\{$1\}/g;

    # makes sth \~x sth --> sth {\~x} sth
    $str =~ s/(?<!\{)(\\~\w)(?!\})/\{$1\}/g;

    # makes sth \aa sth --> sth {\aa} sth
    $str =~ s/(?<!\{)\\aa(?!\})/\{\\aa}/g;

    # makes sth \l sth --> sth {\l} sth
    $str =~ s/(?<!\{)\\l(?!\})/\{\\l}/g;

    # makes sth \ss sth --> sth {\ss} sth
    $str =~ s/(?<!\{)\\ss(?!\})/\{\\ss}/g;

    # if( $str =~ /(?<!\{)(\\".)(?!\})/ ){
    #   say "BEFORE:" .$str;
    #   $str =~ s/(?<!\{)(\\".)(?!\})/\{$1\}/g;
    #   say "AFTER:" .$str;
    # }
    # if( $str =~ /(?<!\{)(\\".)(?!\})/ ){
    #   say "NOT FIXED!!!";
    # }
    # else{
    #   say "FIXED OK!";
    # }

    

    

    return $str;
}
####################################################################################################
sub get_dir_size {
    my $dir  = shift;
    my $size = 0;
    find( sub { $size += -f $_ ? -s _ : 0 }, $dir );
    return $size;
}
####################################################################################################
sub validate_registration_data {
    my $login = shift;
    my $email = shift;
    my $pass1 = shift;
    my $pass2 = shift;

    if($pass1 ne $pass2){
      die "Passwords don't match!\n";    
    }
    if(!check_password_policy($pass1)){
      die "Password is too short, use minimum 4 symbols.\n";
    }
    if(!$login or length($login) == 0){
      die "Login is missing.\n";
    }
    if(!$email or length($email) == 0){
      die "Email is missing.\n";
    }
    return 1;
}
####################################################################################################
sub check_password_policy {
    my $pass = shift;
    return 1 if length($pass) > 3;
    return;
}
####################################################################################################
sub generate_token {
    my $self = shift;
    my $token = Session::Token->new( length => 32 )->get;
    return $token
}
####################################################################################################
sub encrypt_password {
    my $password = shift;
    my $salt = shift || salt();
    # Generate a salt if one is not passed
    
    # Set the cost to 8 and append a NULL
    my $settings = '$2a$08$' . $salt;
    # Encrypt it
    return Crypt::Eksblowfish::Bcrypt::bcrypt( $password, $settings );
}
####################################################################################################
sub salt {
    return Crypt::Eksblowfish::Bcrypt::en_base64(
        Crypt::Random::makerandom_octet( Length => 16 ) );
}
####################################################################################################
sub check_password {
    my $plain_password  = shift;
    my $hashed_password = shift;

    return if !defined $plain_password or $plain_password eq '';

    # Regex to extract the salt
    if ( $hashed_password =~ m!^\$2a\$\d{2}\$([A-Za-z0-9+\\.\/]{22})! ) {
        # Use a letter by letter match rather than a complete string match to avoid timing attacks
        my $match = encrypt_password( $plain_password, $1 );
        for ( my $n = 0; $n < length $match; $n++ ) {
          if( substr( $match, $n, 1 ) ne substr( $hashed_password, $n, 1 ) ){
            return;
          }
        }
        return 1;
    }
    return;
}
####################################################################################################
####################################################################################################
sub send_email {  
    my $config = shift;

    

    my $uri = "https://api.mailgun.net/v3/".$config->{mailgun_domain}."/messages";

    my $mech = WWW::Mechanize->new( ssl_opts => { SSL_version => 'TLSv1' } );
    $mech->credentials( api => $config->{mailgun_key} );
    $mech->ssl_opts( verify_hostname => 0 );
    $mech->post( $uri,
        [   from    => $config->{from},
            to      => $config->{to},
            subject => $config->{subject},
            html    => $config->{content}
        ]
    );
}
####################################################################################
sub split_bibtex_entries {
    my $input = shift;

    my @bibtex_codes = ();
    $input =~ s/^\s*$//g;
    $input =~ s/^\s+|\s+$//g;
    $input =~ s/^\t+//g;
    

    for my $b_code ( split /@/, $input ) {
        # skip bad splitting :P
        next if length($b_code) < 10;
        my $entry_code = "@".$b_code;
        
        push @bibtex_codes, $entry_code;
    }

    return @bibtex_codes;
}
################################################################################
sub decodeLatex {
    my $str = shift;

    use TeX::Encode;
    $str = decode( 'latex', $str );

    $str =~ s/\{(\w)\}/$1/g;         # makes {x} -> x
    $str =~ s/\{\\\"(u)\}/ü/g;    # makes {\"x} -> xe
    $str =~ s/\{\\\"(U)\}/Ü/g;    # makes {\"x} -> xe
    $str =~ s/\{\\\"(o)\}/ö/g;    # makes {\"x} -> xe
    $str =~ s/\{\\\"(O)\}/Ö/g;    # makes {\"x} -> xe
    $str =~ s/\{\\\"(a)\}/ä/g;    # makes {\"x} -> xe
    $str =~ s/\{\\\"(A)\}/Ä/g;    # makes {\"x} -> xe

    $str =~ s/\{\"(u)\}/ü/g;      # makes {"x} -> xe
    $str =~ s/\{\"(U)\}/Ü/g;      # makes {"x} -> xe
    $str =~ s/\{\"(o)\}/ö/g;      # makes {"x} -> xe
    $str =~ s/\{\"(O)\}/Ö/g;      # makes {"x} -> xe
    $str =~ s/\{\"(a)\}/ä/g;      # makes {"x} -> xe
    $str =~ s/\{\"(A)\}/Ä/g;      # makes {"x} -> xe

    $str =~ s/\\\"(u)/ü/g;        # makes \"{x} -> xe
    $str =~ s/\\\"(U)/Ü/g;        # makes \"{x} -> xe
    $str =~ s/\\\"(o)/ö/g;        # makes \"{x} -> xe
    $str =~ s/\\\"(O)/Ö/g;        # makes \"{x} -> xe
    $str =~ s/\\\"(a)/ä/g;        # makes \"{x} -> xe
    $str =~ s/\\\"(A)/Ä/g;        # makes \"{x} -> xe


    $str =~ s/\{\\\'(\w)\}/$1/g;     # makes {\'x} -> x
    $str =~ s/\\\'(\w)/$1/g;         # makes \'x -> x
    $str =~ s/\'\'(\w)/$1/g;         # makes ''x -> x
    $str =~ s/\"(\w)/$1e/g;          # makes "x -> xe
    $str =~ s/\{\\ss\}/ss/g;        # makes {\ss}-> ss
    $str =~ s/\{(.*)\}/$1/g;        # makes {abc..def}-> abc..def
    $str =~ s/\\\^(\w)(\w)/$1$2/g;    # makes \^xx-> xx
    $str =~ s/\\\^(\w)/$1/g;         # makes \^x-> x
    $str =~ s/\\\~(\w)/$1/g;         # makes \~x-> x
    $str =~ s/\\//g;                # removes \



    $str =~ s/\{+//g;
    $str =~ s/\}+//g;
    return $str;
}
################################################################################
sub official_bibtex_types {

  ## defined by bibtex and constant

  return (
    'article',      'book',          'booklet',    'conference',    'inbook',
    'incollection', 'inproceedings', 'manual',     'mastersthesis', 'misc',
    'phdthesis',    'proceedings',   'techreport', 'unpublished'
  );
}
####################################################################################
sub random_string {
  my $len = shift;

  my @set = ( '0' .. '9', 'A' .. 'Y' );
  my $str = join '' => map $set[ rand @set ], 1 .. $len;
  $str;
}
################################################################################
sub get_current_month {
  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime();
  return ( $mon + 1 );
}
################################################################################
sub get_current_year {
  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime();

  return ( $year + 1900 );
}
################################################################################
sub get_month_numeric {
  my $str = shift;
  $str = lc($str);
  $_   = $str;

  return 1  if /jan/ or /january/   or /januar/   or /1/  or /01/;
  return 2  if /feb/ or /february/  or /februar/  or /2/  or /02/;
  return 3  if /mar/ or /march/     or /3/        or /03/;
  return 4  if /apr/ or /april/     or /4/        or /04/;
  return 5  if /may/ or /mai/       or /maj/      or /5/  or /05/;
  return 6  if /jun/ or /june/      or /juni/     or /6/  or /06/;
  return 7  if /jul/ or /july/      or /juli/     or /7/  or /07/;
  return 8  if /aug/ or /august/    or /8/        or /08/;
  return 9  if /sep/ or /september/ or /sept/     or /9/  or /09/;
  return 10 if /oct/ or /october/   or /oktober/  or /10/ or /010/;
  return 11 if /nov/ or /november/  or /11/       or /011/;
  return 12 if /dec/ or /december/  or /dezember/ or /12/ or /012/;

  return 0;
}
################################################################################
sub clean_tag_name {
  my $tag = shift;
  $tag =~ s/^\s+|\s+$//g;
  $tag =~ s/\s/_/g;
  $tag =~ s/\./_/g;
  $tag =~ s/_$//g;
  $tag =~ s/\///g;
  $tag =~ s/\?/_/g;

  return ucfirst($tag);
}
################################################################################
sub uniqlc {
  return keys %{ { map { lc $_ => 1 } @_ } };
}
################################################################################
sub nohtml {
  my $key  = shift // "key-unknown";
  my $type = shift // "no-type";
  return
      "<span class=\"label label-danger\">"
    . "NO HTML "
    . "</span><span class=\"label label-default\">"
    . "($type) $key</span>" . "<BR>";
}
# ################################################################################
sub get_generic_type_description { 
  my $type_desc = shift;
  return "Talks " if $type_desc eq 'talk';
  return "Publications of type " . $type_desc;
}
################################################################################

sub create_user_id {
  my ($name) = @_;

  my @first_arr = $name->part('first');
  @first_arr = grep {defined $_ } @first_arr;
  my $first = join( ' ', @first_arr );

  my @von_arr = $name->part('von');
  my $von     = $von_arr[0];

  my @last_arr = $name->part('last');
  my $last     = $last_arr[0];

  my @jr_arr = $name->part('jr');
  my $jr     = $jr_arr[0];

  my $userID;
  $userID .= $von   if defined $von;
  $userID .= $last;
  $userID .= $first if defined $first;
  $userID .= $jr    if defined $jr;



  $userID =~ s/\\k\{a\}/a/g;    # makes \k{a} -> a
  $userID =~ s/\\l/l/g;         # makes \l -> l
  $userID =~ s/\\r\{u\}/u/g;    # makes \r{u} -> u # FIXME: make sure that the letter is caught
                                # $userID =~ s/\\r{u}/u/g;   # makes \r{u} -> u # the same but not escaped

  $userID =~ s/\{(\w)\}/$1/g;         # makes {x} -> x
  $userID =~ s/\{\\\"(\w)\}/$1e/g;    # makes {\"x} -> xe
  $userID =~ s/\{\"(\w)\}/$1e/g;      # makes {"x} -> xe
  $userID =~ s/\\\"(\w)/$1e/g;        # makes \"{x} -> xe
  $userID =~ s/\{\\\'(\w)\}/$1/g;     # makes {\'x} -> x
  $userID =~ s/\\\'(\w)/$1/g;         # makes \'x -> x
  $userID =~ s/\'\'(\w)/$1/g;         # makes ''x -> x
  $userID =~ s/\"(\w)/$1e/g;          # makes "x -> xe
  $userID =~ s/\{\\ss\}/ss/g;        # makes {\ss}-> ss
  $userID =~ s/\{(\w*)\}/$1/g;        # makes {abc..def}-> abc..def
  $userID =~ s/\\\^(\w)(\w)/$1$2/g;    # makes \^xx-> xx
                                     # I am not sure if the next one is necessary
  $userID =~ s/\\\^(\w)/$1/g;         # makes \^x-> x
  $userID =~ s/\\\~(\w)/$1/g;         # makes \~x-> x
  $userID =~ s/\\//g;                # removes \

  $userID =~ s/\{//g;                # removes {
  $userID =~ s/\}//g;                # removes }

  $userID =~ s/\(.*\)//g;            # removes everything between the brackets and the brackets also

  # print "$userID \n";
  return $userID;
}
################################################################################

1;
