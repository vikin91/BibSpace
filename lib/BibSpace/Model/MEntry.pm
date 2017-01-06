package MEntry;



use Moose;
use BibSpace::Model::MEntryMySQL;
extends 'MEntryMySQL';

no Moose;
__PACKAGE__->meta->make_immutable;
1;


# use BibSpace::Model::MTag;
# use BibSpace::Model::MTagType;

# use Data::Dumper;
# use utf8;
# use Text::BibTeX;    # parsing bib files
# use 5.010;           #because of ~~ and say
# use DBI;
# use Try::Tiny;
# use TeX::Encode;
# use Encode;
# use MooseX::Storage;
# with Storage('format' => 'JSON', 'io' => 'File');


# has 'id'              => ( is => 'rw' );
# has 'entry_type'      => ( is => 'rw', default => 'paper' );
# has 'bibtex_key'      => ( is => 'rw' );
# has 'bibtex_type'     => ( is => 'rw' );
# has 'bib'             => ( is => 'rw', isa => 'Str' );
# has 'html'            => ( is => 'rw' );
# has 'html_bib'        => ( is => 'rw' );
# has 'abstract'        => ( is => 'rw' );
# has 'title'           => ( is => 'rw' );
# has 'hidden'          => ( is => 'rw', default => 0 );
# has 'year'            => ( is => 'rw' );
# has 'month'           => ( is => 'rw', default => 0 );
# has 'sort_month'      => ( is => 'rw', default => 0 );
# has 'teams_str'       => ( is => 'rw' );
# has 'people_str'      => ( is => 'rw' );
# has 'tags_str'        => ( is => 'rw' );
# has 'creation_time'   => ( is => 'rw' );
# has 'modified_time'   => ( is => 'rw' );
# has 'need_html_regen' => ( is => 'rw', default => '1' );

# # not DB fields
# has 'warnings' => ( is => 'ro', default => '', traits => [ 'DoNotSerialize' ] );
# has 'bst_file' => ( is => 'ro', default => './lib/descartes2.bst', traits => [ 'DoNotSerialize' ] );

# ####################################################################################
# sub TO_JSON {
#     shift->pack();
# }
# ####################################################################################
# sub FROM_JSON {
#     shift->unpack();
# }
# ####################################################################################
# sub static_all {
#     my $self = shift;
#     my $dbh  = shift;

#     my $qry = "SELECT
#               id,
#               entry_type,
#               bibtex_key,
#               bibtex_type,
#               bib,
#               html,
#               html_bib,
#               abstract,
#               title,
#               hidden,
#               year,
#               month,
#               sort_month,
#               teams_str,
#               people_str,
#               tags_str,
#               creation_time,
#               modified_time,
#               need_html_regen
#           FROM Entry";
#     my @objs = ();
#     my $sth  = $dbh->prepare($qry);
#     $sth->execute();

#     while ( my $row = $sth->fetchrow_hashref() ) {
#         push @objs,
#             MEntry->new(
#             id              => $row->{id},
#             entry_type      => $row->{entry_type},
#             bibtex_key      => $row->{bibtex_key},
#             bibtex_type     => $row->{bibtex_type},
#             bib             => $row->{bib},
#             html            => $row->{html},
#             html_bib        => $row->{html_bib},
#             abstract        => $row->{abstract},
#             title           => $row->{title},
#             hidden          => $row->{hidden},
#             year            => $row->{year},
#             month           => $row->{month},
#             sort_month      => $row->{sort_month},
#             teams_str       => $row->{teams_str},
#             people_str      => $row->{people_str},
#             tags_str        => $row->{tags_str},
#             creation_time   => $row->{creation_time},
#             modified_time   => $row->{modified_time},
#             need_html_regen => $row->{need_html_regen},
#             );
#     }
#     return @objs;
# }
# ####################################################################################
# sub static_get {
#     my $self = shift;
#     my $dbh  = shift;
#     my $id   = shift;

#     my $qry = "SELECT 
#               id,
#               entry_type,
#               bibtex_key,
#               bibtex_type,
#               bib,
#               html,
#               html_bib,
#               abstract,
#               title,
#               hidden,
#               year,
#               month,
#               sort_month,
#               teams_str,
#               people_str,
#               tags_str,
#               creation_time,
#               modified_time,
#               need_html_regen
#           FROM Entry
#           WHERE id = ?";

#     my $sth = $dbh->prepare($qry);
#     $sth->execute($id);
#     my $row = $sth->fetchrow_hashref();

#     if ( !defined $row ) {
#         return undef;
#     }

#     my $e = MEntry->new(
#         id              => $id,
#         entry_type      => $row->{entry_type},
#         bibtex_key      => $row->{bibtex_key},
#         bibtex_type     => $row->{bibtex_type},
#         bib             => $row->{bib},
#         html            => $row->{html},
#         html_bib        => $row->{html_bib},
#         abstract        => $row->{abstract},
#         title           => $row->{title},
#         hidden          => $row->{hidden},
#         year            => $row->{year},
#         month           => $row->{month},
#         sort_month      => $row->{sort_month},
#         teams_str       => $row->{teams_str},
#         people_str      => $row->{people_str},
#         tags_str        => $row->{tags_str},
#         creation_time   => $row->{creation_time},
#         modified_time   => $row->{modified_time},
#         need_html_regen => $row->{need_html_regen}
#     );
#     $e->decodeLatex();
#     return $e;
# }
# ####################################################################################
# sub static_get_by_bibtex_key {
#     my $self       = shift;
#     my $dbh        = shift;
#     my $bibtex_key = shift;

