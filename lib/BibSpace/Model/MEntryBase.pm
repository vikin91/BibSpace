package MEntryBase;

use BibSpace::Model::MTag;
use BibSpace::Model::MTeam;
use BibSpace::Model::MAuthor;
use BibSpace::Model::MTagType;

use List::MoreUtils qw(any uniq);


use BibSpace::Model::StorageBase;

use DateTime::Format::Strptime;
use DateTime;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use 5.010;           #because of ~~ and say
use DBI;
use Try::Tiny;
use TeX::Encode;
use Encode;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Storage;
with Storage( 'format' => 'JSON', 'io' => 'File' );

my $dtPattern = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S' );

has 'id'              => ( is => 'rw', isa => 'Int', default => 1);
has 'entry_type'      => ( is => 'rw', isa => 'Str', default => 'paper' );
has 'bibtex_key'      => ( is => 'rw', isa => 'Maybe[Str]' );
has '_bibtex_type'     => ( is => 'rw', isa => 'Maybe[Str]' );
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

# class_type 'DateTime';
# coerce 'DateTime'
#       => from 'Str'
#       => via { $dtPattern->parse_datetime($_) };
 
has 'creation_time'   => ( 
    is => 'rw', 
    isa => 'DateTime', 
    default => sub {
        my $dt = DateTime->now;
        say "Setting default MEntry->creation_time";
        $dt->set_formatter($dtPattern);
        return $dt;
    },
    # coerce => 1
);
has 'modified_time'   => ( 
    is => 'rw', 
    isa => 'DateTime', 
    default => sub {
        my $dt = $dtPattern->parse_datetime('1970-01-01 00:00:00');
        say "Setting default MEntry->modified_time";
        return $dt;
    },
    # coerce => 1
);


has 'bauthors' => (
    is      => 'rw',
    isa     => 'ArrayRef[MAuthor]',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        authors_all        => 'elements',
        authors_add        => 'push',
        authors_map        => 'map',
        authors_filter     => 'grep',
        authors_find       => 'first',
        authors_find_index => 'first_index',
        authors_delete     => 'delete',
        authors_clear      => 'clear',
        authors_get        => 'get',
        authors_join       => 'join',
        authors_count      => 'count',
        authors_has        => 'count',
        authors_has_no     => 'is_empty',
        authors_sorted     => 'sort',
    },
);
has 'btags' => (
    is      => 'rw',
    isa     => 'ArrayRef[MTag]',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        tags_all        => 'elements',
        tags_add        => 'push',
        tags_map        => 'map',
        tags_filter     => 'grep',
        tags_find       => 'first',
        tags_find_index => 'first_index',
        tags_delete     => 'delete',
        tags_clear      => 'clear',
        tags_get        => 'get',
        tags_join       => 'join',
        tags_count      => 'count',
        tags_has        => 'count',
        tags_has_no     => 'is_empty',
        tags_sorted     => 'sort',
    },
);
has 'bexceptions' => (
    is      => 'rw',
    isa     => 'ArrayRef[MTeam]',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        exceptions_all        => 'elements',
        exceptions_add        => 'push',
        exceptions_map        => 'map',
        exceptions_filter     => 'grep',
        exceptions_find       => 'first',
        exceptions_find_index => 'first_index',
        exceptions_delete     => 'delete',
        exceptions_clear      => 'clear',
        exceptions_get        => 'get',
        exceptions_join       => 'join',
        exceptions_count      => 'count',
        exceptions_has        => 'count',
        exceptions_has_no     => 'is_empty',
        exceptions_sorted     => 'sort',
    },
);

# not DB fields
has 'warnings' => ( 
    is => 'rw', 
    isa => 'Maybe[Str]', 
    traits => ['DoNotSerialize'] 
);
has 'bst_file' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => './lib/descartes2.bst',
    traits  => ['DoNotSerialize']
);

################################################################################
sub init_storage {
    my $self = shift;

    if( $self->tags_count == 0){
        $self->btags([]);
    }
    if( $self->authors_count == 0){
        $self->bauthors([]);
    }
    if( $self->exceptions_count == 0){
        $self->bexceptions([]);
    }
}
####################################################################################
sub replaceFromStorage {
    my $self = shift;
    my $storage  = shift; # dependency injection
    # use BibSpace::Model::StorageBase;

    my $storageItem = $storage->entries_find( sub{ $_->equals($self) } );

    die "Cannot find ".ref($self).": ".Dumper($self)." in storage " unless $storageItem;
    return $storageItem;
}
####################################################################################
sub toString {
    my $self = shift;
    my $str;
    $str .= "MEntry id " . $self->id;
    $str .= ", entry_type " . $self->entry_type;
    $str .= ", bibtex_key " . $self->bibtex_key;
    $str .= ", year " . $self->year;
    $str .= ", \n";
    $str .= "Authors: [\n";
    map { $str .= "\t".$_->toString . "\n"} $self->authors_all;
    $str .= "]\n";

    $str .= "Tags: [\n";
    map { $str .= "\t".$_->toString . "\n"} $self->tags_all;
    $str .= "]\n";

    $str .= "Exceptions: [\n";
    map { $str .= "\t".$_->toString . "\n"} $self->exceptions_all;
    $str .= "]\n";

    return $str;
}
####################################################################################

