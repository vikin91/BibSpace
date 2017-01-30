package Entry;

use BibSpace::Model::IntegerUidProvider;
use BibSpace::Model::Tag;
use BibSpace::Model::Team;
use BibSpace::Model::Author;
use BibSpace::Model::TagType;
use BibSpace::Model::Type;

use List::MoreUtils qw(any uniq);



use BibSpace::Model::M::StorageBase;

use DateTime::Format::Strptime;
use DateTime;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use 5.010;           #because of ~~ and say
use DBI;
use DBIx::Connector;
use Try::Tiny;
use TeX::Encode;
use Encode;

use Moose;
use Moose::Util::TypeConstraints;
use BibSpace::Model::IEntity;
use BibSpace::Model::ILabeled;
use BibSpace::Model::IAuthored;
use BibSpace::Model::IHavingException;
with 'IEntity', 'ILabeled', 'IAuthored', 'IHavingException';
use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );

my $dtPattern
    = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S' );

has 'entry_type' => ( is => 'rw', isa => 'Str', default => 'paper' );
has 'bibtex_key' => ( is => 'rw', isa => 'Maybe[Str]' );
has '_bibtex_type'    => ( is => 'rw', isa => 'Maybe[Str]', reader=>'bibtex_type' );
has 'bib'             => ( is => 'rw', isa => 'Maybe[Str]' );
has 'html'            => ( is => 'rw', isa => 'Maybe[Str]' );
has 'html_bib'        => ( is => 'rw', isa => 'Maybe[Str]' );
has 'abstract'        => ( is => 'rw', isa => 'Maybe[Str]' );
has 'title'           => ( is => 'rw', isa => 'Maybe[Str]' );
has 'hidden'          => ( is => 'rw', isa => 'Int', default => 0 );
has 'year'            => ( is => 'rw', isa => 'Maybe[Int]', default => 0 );
has 'month'           => ( is => 'rw', isa => 'Int', default => 0 );
has 'sort_month'      => ( is => 'rw', isa => 'Int', default => 0 );
has 'teams_str'       => ( is => 'rw', isa => 'Maybe[Str]' );
has 'people_str'      => ( is => 'rw', isa => 'Maybe[Str]' );
has 'tags_str'        => ( is => 'rw', isa => 'Maybe[Str]' );
has 'need_html_regen' => ( is => 'rw', isa => 'Int', default => 1 );
has 'shall_update_modified_time' =>
    ( is => 'rw', isa => 'Int', default => 0 );


# class_type 'DateTime';
# coerce 'DateTime'
#       => from 'Str'
#       => via { $dtPattern->parse_datetime($_) };

has 'creation_time' => (
    is      => 'rw',
    isa     => 'DateTime',
    traits  => ['DoNotSerialize'],
    default => sub {
        my $dt = DateTime->now;
        say "Setting default MEntry->creation_time";
        $dt->set_formatter($dtPattern);
        return $dt;
    },

    # coerce => 1
);
has 'modified_time' => (
    is      => 'rw',
    isa     => 'DateTime',
    traits  => ['DoNotSerialize'],
    default => sub {
        $dtPattern->parse_datetime('1970-01-01 00:00:00');
    },

    # coerce => 1
);

# not DB fields
has 'warnings' =>
    ( is => 'rw', isa => 'Maybe[Str]', traits => ['DoNotSerialize'] );
has 'bst_file' => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    default => './lib/descartes2.bst',
    traits  => ['DoNotSerialize']
);




####################################################################################

sub equals {
    my $self = shift;
    my $obj  = shift;
    die "Comparing apples to peaches! ".ref($self)." against ".ref($obj) unless ref($self) eq ref($obj);
    return $self->equals_bibtex($obj);
}
####################################################################################

=item equals_bibtex
    Assumes that both objects are equal if the bibtex code is identical
=cut