#     my $qry = "SELECT 
#               id,
#               entry_type,
#               bibtex_key,
#               bibtex_type,
#               bib,
#               html,
#               html_bib,
#               abstract,
#               title,
#               hidden,
#               year,
#               month,
#               sort_month,
#               teams_str,
#               people_str,
#               tags_str,
#               creation_time,
#               modified_time,
#               need_html_regen
#           FROM Entry
#           WHERE bibtex_key = ?";

#     my $sth = $dbh->prepare($qry);
#     $sth->execute($bibtex_key);
#     my $row = $sth->fetchrow_hashref();

#     if ( !defined $row ) {
#         return undef;
#     }

#     my $e = MEntry->new(
#         id              => $row->{id},
#         entry_type      => $row->{entry_type},
#         bibtex_key      => $row->{bibtex_key},
#         bibtex_type     => $row->{bibtex_type},
#         bib             => $row->{bib},
#         html            => $row->{html},
#         html_bib        => $row->{html_bib},
#         abstract        => $row->{abstract},
#         title           => $row->{title},
#         hidden          => $row->{hidden},
#         year            => $row->{year},
#         month           => $row->{month},
#         sort_month      => $row->{sort_month},
#         teams_str       => $row->{teams_str},
#         people_str      => $row->{people_str},
#         tags_str        => $row->{tags_str},
#         creation_time   => $row->{creation_time},
#         modified_time   => $row->{modified_time},
#         need_html_regen => $row->{need_html_regen}
#     );
#     $e->decodeLatex();
#     return $e;
# }
# ####################################################################################

# =item equals_bibtex
#     Assumes that both objects are equal if the bibtex code is identical
# =cut

# sub equals_bibtex {
#     my $self = shift;
#     my $obj  = shift;

#     return 0 if !defined $obj or !defined $self;
#     return $self->{bib} eq $obj->{bib};
# }
# ####################################################################################
# sub bump_modified_time {
#     my $self = shift;
#     my $dbh  = shift;

#     return -1 unless defined $self->{id};

#     my $qry = "UPDATE Entry SET
#                 modified_time=NOW()
#                 WHERE id = ?";

#     my $sth = $dbh->prepare($qry);
#     my $result;
#     try {
#         $result = $sth->execute( $self->{id} );
#         $sth->finish();
#     }
#     catch {
#         warn "MEntry update exception: $_";
#     };
#     return $result;
# }
# ####################################################################################
# sub update {
#     my $self = shift;
#     my $dbh  = shift;

#     return -1 unless defined $self->{id};


#     # update field 'modified_time' only if needed
#     my $need_modified_update
#         = not $self->equals_bibtex( MEntry->static_get( $dbh, $self->{id} ) );

#     my $qry = "UPDATE Entry SET
#                 entry_type=?,
#                 bibtex_key=?,
#                 bibtex_type=?,
#                 bib=?,
#                 html=?,
#                 html_bib=?,
#                 abstract=?,
#                 title=?,
#                 hidden=?,
#                 year=?,
#                 month=?,
#                 sort_month=?,
#                 teams_str=?,
#                 people_str=?,
#                 tags_str=?,
#                 need_html_regen=?
#                 WHERE id = ?";

#     # po tags_str
#     # creation_time=?,
#     # modified_time=NOW(),
#     # przed need_html_regen=?

#     my $sth = $dbh->prepare($qry);
#     my $result = "";
#     try {
#         $result = $sth->execute(
#             $self->{entry_type},  $self->{bibtex_key},
#             $self->{bibtex_type}, $self->{bib},
#             $self->{html},        $self->{html_bib},
#             $self->{abstract},    $self->{title},
#             $self->{hidden},      $self->{year},
#             $self->{month},       $self->{sort_month},
#             $self->{teams_str},   $self->{people_str},
#             $self->{tags_str},    $self->{need_html_regen},
#             $self->{id}
#         );
#         $self->bump_modified_time($dbh) if $need_modified_update;
#         $sth->finish();
#     }
#     catch {
#         warn "MEntry update exception: $_";
#     };
#     return $result;
# }
# ####################################################################################
# sub insert {
#     my $self = shift;
#     my $dbh  = shift;

#     my $result = "";

#     my $qry = "
#     INSERT INTO Entry(
#     entry_type,
#     bibtex_key,
#     bibtex_type,
#     bib,
#     html,
#     html_bib,
#     abstract,
#     title,
#     hidden,
#     year,
#     month,
#     sort_month,
#     teams_str,
#     people_str,
#     tags_str,
#     creation_time,
#     modified_time,
#     need_html_regen
#     ) 
#     VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,NOW(),NOW(),?);";
#     my $sth = $dbh->prepare($qry);
#     $result = $sth->execute(
#         $self->{entry_type}, $self->{bibtex_key}, $self->{bibtex_type},
#         $self->{bib}, $self->{html}, $self->{html_bib}, $self->{abstract},
#         $self->{title}, $self->{hidden}, $self->{year}, $self->{month},
#         $self->{sort_month}, $self->{teams_str}, $self->{people_str},
#         $self->{tags_str},

#         # $self->{creation_time},
#         # $self->{modified_time},
#         $self->{need_html_regen},
#     );
#     my $inserted_id = $dbh->last_insert_id( '', '', 'Entry', '' );
#     $self->{id} = $inserted_id;

