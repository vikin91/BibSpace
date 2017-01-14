use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

my $t_anyone = Test::Mojo->new('BibSpace');
my $self = $t_anyone->app;
my $dbh = $t_anyone->app->db;



use BibSpace::Model::M::MTagCloud;
use BibSpace::Controller::Core; # for random string
use Data::Dumper;



$dbh->do('DELETE FROM Team;');

# my $en = MTeam->new();
my $tc = MTagCloud->new();

my $random1 = random_string(16);
my $random2 = random_string(16);
my $random3 = random_string(16);
my $random4 = random_string(16);

$tc->{tag} = $random1;
$tc->{name} = $random2;
$tc->{url} = $random3;
$tc->{count} = $random4;

my $html = $tc->getHTML();

unlike($html, qr/$random1/, "Html should not contain $random1");
like($html, qr/$random2/, "Html should contain $random2");
like($html, qr/$random3/, "Html should contain $random3");
like($html, qr/$random4/, "Html should contain $random4");


done_testing();
