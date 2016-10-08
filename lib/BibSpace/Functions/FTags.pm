package BibSpace::Functions::FTags;

use 5.010;    #because of ~~
use strict;
use warnings;
use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use DBI;

use BibSpace::Controller::Core;
use BibSpace::Model::MEntry;
use BibSpace::Model::MTag;

use Exporter;
our @ISA = qw( Exporter );

# these CAN be exported.
# our @EXPORT_OK = qw( export_me export_me_too );

# these are exported by default.
our @EXPORT = qw(
    add_tags_from_string
);
####################################################################################
sub add_tags_from_string {
    my $dbh         = shift;
    my $tags_to_add = shift;
    my $type        = shift || 1;
    

    my @tags;
    my @tag_names;


    if ( defined $tags_to_add ) {
        my @pre_tag_names = split( ';', $tags_to_add );
        foreach my $tag (@pre_tag_names) {
            $tag = clean_tag_name($tag);

            if ( defined $tag and $tag ne '' and length($tag) > 0 ) {
                push @tag_names, $tag if defined $tag;
            }
        }

        foreach my $tag_name (@tag_names) {

            my $new_tag = MTag->new(name=> $tag_name, type=>$type);
            $new_tag->save($dbh);
            push @tags, $new_tag;

        }
    }

    return @tags;

}
####################################################################################