#     # say "Mentry insert. inserted_id = $inserted_id";
#     $sth->finish();
#     return $inserted_id;    #or $result;
# }
# ####################################################################################
# sub save {
#     my $self = shift;
#     my $dbh  = shift;

#     my $result = "";

#     $self->decodeLatex();
#     $self->populate_from_bib();

#     $self->{creation_time} = '1970-01-01 00:00:00'
#         if !defined $self->{creation_time}
#         or $self->{creation_time} eq ''
#         or $self->{creation_time} eq '0000-00-00 00:00:00';

#     if ( !defined $self->{id} or $self->{id} <= 0 ) {
#         my $inserted_id = $self->insert($dbh);
#         $self->{id} = $inserted_id;

#         # say "Mentry save: inserting. inserted_id = ".$self->{id};
#         return $inserted_id;
#     }
#     elsif ( defined $self->{id} and $self->{id} > 0 ) {

#         # say "Mentry save: updating ID = ".$self->{id};
#         return $self->update($dbh);
#     }
#     else {
#         warn "Mentry save: cannot either insert nor update :( ID = "
#             . $self->{id};
#     }
# }
# ####################################################################################
# sub delete {
#     my $self = shift;
#     my $dbh  = shift;

#     my $qry    = "DELETE FROM Entry WHERE id=?;";
#     my $sth    = $dbh->prepare($qry);
#     my $result = $sth->execute( $self->{id} );

#     return $result;
# }
# ####################################################################################
# sub is_hidden {
#     my $self = shift;
#     return $self->{hidden} == 1;
# }
# ####################################################################################
# sub hide {
#     my $self = shift;
#     my $dbh  = shift;

#     $self->{hidden} = 1;
#     $self->save($dbh);
# }
# ####################################################################################
# sub unhide {
#     my $self = shift;
#     my $dbh  = shift;

#     $self->{hidden} = 0;
#     $self->save($dbh);
# }
# ####################################################################################
# sub toggle_hide {
#     my $self = shift;
#     my $dbh  = shift;

#     if ( $self->{hidden} == 1 ) {
#         $self->unhide($dbh);
#     }
#     else {
#         $self->hide($dbh);
#     }
# }
# ####################################################################################
# sub make_paper {
#     my $self = shift;
#     my $dbh  = shift;

#     $self->{entry_type} = 'paper';
#     $self->save($dbh);
# }
# ####################################################################################
# sub is_paper {
#     my $self = shift;
#     return 1 if $self->{entry_type} eq 'paper';
#     return 0;
# }
# ####################################################################################
# sub make_talk {
#     my $self = shift;
#     my $dbh  = shift;

#     $self->{entry_type} = 'talk';
#     $self->save($dbh);
# }
# ####################################################################################
# sub is_talk {
#     my $self = shift;
#     return 1 if $self->{entry_type} eq 'talk';
#     return 0;
# }
# ####################################################################################
# sub populate_from_bib {
#     my $self = shift;


#     if ( defined $self->{bib} and $self->{bib} ne '' ) {
#         my $bibtex_entry = new Text::BibTeX::Entry();
#         my $s            = $bibtex_entry->parse_s( $self->{bib} );

#         unless ( $bibtex_entry->parse_ok ) {
#             return 0;
#         }

#         $self->{bibtex_key} = $bibtex_entry->key;
#         $self->{year}       = $bibtex_entry->get('year');
#         $self->{title}      = $bibtex_entry->get('booktitle')
#             if $bibtex_entry->exists('booktitle');
#         $self->{title} = $bibtex_entry->get('title')
#             if $bibtex_entry->exists('title');
#         $self->{abstract} = $bibtex_entry->get('abstract') || undef;
#         $self->{bibtex_type} = $bibtex_entry->type;
#         return 1;
#     }
#     return 0;
# }
# ####################################################################################
# sub bibtex_has_field {

#     # returns 1 if bibtex of this entry has filed
#     my $self         = shift;
#     my $bibtex_field = shift;
#     my $this_bib     = $self->{bib};

#     my $bibtex_entry = new Text::BibTeX::Entry();
#     $bibtex_entry->parse_s($this_bib);
#     return 1 if $bibtex_entry->exists($bibtex_field);
#     return 0;
# }
# ####################################################################################
# sub get_bibtex_field_value {

#     # returns 1 if bibtex of this entry has filed
#     my $self         = shift;
#     my $bibtex_field = shift;
#     my $this_bib     = $self->{bib};

#     if ( $self->bibtex_has_field($bibtex_field) ) {
#         my $bibtex_entry = new Text::BibTeX::Entry();
#         $bibtex_entry->parse_s($this_bib);
#         return $bibtex_entry->get($bibtex_field);
#     }
#     return undef;
# }
# ####################################################################################
# sub fix_month {
#     my $self         = shift;
#     my $bibtex_entry = new Text::BibTeX::Entry();
#     $bibtex_entry->parse_s( $self->{bib} );

#     my $num_fixes = 0;
#     my $month_numeric = 0;

#     if ( $self->bibtex_has_field('month') ) {
#         my $month_str = $bibtex_entry->get('month');
#         $month_numeric = BibSpace::Controller::Core::get_month_numeric($month_str);
#         $num_fixes          = 1;
#     }
#     $self->{month}      = $month_numeric;
#     $self->{sort_month} = $month_numeric;