sub equals_bibtex {
    my $self = shift;
    my $obj  = shift;
    die "Comparing apples to peaches! ".ref($self)." against ".ref($obj) unless ref($self) eq ref($obj);
    return $self->bib eq $obj->bib;
}
####################################################################################

=item is_visible
    Entry is visible if at least one of its authors is visible
=cut

sub is_visible {
    my $self = shift;

    my $visible_author = any { $_->is_visible } $self->get_authors;
    return 1 if defined $visible_author;
    return;
}
####################################################################################
sub is_hidden {
    my $self = shift;
    return $self->hidden == 1;
}
####################################################################################
sub hide {
    my $self = shift;
    $self->hidden(1);
}
####################################################################################
sub unhide {
    my $self = shift;
    $self->hidden(0);
}
####################################################################################
sub toggle_hide {
    my $self = shift;
    if ( $self->is_hidden == 1 ) {
        $self->unhide();
    }
    else {
        $self->hide();
    }
}
####################################################################################
sub make_paper {
    my $self = shift;
    $self->entry_type('paper');
}
####################################################################################
sub is_paper {
    my $self = shift;
    return 1 if $self->entry_type eq 'paper';
    return;
}
####################################################################################
sub make_talk {
    my $self = shift;
    $self->entry_type('talk');
}
####################################################################################
sub is_talk {
    my $self = shift;
    return 1 if $self->entry_type eq 'talk';
    return;
}
####################################################################################
sub matches_our_type {
    my $self  = shift;
    my $oType = shift;
    my $repo  = shift;

    die "This method requires repo, sorry." unless $repo;

    # example: ourType = inproceedings
    # mathces bibtex types: inproceedings, incollection

    my $mapping = $repo->types_find(
        sub {
            ( $_->our_type cmp $oType ) == 0;
        }
    );

    return if !defined $mapping;

    my $match = $mapping->bibtexTypes_find( sub { $_ eq $self->{_bibtex_type} } );

    return defined $match;
}
####################################################################################
sub populate_from_bib {
    my $self = shift;


    if ( defined $self->bib and $self->bib ne '' ) {
        my $bibtex_entry = new Text::BibTeX::Entry();
        my $s            = $bibtex_entry->parse_s( $self->bib );

        return if !$bibtex_entry->parse_ok;

        $self->bibtex_key( $bibtex_entry->key );
        $self->year( $bibtex_entry->get('year') );
        if ( $bibtex_entry->exists('booktitle') ) {
            $self->title( $bibtex_entry->get('booktitle') );
        }
        if ( $bibtex_entry->exists('title') ) {
            $self->title( $bibtex_entry->get('title') );
        }
        $self->abstract( $bibtex_entry->get('abstract') || undef );
        $self->_bibtex_type( $bibtex_entry->type );
        return 1;
    }
    return;
}
####################################################################################
sub add_bibtex_field {
    my $self  = shift;
    my $field = shift;
    my $value = shift;

    my $entry = new Text::BibTeX::Entry();
    $entry->parse_s( $self->bib );
    return unless $entry->parse_ok;
    my $key = $entry->key;

    $entry->set( $field, $value );
    my $new_bib = $entry->print_s;

    $self->bib($new_bib);
    $self->populate_from_bib();
}
####################################################################################
sub has_bibtex_field {

    # returns 1 if bibtex of this entry has filed
    my $self         = shift;
    my $bibtex_field = shift;
    my $this_bib     = $self->bib;

    my $bibtex_entry = new Text::BibTeX::Entry();
    $bibtex_entry->parse_s($this_bib);
    return 1 if $bibtex_entry->exists($bibtex_field);
    return;
}
####################################################################################
sub get_bibtex_field_value {

    # returns 1 if bibtex of this entry has filed
    my $self         = shift;
    my $bibtex_field = shift;
    my $this_bib     = $self->bib;

    if ( $self->has_bibtex_field($bibtex_field) ) {
        my $bibtex_entry = new Text::BibTeX::Entry();
        $bibtex_entry->parse_s($this_bib);
        return $bibtex_entry->get($bibtex_field);
    }
    return undef;
}
####################################################################################
sub remove_bibtex_fields {
    my $self                         = shift;
    my $arr_ref_bib_fields_to_delete = shift;
    my @bib_fields_to_delete         = @$arr_ref_bib_fields_to_delete;

    my $entry = new Text::BibTeX::Entry();
    $entry->parse_s( $self->bib );
    return -1 unless $entry->parse_ok;
    my $key = $entry->key;

    my $num_deleted = 0;

    for my $field (@bib_fields_to_delete) {
        $entry->delete($field) if defined $entry->exists($field);
        $num_deleted++ if defined $entry->exists($field);
    }

    if ( $num_deleted > 0 ) {
        my $new_bib = $entry->print_s;

# cleaning errors caused by sqlite - mysql import # FIXME: do we still need this?
        $new_bib =~ s/''\{(.)\}/"\{$1\}/g;
        $new_bib =~ s/"\{(.)\}/\\"\{$1\}/g;

        $new_bib =~ s/\\\\/\\/g;
        $new_bib =~ s/\\\\/\\/g;

        $self->bib($new_bib);
    }
    return $num_deleted;
}
####################################################################################
sub fix_month {
    my $self         = shift;
    my $bibtex_entry = new Text::BibTeX::Entry();
    $bibtex_entry->parse_s( $self->{bib} );

    my $num_fixes     = 0;
    my $month_numeric = 0;

    if ( $self->has_bibtex_field('month') ) {
        my $month_str = $bibtex_entry->get('month');
        $month_numeric
            = BibSpace::Controller::Core::get_month_numeric($month_str);

    }
    if ( $self->{month} != $month_numeric ) {
        $self->{month} = $month_numeric;
        $num_fixes = 1;
    }

    # ve leave changed
    if ( $self->{sort_month} == 0 and $self->{sort_month} != $month_numeric )
    {
        $self->{sort_month} = $month_numeric;
    }


    return $num_fixes;
}
####################################################################################
sub generate_html {
    my $self     = shift;
    my $bst_file = shift;

    $bst_file = $self->bst_file if !defined $bst_file;

    $self->populate_from_bib();

    my $c = BibSpaceBibtexToHtml::BibSpaceBibtexToHtml->new();
    $self->html(
        $c->convert_to_html(
            { method => 'new', bib => $self->{bib}, bst => $bst_file }
        )
    );
    $self->warnings( join( ', ', @{ $c->{warnings_arr} } ) );

    $self->need_html_regen(0);

    return ( $self->html, $self->bib );
}
####################################################################################
sub regenerate_html {
    my $self     = shift;
    my $force    = shift;
    my $bst_file = shift;

    $bst_file = $self->{bst_file} if !defined $bst_file;
    warn "Warning, you use Mentry->regenerate_html without valid bst file!"
        unless defined $bst_file;

    if (   $force == 1
        or $self->need_html_regen == 1
        or $self->html =~ m/ERROR/ )
    {
        $self->populate_from_bib();
        $self->generate_html($bst_file);
        $self->need_html_regen(0);
    }
}

