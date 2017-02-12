package Entry;

use BibSpace::Model::Tag;
use BibSpace::Model::Team;
use BibSpace::Model::Author;
use BibSpace::Model::TagType;
use BibSpace::Model::Type;

use BibSpace::Functions::Core;

use List::MoreUtils qw(any uniq);


use DateTime::Format::Strptime;
use DateTime;
use Path::Tiny;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use v5.16;           #because of ~~ and say

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


has 'entry_type' => ( is => 'rw', isa => 'Str', default => 'paper' );
has 'bibtex_key' => ( is => 'rw', isa => 'Maybe[Str]' );
has '_bibtex_type' => ( is => 'rw', isa => 'Maybe[Str]', reader => 'bibtex_type' );
has 'bib' => ( is => 'rw', isa => 'Maybe[Str]', trigger => \&_bib_changed );

sub _bib_changed {
    my ( $self, $curr_val, $prev_val ) = @_;

    # bib was updated, we need to bump modified_time
    if ( $prev_val and $curr_val ne $prev_val ) {
        $self->modified_time(
            DateTime->now->set_time_zone(
                $self->preferences->local_time_zone
            )
        );
    }
}


has 'html'            => ( is => 'rw', isa => 'Maybe[Str]' );
has 'html_bib'        => ( is => 'rw', isa => 'Maybe[Str]' );
has 'abstract'        => ( is => 'rw', isa => 'Maybe[Str]' );
has 'title'           => ( is => 'rw', isa => 'Maybe[Str]' );
has 'hidden'          => ( is => 'rw', isa => 'Int', default => 0 );
has 'year'            => ( is => 'rw', isa => 'Maybe[Int]', default => 0 );
has 'month'           => ( is => 'rw', isa => 'Int', default => 0 );
has 'need_html_regen' => ( is => 'rw', isa => 'Int', default => 1 );

# name => Path::Tiny object
has 'attachments' => (
    is      => 'rw',
    traits  => ['Hash'],
    isa     => 'HashRef[Path::Tiny]',
    default => sub { {} },
    handles => {
        attachments_set     => 'set',
        attachments_get     => 'get',
        attachments_has     => 'exists',
        attachments_defined => 'defined',
        attachments_keys    => 'keys',
        attachments_values  => 'values',
        attachments_num     => 'count',
        attachments_pairs   => 'kv',
        attachments_delete  => 'delete',
        attachments_clear   => 'clear',
    },
);

sub get_attachments_debug_string {
    my $self = shift;
    my $str  = "Entry ID " . $self->id . " has: ";
    foreach my $f_type ( $self->attachments_keys ) {
        $str .= " type: (" . $f_type . ") ";
        my $f_path = $self->attachments_get($f_type);
        $str .= "path: (" . $f_path . "), ";
    }
    return $str;
}


has 'creation_time' => (
    is      => 'rw',
    isa     => 'DateTime',
    lazy    => 1,            # due to preferences
    default => sub {
        my $self = shift;
        DateTime->now->set_time_zone( $self->preferences->local_time_zone );
    },
);

sub get_creation_time {
    my $self = shift;
    $self->creation_time->set_time_zone( $self->preferences->local_time_zone )
        ->strftime( $self->preferences->output_time_format );
}

has 'modified_time' => (
    is      => 'rw',
    isa     => 'DateTime',
    lazy    => 1,            # due to preferences
    default => sub {
        my $self = shift;
        DateTime->now->set_time_zone( $self->preferences->local_time_zone );
    },
);

sub get_modified_time {
    my $self = shift;
    $self->modified_time->set_time_zone( $self->preferences->local_time_zone )
        ->strftime( $self->preferences->output_time_format );
}

# not DB fields
# bibtex warnings
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
    die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj)
        unless ref($self) eq ref($obj);
    return $self->equals_bibtex($obj);
}
####################################################################################

=item equals_bibtex
    Assumes that both objects are equal if the bibtex code is identical
=cut