#     return $num_fixes;
# }
# ########################################################################################################################
# sub is_talk_in_DB {
#     my $self = shift;
#     my $dbh  = shift;

#     my $db_e = MEntry->static_get( $dbh, $self->{id} );
#     return undef unless defined $db_e;
#     if ( $db_e->{entry_type} eq 'talk' ) {
#         return 1;
#     }
#     return 0;
# }
# ########################################################################################################################
# sub is_talk_in_tag {
#     my $self = shift;
#     my $dbh  = shift;
#     my $sum
#         = $self->has_tag_named( $dbh, "Talks" )
#         + $self->has_tag_named( $dbh, "Talk" )
#         + $self->has_tag_named( $dbh, "talks" )
#         + $self->has_tag_named( $dbh, "talk" );
#     return 1 if $sum > 0;
#     return 0;
# }
# ########################################################################################################################
# sub fix_entry_type_based_on_tag {
#     my $self = shift;
#     my $dbh  = shift;

#     my $is_talk_db  = $self->is_talk_in_DB($dbh);
#     my $is_talk_tag = $self->is_talk_in_tag($dbh);

#     if ( $is_talk_tag and $is_talk_db ) {

#         # say "both true: OK";
#         return 0;
#     }
#     elsif ( $is_talk_tag and $is_talk_db == 0 ) {

#         # say "tag true, DB false. Should write to DB";
#         $self->make_talk($dbh);
#         return 1;
#     }
#     elsif ( $is_talk_tag == 0 and $is_talk_db ) {

#         # say "tag false, DB true. do nothing";
#         return 0;
#     }

#     # say "both false. Do nothing";
#     return 0;
# }
# ####################################################################################
# sub postprocess_updated {
#     my $self     = shift;
#     my $dbh      = shift;
#     my $bst_file = shift;

#     $bst_file = $self->{bst_file} if !defined $bst_file;

#     warn
#         "Warning, you use Mentry->postprocess_updated without valid bst file!"
#         unless defined $bst_file;

#     $self->process_tags($dbh);
#     my $populated = $self->populate_from_bib();
#     $self->fix_month();
#     $self->process_authors( $dbh, 1 );

#     $self->regenerate_html( $dbh, 0, $bst_file );
#     $self->save($dbh);

#     return 1;    # TODO: old code!
# }
# ####################################################################################
# sub generate_html {
#     my $self     = shift;
#     my $bst_file = shift;

#     $bst_file = $self->{bst_file} if !defined $bst_file;

#     $self->populate_from_bib();

#     my $c = BibSpaceBibtexToHtml::BibSpaceBibtexToHtml->new();
#     $self->{html} = $c->convert_to_html(
#         { method => 'new', bib => $self->{bib}, bst => $bst_file } );
#     $self->{warnings} = join( ', ', @{ $c->{warnings_arr} } );

#     $self->{need_html_regen} = 0;

#     return ( $self->{html}, $self->{bib} );
# }
# ####################################################################################
# sub regenerate_html {
#     my $self     = shift;
#     my $dbh      = shift;
#     my $force    = shift;
#     my $bst_file = shift;

#     $bst_file = $self->{bst_file} if !defined $bst_file;
#     warn "Warning, you use Mentry->regenerate_html without valid bst file!"
#         unless defined $bst_file;

#     if (   $force == 1
#         or $self->{need_html_regen} == 1
#         or $self->{html} =~ m/ERROR/ )
#     {
#         $self->populate_from_bib();
#         $self->generate_html($bst_file);
#         $self->{need_html_regen} = 0;
#     }
# }
# ####################################################################################
# sub authors_from_bibtex {
#     my $self = shift;

#     $self->populate_from_bib();

#     my $bibtex_entry = new Text::BibTeX::Entry();
#     $bibtex_entry->parse_s( $self->{bib} );
#     my $entry_key = $self->{bibtex_key};

#     my @names;
#     if ( $bibtex_entry->exists('author') ) {
#         my @authors = $bibtex_entry->split('author');
#         my (@n) = $bibtex_entry->names('author');
#         push @names, @n;
#     }
#     elsif ( $bibtex_entry->exists('editor') )
#     {    # issue with Alex Dagstuhl Chapter
#         my @authors = $bibtex_entry->split('editor');
#         my (@n) = $bibtex_entry->names('editor');
#         push @names, @n;
#     }

#     my @author_names;
#     foreach my $name (@names) {
#         push @author_names, BibSpace::Controller::Core::create_user_id($name);
#     }
#     return @author_names;
# }
# ####################################################################################
# sub create_authors {
#     my $self = shift;
#     my $dbh  = shift;

#     my $num_authors_created = 0;

#     foreach my $name ( $self->authors_from_bibtex() ) {
#         my $author_candidate = MAuthor->static_get_by_name( $dbh, $name );

#         # such author does not exist
#         if ( !defined $author_candidate ) {
#             $author_candidate = MAuthor->new( uid => $name );
#             $author_candidate->save($dbh);


#             ++$num_authors_created;
#         }
#         else {
#             # such author exists already
#             # we do nothing

#         }
#     }
#     return $num_authors_created;
# }
# ####################################################################################
# sub authors {
#     my $self = shift;
#     my $dbh  = shift;

#     die "MEntry::authors Calling authors on undefined or empty entry!"
#         if !defined $self->{id}
#         or $self->{id} < 0;
#     die "MEntry::authors Calling authors with no database hande!"
#         unless defined $dbh;