sub equals {
    my $self = shift;
    my $obj  = shift;
    return $self->equals_bibtex($obj);
}
####################################################################################
=item equals_bibtex
    Assumes that both objects are equal if the bibtex code is identical
=cut

sub equals_bibtex {
    my $self = shift;
    my $obj  = shift;

    return 0 unless defined $obj;
    # return 0 unless $obj->isa("MEntryBase");

    my $result = $self->bib cmp $obj->bib;
    return $result == 0;
}
####################################################################################
=item is_visible
    Entry is visible if at least one of its authors is visible
=cut
sub is_visible {
    my $self = shift;

    my $visible_author = $self->authors_find( sub{ $_->is_visible });
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
    return 0;
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
    return 0;
}
####################################################################################
sub matches_our_type {
    my $self  = shift;
    my $oType = shift;
    my $storage = shift;

    die "This method requires storage, sorry." unless $storage;

    # example: ourType = inproceedings
    # mathces bibtex types: inproceedings, incollection

    use BibSpace::Model::MTypeMappingBase;

    my $mapping = $storage->typeMappings_find( sub{
        ($_->our_type cmp $oType)==0;
    });

    return if !defined $mapping;

    my $match = $mapping->bibtexTypes_find( sub{
        ($_ cmp $self->{_bibtex_type})==0;
    });

    return defined $match;

    
}
####################################################################################
sub populate_from_bib {
    my $self = shift;


    if ( defined $self->bib and $self->bib ne '' ) {
        my $bibtex_entry = new Text::BibTeX::Entry();
        my $s            = $bibtex_entry->parse_s( $self->bib );

        unless ( $bibtex_entry->parse_ok ) {
            return 0;
        }

        $self->bibtex_key($bibtex_entry->key);
        $self->year( $bibtex_entry->get('year') );
        if( $bibtex_entry->exists('booktitle') ){
            $self->title($bibtex_entry->get('booktitle'));
        }
        if( $bibtex_entry->exists('title') ){
            $self->title($bibtex_entry->get('title'));
        }
        $self->abstract( $bibtex_entry->get('abstract') || undef);
        $self->_bibtex_type( $bibtex_entry->type );
        return 1;
    }
    return 0;
}
####################################################################################
sub add_bibtex_field {
    my $self  = shift;
    my $field = shift;
    my $value = shift;

    my $entry = new Text::BibTeX::Entry();
    $entry->parse_s($self->bib);
    return -1 unless $entry->parse_ok;
    my $key = $entry->key;

    $entry->set( $field, $value );
    my $new_bib = $entry->print_s;

    $self->bib($new_bib);
    $self->populate_from_bib();
}
####################################################################################
sub bibtex_has_field {

    # returns 1 if bibtex of this entry has filed
    my $self         = shift;
    my $bibtex_field = shift;
    my $this_bib     = $self->bib;

    my $bibtex_entry = new Text::BibTeX::Entry();
    $bibtex_entry->parse_s($this_bib);
    return 1 if $bibtex_entry->exists($bibtex_field);
    return 0;
}
####################################################################################
sub get_bibtex_field_value {

    # returns 1 if bibtex of this entry has filed
    my $self         = shift;
    my $bibtex_field = shift;
    my $this_bib     = $self->bib;

    if ( $self->bibtex_has_field($bibtex_field) ) {
        my $bibtex_entry = new Text::BibTeX::Entry();
        $bibtex_entry->parse_s($this_bib);
        return $bibtex_entry->get($bibtex_field);
    }
    return undef;
}
####################################################################################
sub fix_month {
    my $self         = shift;
    my $bibtex_entry = new Text::BibTeX::Entry();
    $bibtex_entry->parse_s( $self->{bib} );

    my $num_fixes     = 0;
    my $month_numeric = 0;

    if ( $self->bibtex_has_field('month') ) {
        my $month_str = $bibtex_entry->get('month');
        $month_numeric
            = BibSpace::Controller::Core::get_month_numeric($month_str);
        
    }
    if($self->{month} != $month_numeric){
        $self->{month} = $month_numeric; 
        $num_fixes = 1;
    }
    # ve leave changed 
    if($self->{sort_month} == 0 and $self->{sort_month} != $month_numeric){
        $self->{sort_month} = $month_numeric;
    }
    
    

    return $num_fixes;
}
########################################################################################################################
sub has_tag_named {
    my $self = shift;
    my $name = shift;

    my $found = $self->tags_find(
        sub { ($_->name cmp $name)==0 }
    );
    return 1 if defined $found;
    return 0;
}
########################################################################################################################
sub is_talk_in_tag {
    my $self = shift;
    my $sum
        = $self->has_tag_named("Talks")
        + $self->has_tag_named("Talk")
        + $self->has_tag_named("talks")
        + $self->has_tag_named("talk");
    return 1 if $sum > 0;
    return 0;
}
########################################################################################################################
sub fix_entry_type_based_on_tag {
    my $self = shift;

    my $is_talk_db  = $self->is_talk();
    my $is_talk_tag = $self->is_talk_in_tag();

    if ( $is_talk_tag and $is_talk_db ) {

        # say "both true: OK";
        return 0;
    }
    elsif ( $is_talk_tag and $is_talk_db == 0 ) {

        # say "tag true, DB false. Should write to DB";
        $self->make_talk();
        return 1;
    }
    elsif ( $is_talk_tag == 0 and $is_talk_db ) {

        # say "tag false, DB true. do nothing";
        return 0;
    }

    # say "both false. Do nothing";
    return 0;
}
####################################################################################
sub postprocess_updated {
    my $self     = shift;
    my $bst_file = shift;

    $bst_file = $self->bst_file if !defined $bst_file;

    warn
        "Warning, you use Mentry->postprocess_updated without valid bst file!"
        unless defined $bst_file;

    $self->populate_from_bib();
    $self->fix_month();
    $self->regenerate_html( 0, $bst_file );

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
sub authors {
    my $self = shift;
    return $self->authors_all;
}
####################################################################################
sub has_author {
    my $self = shift;
    my $a = shift;

    my $exists = $self->authors_find_index( sub { $_->equals($a) } ) > -1;
    return $exists;
}
####################################################################################
sub has_master_author {
    my $self = shift;
    my $a = shift;

    my $author = $self->authors_find( sub { $_->equals($a) } );
    if($author){
        return $author->is_master;
    }
    return 0;
}
####################################################################################
sub assign_author {
    my ($self, @authors)   = @_;

    return 0 if !@authors or scalar @authors == 0;

    my $added = 0;
    foreach my $a ( @authors ){
        if( defined $a and !$self->has_author( $a ) ){
            $self->authors_add( $a );
            ++$added;
            if( !$a->has_entry($self) ){
                $a->assign_entry($self);
            }
        }
    }
    return $added;
}
####################################################################################
sub remove_author {
    my $self   = shift;
    my $author = shift;

    my $index = $self->authors_find_index( sub { $_->equals($author) } );
    return 0 if $index == -1;
    return 1 if $self->authors_delete($index);
    return 0;
}
####################################################################################
sub remove_all_authors {
    my $self = shift;

    $self->authors_clear;
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
sub get_authors_from_bibtex {
    my $self = shift;

    my @authors;

    foreach my $name ( $self->author_names_from_bibtex() ) {
        my $a = MAuthor->new( uid => $name );
        push @authors, $a;
    }
    return @authors;
}
####################################################################################
sub teams {
    my $self = shift;

    my %final_teams;
    foreach my $author ( $self->authors ) {

        foreach my $team ( $author->teams ) {
            if ($author->joined_team( $team ) <= $self->year
                and (  $author->left_team( $team ) > $self->year
                    or $author->left_team( $team ) == 0 )
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

    return 1 if any { $_->equals($team) } $self->teams;
    return 0;

}
####################################################################################
sub exceptions {
    my $self = shift;
    return $self->exceptions_all;
}
####################################################################################
sub remove_exception {
    my $self      = shift;
    my $exception = shift;

    my $index = $self->exceptions_find_index(
        sub { $_->equals( $exception ) }
    );
    return 0 if $index == -1;
    return 1 if $self->exceptions_delete($index);
    return 0;
}
####################################################################################
sub assign_exception {
    my $self      = shift;
    my $exception = shift;



    return 0
        if !defined $self->id
        or $self->id < 0
        or !defined $exception
        or $exception->id <= 0;

    my $result = $self->exceptions_add($exception);
    # say "adding excpetion ". $exception->toString;
    # say "Entry has exceptions: \n". join ("\n", map { $_->toString } $self->exceptions_all );

    return 1 if $result;
    return 0;
}
####################################################################################
sub tags {
    my $self     = shift;
    my $tag_type = shift;

    if ( defined $tag_type ) {
        return $self->tags_filter(
            sub {
                $_->type == $tag_type;
            }
        );
    }

    return $self->tags_all;
}
####################################################################################
sub has_tag {
    my $self = shift;
    my $tag = shift;

    my $exists = $self->tags_find_index( sub { $_->equals($tag) } ) > -1;
    return $exists;
}
####################################################################################
sub assign_tag {
    my ($self, @tags)   = @_; 

    return 0 if !@tags or scalar @tags == 0;

    my $added = 0;
    foreach my $tag ( @tags ){
        if( defined $tag and !$self->has_tag( $tag ) ){
            $self->tags_add( $tag );
            ++$added;
            # if( !$tag->has_entry($self) ){
            #     $tag->assign_entry($self);
            # }
        }
    }
    return $added;
}
####################################################################################
sub remove_tag {
    my $self = shift;
    my $tag  = shift;

    my $index = $self->tags_find_index( sub { $_->equals($tag) });
    return 0 if $index == -1;
    return 1 if $self->tags_delete($index);
    return 0;
}
####################################################################################
sub remove_tag_by_id {
    my $self   = shift;
    my $tag_id = shift;

    my $index = $self->tags_find_index( sub { $_->id == $tag_id } );
    return 0 if $index == -1;
    return 1 if $self->tags_delete($index);
    return 0;
}
####################################################################################
sub remove_tag_by_name {
    my $self     = shift;
    my $tag_name = shift;

    my $index = $self->tags_find_index(
        sub {
                (defined $_->name
                and defined $tag_name
                and $_->name eq $tag_name);
        }
    );
    return 0 if $index == -1;
    return 1 if $self->tags_delete($index);
    return 0;
}


####################################################################################
sub get_tags_from_bibtex {
    my $self = shift;

    my @tags;

    foreach my $name ( $self->tag_names_from_bibtex() ) {
        push @tags, MTag->new( name => $name );
    }
    return @tags;
}
####################################################################################
sub tag_names_from_bibtex {
    my $self = shift;

    my @tag_names;

    my $bibtex_entry = new Text::BibTeX::Entry();
    $bibtex_entry->parse_s( $self->bib );

    if ( $bibtex_entry->exists('tags') ) {
        my $tags_str = $bibtex_entry->get('tags');
        if($tags_str){
            # change , into ;
            $tags_str =~ s/\,/;/g;    
            # remove leading and trailing spaces
            $tags_str =~ s/^\s+|\s+$//g;

            @tag_names = split( ';', $tags_str );
            # remove leading and trailing spaces
            map { s/^\s+|\s+$//g } @tag_names;
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
sub static_get_unique_years_array {
    my $self = shift;
    my $dbh  = shift;

#my @pubs = Fget_publications_main_hashed_args_only($self, {hidden => undef, visible => 1});
    my @pubs
        = MEntry->static_get_filter( $dbh, undef, undef, undef, undef, undef,
        undef, 1, undef, undef );
    my @years = map { $_->year } @pubs;

    my $set = Set::Scalar->new(@years);
    $set->delete('');
    my @sorted_years = sort { $b <=> $a } $set->members;

    return @sorted_years;
}
####################################################################################
sub static_get_from_id_array {
    my $self             = shift;
    my $dbh              = shift;
    my $input_id_arr_ref = shift;
    my $keep_order       = shift // 0
        ; # if set to 1, it keeps the order of the output_arr exactly as in the input_id_arr

    my @input_id_arr = @$input_id_arr_ref;

    unless ( grep { defined($_) } @input_id_arr ) {    # if array is empty
        return ();
    }

    my $sort = 1 if $keep_order == 0 or !defined $keep_order;
    my @output_arr = ();

    # the performance here can be optimized
    for my $wanted_id (@input_id_arr) {
        my $e = MEntry->static_get( $dbh, $wanted_id );
        push @output_arr, $e if defined $e;
    }

    if ( $keep_order == 0 ) {
        return sort sort_by_year_month_modified_time @output_arr;
    }
    return @output_arr;
}
####################################################################################
####################################################################################

####################################################################################
sub decodeLatex {
    my $self = shift;
    if ( defined $self->title ) {
        my $title = $self->title;
        $title =~ s/^\{//g;
        $title =~ s/\}$//g;
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

no Moose;
__PACKAGE__->meta->make_immutable;
1;
