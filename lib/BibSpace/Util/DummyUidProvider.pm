package DummyUidProvider;
use Moose;
use BibSpace::Util::IUidProvider;
with 'IUidProvider';
use List::Util qw(max);
use Scalar::Util qw( refaddr );
use List::MoreUtils qw(any uniq);

use feature qw(say);

sub reset       { 1; }
sub registerUID { 1; }
sub last_id     { 1; }
sub generateUID { 1; }

no Moose;
1;