#     my $qry
#         = "SELECT entry_id, author_id FROM Entry_to_Author WHERE entry_id = ?";
#     my $sth = $dbh->prepare_cached($qry);
#     $sth->execute( $self->{id} );

#     my @authors;

#     while ( my $row = $sth->fetchrow_hashref() ) {
#         my $author = MAuthor->static_get( $dbh, $row->{author_id} );

#         push @authors, $author if defined $author;
#     }
#     return @authors;
# }
# ####################################################################################
# sub teams {
#     my $self = shift;
#     my $dbh  = shift;

#     die "MEntry::teams Calling authors on undefined or empty entry!"
#         if !defined $self->{id}
#         or $self->{id} < 0;
#     die "MEntry::teams Calling authors with no database handle!"
#         unless defined $dbh;

#     my %final_teams;
#     foreach my $author ( $self->authors($dbh) ) {
#         foreach my $team ( $author->teams($dbh) ) {
#             if ($author->joined_team( $dbh, $team ) <= $self->{year}
#                 and (  $author->left_team( $dbh, $team ) > $self->{year}
#                     or $author->left_team( $dbh, $team ) == 0 )
#                 )
#             {
#                 # $final_teams{$team}       = 1; # BAD: $team gets stringified
#                 $final_teams{ $team->{id} } = $team;
#             }
#         }
#     }
#     return values %final_teams;
# }
# ####################################################################################
# sub exceptions {
#     my $self = shift;
#     my $dbh  = shift;

#     die "MEntry::exceptions Calling authors on undefined or empty entry!"
#         if !defined $self->{id}
#         or $self->{id} < 0;
#     die "MEntry::exceptions Calling authors with no database handle!"
#         unless defined $dbh;


#     my $qry
#         = "SELECT team_id, entry_id FROM Exceptions_Entry_to_Team WHERE entry_id = ?";
#     my $sth = $dbh->prepare_cached($qry);
#     $sth->execute( $self->{id} );

#     my %teams;
#     while ( my $row = $sth->fetchrow_hashref() ) {
#         my $team = MTeam->static_get( $dbh, $row->{team_id} );
#         $teams{ $team->{id} } = $team;
#     }

#     return values %teams;
# }
# ####################################################################################
# sub remove_exception {
#     my $self      = shift;
#     my $dbh       = shift;
#     my $exception = shift;

#     return 0
#         if !defined $exception
#         or !defined $self->{id}
#         or $self->{id} < 0;

#     my $sth
#         = $dbh->prepare(
#         "DELETE FROM Exceptions_Entry_to_Team WHERE entry_id=? AND team_id=?"
#         );
#     return $sth->execute( $self->{id}, $exception->{id} );
# }
# ####################################################################################
# sub assign_exception {
#     my $self      = shift;
#     my $dbh       = shift;
#     my $exception = shift;

#     return 0
#         if !defined $exception
#         or !defined $self->{id}
#         or $self->{id} < 0;

#     my $sth
#         = $dbh->prepare(
#         'INSERT IGNORE INTO Exceptions_Entry_to_Team(entry_id, team_id) VALUES(?, ?)'
#         );
#     $sth->execute( $self->{id}, $exception->{id} );
#     return 1;
# }
# ####################################################################################
# sub static_entries_with_exception {
#     my $self = shift;
#     my $dbh  = shift;

#     die
#         "MEntry::static_entries_with_exception Calling authors with no database handle!"
#         unless defined $dbh;


#     my $qry
#         = "SELECT DISTINCT entry_id FROM Exceptions_Entry_to_Team WHERE team_id>-1";
#     my $sth = $dbh->prepare_cached($qry);
#     $sth->execute();

#     my @objs;
#     while ( my $row = $sth->fetchrow_hashref() ) {
#         my $entry = MEntry->static_get( $dbh, $row->{entry_id} );
#         push @objs, $entry;
#     }

#     return @objs;
# }
# ####################################################################################
# sub assign_author {
#     my $self   = shift;
#     my $dbh    = shift;
#     my $author = shift;

#     if ( defined $author ) {
#         my $sth
#             = $dbh->prepare(
#             'INSERT IGNORE INTO Entry_to_Author(author_id, entry_id) VALUES(?, ?)'
#             );
#         $sth->execute( $author->{id}, $self->{id} );
#         return 1;
#     }
#     return 0;
# }
# ####################################################################################
# sub remove_author {
#     my $self   = shift;
#     my $dbh    = shift;
#     my $author = shift;

#     if ( defined $author ) {

#         my $sth
#             = $dbh->prepare(
#             'DELETE FROM Entry_to_Author WHERE entry_id = ? AND author_id = ?'
#             );
#         $sth->execute( $self->{id}, $author->{id} );
#         return 1;
#     }
#     return 0;
# }
# ####################################################################################
# sub remove_all_authors {
#     my $self = shift;
#     my $dbh  = shift;

#     if ( defined $self->{id} ) {
#         my $sth
#             = $dbh->prepare('DELETE FROM Entry_to_Author WHERE entry_id = ?');
#         $sth->execute( $self->{id} );
#     }
# }
# ####################################################################################

# =item assign_existing_authors
# This function processes the authors from bibtex entries, 
# then searches for existing authors in database and 
# assigns them to the entry by modifying the database.

# Author will not be assigned if it does not extist in the DB !
# =cut 

# sub assign_existing_authors {
#     my $self = shift;
#     my $dbh  = shift;