sub equals_bibtex {
    my $self = shift;
    my $obj  = shift;
    die "Comparing apples to peaches! " . ref($self) . " against " . ref($obj)
        unless ref($self) eq ref($obj);
    return $self->bib eq $obj->bib;
}
####################################################################################
####################################################################################
sub delete_all_attachments {
    my $self = shift;

    for my $fp ( $self->attachments_values ) {
        $fp->remove;
    }
    $self->attachments_clear;
}
####################################################################################
sub add_attachment {
    my ( $self, $type, $obj ) = @_;
    $self->attachments_set( $type, $obj );
}
####################################################################################
sub get_attachment {
    my ( $self, $type ) = @_;
    $self->attachments_get($type);
}
####################################################################################
sub delete_attachment {
    my ( $self, $type ) = @_;
    if ( $self->attachments_has($type) ) {

        my $fp = $self->attachments_get($type);
        $fp->remove;
        $self->attachments_delete($type);
    }
}
####################################################################################
sub discover_attachments {
    my ( $self, $upload_dir ) = @_;

    my $id = $self->id;

    $self->attachments_clear;

    try {
        Path::Tiny->new($upload_dir)->mkpath;
        Path::Tiny->new( $upload_dir, "papers" )->mkpath;
        Path::Tiny->new( $upload_dir, "slides" )->mkpath;
    }
    catch {
        warn $_;
    };

    my @discovery_papers;
    try {
        my $dir_path = Path::Tiny->new( $upload_dir, "papers" );
        @discovery_papers = $dir_path->children(qr/paper-$id\./);
    }
    catch {
        warn $_;
    };
    $self->add_attachment( 'paper',   $_ ) for @discovery_papers;


    my @discovery_slides;
    try {
        my $dir_path = Path::Tiny->new( $upload_dir, "slides" );
        @discovery_slides = $dir_path->children(qr/slides-paper-$id\./);
    }
    catch {
        warn $_;
    };
    $self->add_attachment( 'slides',  $_ ) for @discovery_slides;


    # my @discovery_other;
    # try {
    #     my $dir_path = Path::Tiny->new( $upload_dir, "unknown" );
    #     @discovery_other = $dir_path->children(qr/unknown-$id\./);
    # }
    # catch {
    #     warn $_;
    # };
    # $self->add_attachment( 'unknown', $_ ) for @discovery_other;
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

    my $match
        = $mapping->bibtexTypes_find( sub { $_ eq $self->{_bibtex_type} } );

    return defined $match;
}
####################################################################################
sub has_valid_bibtex {
    my $self = shift;
    if ( defined $self->bib and $self->bib ne '' ) {
        my $bibtex_entry = new Text::BibTeX::Entry();
        my $s            = $bibtex_entry->parse_s( $self->bib );

        return if !$bibtex_entry->parse_ok;
        return 1;
    }
    return;
}
####################################################################################
sub populate_from_bib {
    my $self = shift;

    return if !$self->has_valid_bibtex;

    if ( defined $self->bib and $self->bib ne '' ) {
        my $bibtex_entry = new Text::BibTeX::Entry();
        my $s            = $bibtex_entry->parse_s( $self->bib );

        $self->bibtex_key( $bibtex_entry->key );
        my $year_str = $bibtex_entry->get('year');
        if ( Scalar::Util::looks_like_number($year_str) ) {
            $self->year($year_str);
        }


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
        if ( $entry->exists($field) ) {
            $entry->delete($field);
            $num_deleted++;
        }
    }

    if ( $num_deleted > 0 ) {
        my $new_bib = $entry->print_s;
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
            = BibSpace::Functions::Core::get_month_numeric($month_str);

    }
    if ( $self->month != $month_numeric ) {
        $self->month($month_numeric);
        $num_fixes = 1;
    }


    return $num_fixes;
}
####################################################################################
sub fix_bibtex_accents {
    my $self = shift;
    $self->bib( fix_bibtex_national_characters( $self->bib ) );
}
####################################################################################
sub generate_html {
    my $self      = shift;
    my $bst_file  = shift;
    my $converter = shift;

    die "Bibtex-Html converter is not defined" unless $converter;
    $bst_file = $self->bst_file if !defined $bst_file;

    $self->populate_from_bib();
    $self->fix_bibtex_accents;


    try{
        $converter->convert( $self->bib, $bst_file );
        $self->html($converter->get_html);
        $self->warnings( join( ', ', $converter->get_warnings ) );
        $self->need_html_regen(0);
    }
    catch{
        $self->html(nohtml(undef,undef));
        $self->warnings("WARNING: Converter was unable to convert this entry.");
        $self->need_html_regen(1);
    };


    return ( $self->html, $self->bib );
}
####################################################################################
sub regenerate_html {
    my $self      = shift;
    my $force     = shift;
    my $bst_file  = shift;
    my $converter = shift;
    $bst_file ||= $self->bst_file;

    die "Bibtex-Html converter is not defined" unless $converter;

    warn "Warning, you use entry->regenerate_html without valid bst file!"
        unless defined $bst_file;

    if (   $force == 1
        or $self->need_html_regen == 1
        or $self->html =~ m/ERROR/ )
    {
        $self->generate_html( $bst_file, $converter );
        return 1;
    }
    return 0;
}

####################################################################################
sub has_author {
    my $self   = shift;
    my $author = shift;

    warn
        "FIXME: Change authorship search method! Use dummy-search authorship object!";

    my $authorship = $self->authorships_find(
        sub { $_->author->equals($author) and $_->entry->equals($self) } );
    return defined $authorship;
}
####################################################################################
sub has_master_author {
    my $self   = shift;
    my $author = shift;

    return $self->has_author( $author->get_master );
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
        push @author_names, BibSpace::Functions::Core::create_user_id($name);
    }
    return @author_names;
}
####################################################################################
sub get_teams {
    my $self = shift;

    my @exception_teams = map { $_->team } $self->get_exceptions;

    ## Important: this means that entry-teams = teams + exceptions!
    my %final_teams = map { $_->id => $_ } @exception_teams;

    foreach my $author ( $self->get_authors ) {

        foreach my $team ( $author->get_teams ) {
            my $joined = $author->joined_team($team);
            my $left   = $author->left_team($team);

            # entry has no year... strange but possible
            if ( !$self->year ) {
                $final_teams{ $team->id } = $team;
            }
            elsif ( $joined <= $self->year
                and ( $left > $self->year or $left == 0 ) )
            {
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
    return;
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
sub get_title {
    my $self      = shift;
    my $raw_title = $self->title;
    $raw_title = decodeLatex($raw_title);
    return $raw_title;
}
####################################################################################
sub clean_ugly_bibtex_fields {
    my $self                         = shift;
    my $field_names_to_clean_arr_ref = shift;

    return $self->remove_bibtex_fields($field_names_to_clean_arr_ref);
}

####################################################################################

no Moose;
__PACKAGE__->meta->make_immutable;
1;
