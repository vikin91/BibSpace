use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

# my $t_anyone = Test::Mojo->new('BibSpace');
# my $self = $t_anyone->app;
# my $dbh = $t_anyone->app->db;

use BibSpace::Model::TagCloud;
use BibSpace::Functions::Core;    # for random string
use Data::Dumper;

my $random2 = random_string(16);
my $random3 = random_string(16);
my $random4 = random_string(16);

my $tc = TagCloud->new();

$tc->{name}  = $random2;
$tc->{url}   = $random3;
$tc->{count} = $random4;

my $html = $tc->getHTML();

like($html, qr/$random2/, "Html should contain $random2");
like($html, qr/$random3/, "Html should contain $random3");
like($html, qr/$random4/, "Html should contain $random4");

done_testing();