#     $self->populate_from_bib();
#     my $bibtex_entry = new Text::BibTeX::Entry();
#     $bibtex_entry->parse_s( $self->{bib} );
#     my $entry_key = $self->{bibtex_key};

#     my $num_authors_assigned = 0;


#     $self->remove_all_authors($dbh);

# # We assume that entry has no authors, so $self->authors($dbh) cannot be used!

#     foreach my $name ( $self->authors_from_bibtex() ) {
#         my $author = MAuthor->static_get_by_name( $dbh, $name );
#         my $master = $author;
#         $master = $author->get_master($dbh) if defined $author;

#         my $num_assigned = 0;
#         $num_assigned = $self->assign_author( $dbh, $master )
#             if defined $author and defined $master;
#         $num_authors_assigned = $num_authors_assigned + $num_assigned;
#     }
#     return $num_authors_assigned;
# }
# ####################################################################################
# sub process_authors {
#     my $self           = shift;
#     my $dbh            = shift;
#     my $create_authors = shift // 0;

#     my $num_authors_created = 0;
#     $num_authors_created = $self->create_authors($dbh)
#         if $create_authors == 1;

#     my $num_authors_assigned = 0;
#     $num_authors_assigned = $self->assign_existing_authors($dbh);

#     return ( $num_authors_created, $num_authors_assigned );
# }
# ####################################################################################
# sub process_tags {
#     my $self = shift;
#     my $dbh  = shift;

#     $self->populate_from_bib();

#     my $bibtex_entry = new Text::BibTeX::Entry();
#     $bibtex_entry->parse_s( $self->{bib} );

#     my $e = MEntry->static_get_by_bibtex_key( $dbh, $self->{bibtex_key} );

#     return 0 if !defined $e;

#     my $num_tags_added = 0;

#     if ( $bibtex_entry->exists('tags') ) {
#         my $tags_str = $bibtex_entry->get('tags');
#         $tags_str =~ s/\,/;/g       if defined $tags_str;
#         $tags_str =~ s/^\s+|\s+$//g if defined $tags_str;

#         my @tags = ();
#         @tags = split( ';', $tags_str ) if defined $tags_str;

#         for my $tag (@tags) {
#             $tag =~ s/^\s+|\s+$//g;
#             $tag =~ s/\ /_/g if defined $tag;

#             my $tt = MTagType->new(name => "Imported", comment => "Automatically imported entries");
#             $tt->save($dbh);
#             $num_tags_added = $num_tags_added + $e->add_tags($dbh, [$tag], $tt->{id});
#         }
#     }
#     return $num_tags_added;
# }
# ####################################################################################
# sub sort_by_year_month_modified_time {

#     # $a and $b exist and are MEntry objects
#            $a->{year} <=> $b->{year}
#         or $a->{sort_month} <=> $b->{sort_month}
#         or $a->{month} <=> $b->{month}
#         or $a->{id} <=> $b->{id};

# # $a->{modified_time} <=> $b->{modified_time}; # needs an extra lib, so we just compare ids as approximation
# }
# ####################################################################################
# sub static_get_unique_years_array {
#     my $self = shift;
#     my $dbh  = shift;

# #my @pubs = Fget_publications_main_hashed_args_only($self, {hidden => undef, visible => 1});
#     my @pubs
#         = MEntry->static_get_filter( $dbh, undef, undef, undef, undef, undef,
#         undef, 1, undef, undef );
#     my @years = map { $_->{year} } @pubs;

#     my $set = Set::Scalar->new(@years);
#     $set->delete('');
#     my @sorted_years = sort { $b <=> $a } $set->members;

#     return @sorted_years;
# }
# ####################################################################################
# sub static_get_from_id_array {
#     my $self             = shift;
#     my $dbh              = shift;
#     my $input_id_arr_ref = shift;
#     my $keep_order       = shift // 0
#         ; # if set to 1, it keeps the order of the output_arr exactly as in the input_id_arr

#     my @input_id_arr = @$input_id_arr_ref;

#     unless ( grep { defined($_) } @input_id_arr ) {    # if array is empty
#         return ();
#     }

#     my $sort = 1 if $keep_order == 0 or !defined $keep_order;
#     my @output_arr = ();

#     # the performance here can be optimized
#     for my $wanted_id (@input_id_arr) {
#         my $e = MEntry->static_get( $dbh, $wanted_id );
#         push @output_arr, $e if defined $e;
#     }

#     if ( $keep_order == 0 ) {
#         return sort sort_by_year_month_modified_time @output_arr;
#     }
#     return @output_arr;
# }
# ####################################################################################
# ####################################################################################
# sub static_get_filter {
#     my $self = shift;
#     my $dbh  = shift;

#     my $master_id   = shift;
#     my $year        = shift;
#     my $bibtex_type = shift;
#     my $entry_type  = shift;
#     my $tagid       = shift;
#     my $teamid      = shift;
#     my $visible     = shift || 0;
#     my $permalink   = shift;
#     my $hidden      = shift;



#     my @params;