####################################################################################
sub has_author {
    my $self            = shift;
    my $author          = shift;

    # SimpleLogger->new->warn("Checking if entry ".$self->id." has author ".$author->uid." (master ".$author->master.")");
    # SimpleLogger->new->warn("Entry ".$self->id." authorships: ".join(',', map{$_->id} grep {$_->author_id == $author->id } $self->authorships_all));

    my $authorship = $self->authorships_find( sub { $_->author->equals($author) and $_->entry->equals($self)});
    return defined $authorship;
}
####################################################################################
sub has_master_author {
    my $self            = shift;
    my $author          = shift;

    return $self->has_author($author->get_master);
}
####################################################################################
####################################################################################
####################################################################################
sub author_names_from_bibtex {
    my $self = shift;

    $self->populate_from_bib();

    my $bibtex_entry = new Text::BibTeX::Entry();
    $bibtex_entry->parse_s( $self->bib );
    my $entry_key = $self->bibtex_key;

    my @names;
    if ( $bibtex_entry->exists('author') ) {
        my @authors = $bibtex_entry->split('author');
        my (@n) = $bibtex_entry->names('author');
        push @names, @n;
    }
    elsif ( $bibtex_entry->exists('editor') )
    {    # issue with Alex Dagstuhl Chapter
        my @authors = $bibtex_entry->split('editor');
        my (@n) = $bibtex_entry->names('editor');
        push @names, @n;
    }

    my @author_names;
    foreach my $name (@names) {
        push @author_names, BibSpace::Controller::Core::create_user_id($name);
    }
    return @author_names;
}
####################################################################################
sub teams {
    my $self = shift;
    SimpleLogger->new->warn("entry->teams is deprecated in favor of entry->get_teams");
    return $self->get_teams;
}
####################################################################################
sub get_teams {
    my $self = shift;

    my %final_teams;
    foreach my $author ( $self->get_authors ) {

        foreach my $team ( $author->get_teams ) {
            if ($author->joined_team($team) <= $self->year
                and (  $author->left_team($team) > $self->year
                    or $author->left_team($team) == 0 )
                )
            {
                # $final_teams{$team}       = 1; # BAD: $team gets stringified
                $final_teams{ $team->id } = $team;
            }
        }
    }
    return values %final_teams;
}
####################################################################################
sub has_team {
    my $self = shift;
    my $team = shift;

    return 1 if any { $_->equals($team) } $self->get_teams;
    return ;
}
####################################################################################
####################################################################################
####################################################################################
sub tag_names_from_bibtex {
    my $self = shift;

    my @tag_names;

    my $bibtex_entry = new Text::BibTeX::Entry();
    $bibtex_entry->parse_s( $self->bib );

    if ( $bibtex_entry->exists('tags') ) {
        my $tags_str = $bibtex_entry->get('tags');
        if ($tags_str) {

            # change , into ;
            $tags_str =~ s/\,/;/g;

            # remove leading and trailing spaces
            $tags_str =~ s/^\s+|\s+$//g;

            @tag_names = split( ';', $tags_str );

            # remove leading and trailing spaces
            map {s/^\s+|\s+$//g} @tag_names;

            # change spaces into underscores
            map { $_ =~ s/\ /_/g } @tag_names;
        }
    }
    return @tag_names;
}
####################################################################################
sub sort_by_year_month_modified_time {

    # $a and $b exist and are MEntry objects
    {
        no warnings 'uninitialized';
               $a->{year} <=> $b->{year}
            or $a->{sort_month} <=> $b->{sort_month}
            or $a->{month} <=> $b->{month}
            or $a->{id} <=> $b->{id};
    }

# $a->{modified_time} <=> $b->{modified_time}; # needs an extra lib, so we just compare ids as approximation
}
####################################################################################
sub decodeLatex {
    my $self = shift;
    if ( defined $self->title ) {
        my $title = $self->title;
        $title =~ s/^\{+//g;
        $title =~ s/\}+$//g;
        $self->title($title);

        # $self->{title} = decode( 'latex', $self->{title} );
        # $self->{title} = decode( 'latex', $self->{title} );
    }
}
####################################################################################

####################################################################################
sub clean_ugly_bibtex_fields {
    my $self = shift;

    my @arr_default
        = qw(bdsk-url-1 bdsk-url-2 bdsk-url-3 date-added date-modified owner tags);
    return $self->remove_bibtex_fields( \@arr_default );
}

####################################################################################

no Moose;
__PACKAGE__->meta->make_immutable;
1;