#     my $qry = "SELECT DISTINCT          
#                       Entry.id,
#                       Entry.entry_type,
#                       Entry.bibtex_key,
#                       Entry.bibtex_type,
#                       Entry.bib,
#                       Entry.html,
#                       Entry.html_bib,
#                       Entry.abstract,
#                       Entry.title,
#                       Entry.hidden,
#                       Entry.month,
#                       Entry.year,
#                       Entry.sort_month,
#                       Entry.teams_str,
#                       Entry.people_str,
#                       Entry.tags_str,
#                       Entry.creation_time,
#                       Entry.modified_time,
#                       Entry.need_html_regen
#                 FROM Entry
#                 LEFT JOIN Exceptions_Entry_to_Team  ON Entry.id = Exceptions_Entry_to_Team.entry_id
#                 LEFT JOIN Entry_to_Author ON Entry.id = Entry_to_Author.entry_id 
#                 LEFT JOIN Author ON Entry_to_Author.author_id = Author.id 
#                 LEFT JOIN Author_to_Team ON Entry_to_Author.author_id = Author_to_Team.author_id 
#                 LEFT JOIN OurType_to_Type ON OurType_to_Type.bibtex_type = Entry.bibtex_type 
#                 LEFT JOIN Entry_to_Tag ON Entry.id = Entry_to_Tag.entry_id 
#                 LEFT JOIN Tag ON Tag.id = Entry_to_Tag.tag_id 
#                 WHERE Entry.bibtex_key IS NOT NULL ";
#     if ( defined $hidden ) {
#         push @params, $hidden;
#         $qry .= "AND Entry.hidden=? ";
#     }
#     if ( defined $visible and $visible eq '1' ) {
#         $qry .= "AND Author.display=1 ";
#     }
#     if ( defined $master_id ) {
#         push @params, $master_id;
#         $qry .= "AND Entry_to_Author.author_id=? ";
#     }
#     if ( defined $year ) {
#         push @params, $year;
#         $qry .= "AND Entry.year=? ";
#     }
#     if ( defined $bibtex_type ) {
#         push @params, $bibtex_type;
#         $qry .= "AND OurType_to_Type.our_type=? ";
#     }
#     if ( defined $entry_type ) {
#         push @params, $entry_type;
#         $qry .= "AND Entry.entry_type=? ";
#     }
#     if ( defined $teamid ) {
#         push @params, $teamid;
#         push @params, $teamid;

#         # push @params, $teamid;
#         # $qry .= "AND Exceptions_Entry_to_Team.team_id=?  ";
#         $qry
#             .= "AND ((Exceptions_Entry_to_Team.team_id=? ) OR (Author_to_Team.team_id=? AND start <= Entry.year  AND (stop >= Entry.year OR stop = 0))) ";
#     }
#     if ( defined $tagid ) {
#         push @params, $tagid;
#         $qry .= "AND Entry_to_Tag.tag_id LIKE ?";
#     }
#     if ( defined $permalink ) {
#         push @params, $permalink;
#         $qry .= "AND Tag.permalink LIKE ?";
#     }
#     $qry
#         .= "ORDER BY Entry.year DESC, Entry.sort_month DESC, Entry.creation_time DESC, Entry.modified_time DESC, Entry.bibtex_key ASC";

#     # print $qry."\n";

#     my $sth = $dbh->prepare_cached($qry);
#     $sth->execute(@params);

#     my @objs;

#     while ( my $row = $sth->fetchrow_hashref() ) {
#         my $obj = MEntry->new(
#             id              => $row->{id},
#             entry_type      => $row->{entry_type},
#             bibtex_key      => $row->{bibtex_key},
#             bibtex_type     => $row->{bibtex_type},
#             bib             => $row->{bib},
#             html            => $row->{html},
#             html_bib        => $row->{html_bib},
#             abstract        => $row->{abstract},
#             title           => $row->{title},
#             hidden          => $row->{hidden},
#             year            => $row->{year},
#             month           => $row->{month},
#             sort_month      => $row->{sort_month},
#             teams_str       => $row->{teams_str},
#             people_str      => $row->{people_str},
#             tags_str        => $row->{tags_str},
#             creation_time   => $row->{creation_time},
#             modified_time   => $row->{modified_time},
#             need_html_regen => $row->{need_html_regen}
#         );
#         $obj->decodeLatex();
#         push @objs, $obj;
#     }

#     # {
#     #      no warnings 'uninitialized';
#     #     say " MEntry static_get_filter
#     #             master_id $master_id
#     #             year $year
#     #             bibtex_type $bibtex_type
#     #             entry_type $entry_type
#     #             tagid $tagid
#     #             teamid $teamid
#     #             visible $visible
#     #             permalink $permalink
#     #             hidden $hidden
#     #             num results = " . (scalar @objs) ."
#     #     ";
#     # }
#     return @objs;
# }
# ####################################################################################
# sub decodeLatex {
#     my $self = shift;
#     if ( defined $self->{title} ) {
#         $self->{title} =~ s/^\{//g;
#         $self->{title} =~ s/\}$//g;

#         # $self->{title} = decode( 'latex', $self->{title} );
#         # $self->{title} = decode( 'latex', $self->{title} );
#     }
# }
# ####################################################################################
# sub has_tag_named {
#     my $self        = shift;
#     my $dbh         = shift;
#     my $tag_to_find = shift;

#     my $mtag = MTag->static_get_by_name( $dbh, $tag_to_find );
#     return 0 if !defined $mtag;
#     return 0 if defined $mtag and $mtag->{id} < 0;

#     my $tag_id = $mtag->{id};
#     my $qry
#         = "SELECT COUNT(*) FROM Entry_to_Tag WHERE entry_id = ? AND tag_id = ?";
#     my @ary = $dbh->selectrow_array( $qry, undef, $self->{id}, $tag_id );
#     my $key_exists = $ary[0];

#     #my $sth = $dbh->prepare( $qry );
#     #$sth->execute($self->{id}, $tag_id);

#     return $key_exists == 1;

# }
# ####################################################################################
# sub tags {
#     my $self     = shift;
#     my $dbh      = shift;
#     my $tag_type = shift;    # optional

#     return () if !defined $self->{id} or $self->{id} < 0;

#     my $qry = "SELECT entry_id, tag_id 
#                 FROM Entry_to_Tag 
#                 LEFT JOIN Tag ON Tag.id = Entry_to_Tag.tag_id
#                 WHERE entry_id = ?";
#     my $sth;
#     if ( defined $tag_type ) {
#         $qry .= " AND Tag.type = ?";
#         $sth = $dbh->prepare_cached($qry);
#         $sth->execute( $self->{id}, $tag_type );
#     }
#     else {
#         $sth = $dbh->prepare_cached($qry);
#         $sth->execute( $self->{id} );
#     }


#     my @tags = ();

#     while ( my $row = $sth->fetchrow_hashref() ) {
#         my $tag_id = $row->{tag_id};
#         my $mtag = MTag->static_get( $dbh, $tag_id );
#         push @tags, $mtag if defined $mtag;
#     }
#     return @tags;
# }
# ####################################################################################
# sub add_tags {
#     my $self              = shift;
#     my $dbh               = shift;
#     my $tag_names_arr_ref = shift;
#     my $tag_type          = shift // 1;
#     my @tag_names         = @$tag_names_arr_ref;

#     my $num_added = 0;

#     return 0 if !defined $self->{id} or $self->{id} < 0;

#     # say "MEntry add_tags type $tag_type. Tags: " . join(", ", @tag_names);

#     foreach my $tn (@tag_names) {
#         my $t = MTag->static_get_by_name( $dbh, $tn );
#         if ( !defined $t ) {
#             $t = MTag->new( name => $tn, type => $tag_type );
#             $t->save($dbh);
#         }
#         $t = MTag->static_get_by_name( $dbh, $tn );
#         $num_added = $num_added + $self->assign_tag( $dbh, $t );
#     }
#     return $num_added;
# }
# ####################################################################################
# sub assign_tag {
#     my $self = shift;
#     my $dbh  = shift;
#     my $tag  = shift;

#     my $num_added = 0;

#     return 0
#         if !defined $self->{id}
#         or $self->{id} < 0
#         or !defined $tag
#         or $tag->{id} <= 0;

#     my $sth = $dbh->prepare(
#         "INSERT IGNORE INTO Entry_to_Tag( entry_id, tag_id) VALUES (?,?)");
#     $num_added = $sth->execute( $self->{id}, $tag->{id} );
#     return $num_added;
# }
# ####################################################################################
# sub remove_tag {
#     my $self = shift;
#     my $dbh  = shift;
#     my $tag  = shift;

#     return 0 if !defined $tag or !defined $self->{id} or $self->{id} < 0;

#     my $sth = $dbh->prepare(
#         "DELETE FROM Entry_to_Tag WHERE entry_id=? AND tag_id=?");

#     return $sth->execute( $self->{id}, $tag->{id} );
# }
# ####################################################################################
# sub remove_tag_by_id {
#     my $self   = shift;
#     my $dbh    = shift;
#     my $tag_id = shift;

#     return $self->remove_tag( $dbh, MTag->static_get( $dbh, $tag_id ) );
# }
# ####################################################################################
# sub remove_tag_by_name {
#     my $self     = shift;
#     my $dbh      = shift;
#     my $tag_name = shift;

#     return $self->remove_tag( $dbh,
#         MTag->static_get_by_name( $dbh, $tag_name ) );
# }
# ####################################################################################
# sub clean_ugly_bibtex_fields {
#     my $self = shift;
#     my $dbh  = shift;

#     my @arr_default
#         = qw(bdsk-url-1 bdsk-url-2 bdsk-url-3 date-added date-modified owner tags);
#     return $self->remove_bibtex_fields( $dbh, \@arr_default );
# }
# ####################################################################################
# sub remove_bibtex_fields {
#     my $self                         = shift;
#     my $dbh                          = shift;
#     my $arr_ref_bib_fields_to_delete = shift;
#     my @bib_fields_to_delete         = @$arr_ref_bib_fields_to_delete;

#     my $entry = new Text::BibTeX::Entry();
#     $entry->parse_s( $self->{bib} );
#     return -1 unless $entry->parse_ok;
#     my $key = $entry->key;

#     my $num_deleted = 0;

#     for my $field (@bib_fields_to_delete) {
#         $entry->delete($field) if defined $entry->exists($field);
#         $num_deleted++ if defined $entry->exists($field);
#     }

#     if ( $num_deleted > 0 ) {
#         my $new_bib = $entry->print_s;

# # cleaning errors caused by sqlite - mysql import # FIXME: do we still need this?
#         $new_bib =~ s/''\{(.)\}/"\{$1\}/g;
#         $new_bib =~ s/"\{(.)\}/\\"\{$1\}/g;

#         $new_bib =~ s/\\\\/\\/g;
#         $new_bib =~ s/\\\\/\\/g;

#         $self->{bib} = $new_bib;
#         $self->save($dbh);
#     }
#     return $num_deleted;
# }
# ####################################################################################

# no Moose;
# __PACKAGE__->meta->make_immutable;
# 1;
