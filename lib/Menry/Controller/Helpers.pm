package Menry::Controller::Helpers;

use Menry::Controller::Core;
use Menry::Controller::Set;
use Menry::Controller::Publications;
use Menry::Functions::BackupFunctions;
use Menry::Functions::TagObj;
use Menry::Functions::EntryObj;
use Menry::Functions::TagTypeObj;
use Menry::Schema;

use Data::Dumper;
use utf8;
use Text::BibTeX; # parsing bib files
use DateTime;
use File::Slurp;
use Time::Piece;
use 5.010; #because of ~~
use strict;
use warnings;
use List::Util qw(any);



use base 'Mojolicious::Plugin';
sub register {

	my ($self, $app) = @_;

    # TODO: Move all implementations to a separate files to avoid code redundancy! Here only function calls should be present, not theirs implementation

    $app->helper(get_rank_of_current_user => sub {
        my $self = shift;

        my $u = $app->db->resultset('Login')->search({ login => $app->session('user') })->first;
        return $u->rank;

        # my $uname = shift || $app->session('user');
        # my $user_dbh = DBI->connect('dbi:SQLite:dbname='.$app->config->{user_db}, '', '') or die $DBI::errstr;

        # my $sth = $user_dbh->prepare("SELECT rank FROM Login WHERE login=?");
        # $sth->execute($uname);
        # my $row = $sth->fetchrow_hashref();
        # my $rank = $row->{rank};

        # $rank = 0 unless defined $rank;

        # return $rank;
    });

	$app->helper(current_year => sub {
        my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        return 1900 + $year;
    });

	$app->helper(get_year_of_oldest_entry => sub {
        my $self = shift;
        my $sth = $self->app->db->prepare( "SELECT MIN(year) as min FROM Entry" ) or die $self->app->db->errstr;  
        $sth->execute(); 
        my $row = $sth->fetchrow_hashref();
        my $min = $row->{min};
        return $min; 
        
    });
    

	$app->helper(current_month => sub {
        my  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        return $mon + 1;
    });



    $app->helper(can_delete_backup => sub {
        my $self = shift;
        my $bid = shift;
        my $backup_dbh = $self->app->backup_db;

        my $b_fname = get_backup_filename($self, $bid);
        my $b_age = get_backup_age_in_days($self, $bid);

        my $file_exists = 0;
        $file_exists = 1 if -e $b_fname;


        my $age_limit = $self->config->{allow_delete_backups_older_than};

        # say "age limit is $age_limit, backup age: $b_age";

        return 1 if $file_exists == 1 and $b_age > $age_limit;
        return 1 if $file_exists == 0;
        return 0;
    });


    $app->helper(num_pubs => sub {
        my $self = shift;
        my $num = $self->app->db->resultset('Entry')->count;
        return $num; 
      });

    $app->helper(get_all_tag_types => sub {
        my $self = shift;
        return $self->app->db->resultset('TagType')->all;
      });

    $app->helper(get_tag_type_obj => sub {
        my $self = shift;
        my $type = shift || 1;

        # say "get_tag_type_obj for type $type";

        my $ttobj = TagTypeObj->getById($self->app->db, $type);
        return $ttobj;

        # return $ttobj->{name};
    });

    $app->helper(get_tags_of_type_for_paper => sub {
        my $self = shift;
        my $eid = shift;
        my $type = shift || 1;

        my $entry = $self->app->db->resultset('Entry')->search({ id => $eid})->first;

        my @tags_for_entry = $entry->tags->search({type => $type})->all;
        return @tags_for_entry;
        # my @tobjarr = TagObj->getTagsOfTypeForPaper($self->app->db, $eid, $type);
        # return @tobjarr;
    });

    $app->helper(get_unassigned_tags_of_type_for_paper => sub {
        my $self = shift;
        my $eid = shift;
        my $type = shift || 1;

        my $entry = $self->app->db->resultset('Entry')->search({ id => $eid})->first;

        my @all = $self->app->db->resultset('Tag')->search({type => $type})->all;
        my @entry_tags = $entry->tags->search({type => $type})->all;

        my @all_name = $self->app->db->resultset('Tag')->search({type => $type})->get_column('name')->all;
        my @entry_tags_name = $entry->tags->search({type => $type})->get_column('name')->all;

        my @unassigned_tags;
        for my $t (@all){
            my $name = $t->name;
            if (grep( /^$name$/, @entry_tags_name) == 0){
                say "helper get_unassigned_tags_of_type_for_paper: marking ".$t->name." as unassigned. ";
                push @unassigned_tags, $t;
            }
        }
        return @unassigned_tags;
    });

    

    

    $app->helper(num_authors => sub {
        my $self = shift;

        my $num = $self->app->db->resultset('Author')->search(
          {}, 
          {columns => [{ 'd_master_id' => { distinct => 'me.master_id' } }],}
        )->count;

        return $num; 
      });

    $app->helper(num_visible_authors => sub {
        my $self = shift;

        my $num = $self->app->db->resultset('Author')->search(
          {'display' => 1}, 
          {columns => [{ 'd_master_id' => { distinct => 'me.master_id' } }],}
        )->count;
        return $num; 
      });

    $app->helper(get_num_members_for_team => sub {
        my $self = shift;
        my $teamid = shift;

        return $self->app->db->resultset('AuthorToTeam')->search({team_id => $teamid})->count;

    });

    $app->helper(team_can_be_deleted => sub {
        my $self = shift;
        my $id = shift;

        my ($author_ids_ref, $start_arr_ref, $stop_arr_ref) = get_team_members($self, $id);
        my $num_authors = scalar @$author_ids_ref;
        return 0 if $num_authors > 0;

        return 1;
    });

    $app->helper(get_num_teams => sub {
        my $self = shift;
        my ($teams_arr_ref, $team_ids_arr_ref) = get_all_teams($self->app->db);
        return scalar @$team_ids_arr_ref;
    });

    $app->helper(get_teams_id_arr => sub {
        my $self = shift;
        my ($teams_arr_ref, $team_ids_arr_ref) = get_all_teams($self->app->db);
        return @$team_ids_arr_ref;
    });

    $app->helper(get_team_name => sub {
        my $self = shift;
        my $id = shift;
        return $self->app->db->resultset('Team')->search({id => $id})->get_column('name')->first;
    });

    $app->helper(get_tag_name => sub {
        my $self = shift;
        my $id = shift;
        return get_tag_name_for_id($self->app->db, $id);
    });

    $app->helper(author_is_visible => sub {
        my $self = shift;
        my $id = shift;

        return get_visibility_for_id($self, $id);
      });


    $app->helper(author_can_be_deleted => sub {
        my $self = shift;
        my $id = shift;

        my $visibility = get_visibility_for_id($self, $id);
        return 0 if $visibility == 1;

        my ($teams_arr, $start_arr, $stop_arr, $team_id_arr) = get_teams_of_author($self, $id);
        my $num_teams = scalar @$teams_arr;


        return 1 if $num_teams == 0 and $visibility == 0;
        return 0;
      });

    $app->helper(num_tags => sub {
        my $self = shift;
        my $type = shift || 1;

        return $self->app->db->resultset('Tag')->search({ type => $type })->count;
      });

    $app->helper(num_pubs_for_year => sub {
        my $self = shift;
        my $year = shift;

        my $num = $self->app->db->resultset('Entry')->search({ year => $year })->count;
        return $num; 
      });

    $app->helper(get_bibtex_types_aggregated_for_type => sub {
        my $self = shift;
        my $type = shift;
        
        return get_bibtex_types_for_our_type($self->app->db, $type);
    });

    $app->helper(helper_get_description_for_our_type => sub {
        my $self = shift;
        my $type = shift;

        
        return get_description_for_our_type($self->app->db, $type);
    });

    $app->helper(helper_get_landing_for_our_type => sub {
        my $self = shift;
        my $type = shift;
        return get_landing_for_our_type($self->app->db, $type);
    });

    
    # $app->helper(helper_get_entry_title => sub {
    #     my $self = shift;
    #     my $eid = shift;

    #     return get_entry_title($self->app->db, $eid);
    #   });

    

    $app->helper(num_bibtex_types_aggregated_for_type => sub {
        my $self = shift;
        my $type = shift;
        return scalar $self->get_bibtex_types_aggregated_for_type($type);
      });

    $app->helper(num_pubs_for_author_and_tag => sub {
        my $self = shift;
        my $mid = shift;
        my $tag_id = shift;

        say "call HELPER num_pubs_for_author_and_tag";

        my @objs = get_publications_main_hashed_args($self, {hidden => undef, author => $mid, tag=>$tag_id});
        my $count =  scalar @objs;

        return $count;

        # my $set = get_set_of_papers_for_author_and_tag($self, $mid, $tag_id);
        # return scalar $set->members;
      });

    $app->helper(num_pubs_for_author_and_team => sub {
        my $self = shift;
        my $mid = shift;
        my $team_id = shift;

        say "call HELPER num_pubs_for_author_and_team";

        my $set = get_set_of_papers_for_author_and_team($self, $mid, $team_id);
        return scalar $set->members;
      });



    $app->helper(get_years_arr => sub {
        my $self = shift;

        my @arr = $self->app->db->resultset('Entry')->search(
            { 
                'hidden' => 0,
                'display' => 1
            },
            { 
                join => {'entry_to_authors' => 'author'}, 
                columns => [{ 'd_year' => { distinct => 'me.year' } }],
                order_by => { '-desc' => ['year'] },
            }
            )->get_column('d_year')->all;

        return @arr; 
      });

    $app->helper(num_pubs_for_author => sub {
        my $self = shift;
        my $mid = shift;

        my $num = $self->app->db->resultset('EntryToAuthor')->search({ author_id => $mid })->count;
        return $num; 
      });

    $app->helper(get_authors_of_entry => sub {
        my $self = shift;
        my $eid = shift;

        my @aids = $self->app->db->resultset('EntryToAuthor')->search({ entry_id => $eid })->get_column('author_id')->all;
        return @aids; 
      });

    $app->helper(num_unhidden_pubs_for_tag => sub {
        my $self = shift;
        my $tid = shift;

        my $sth = $self->app->db->prepare( "SELECT COUNT(Entry_to_Tag.entry_id) as num FROM Entry_to_Tag LEFT JOIN Entry ON Entry.id = Entry_to_Tag.entry_id WHERE tag_id=? AND hidden=0" );  
        $sth->execute($tid); 
        my $row = $sth->fetchrow_hashref();
        my $num = $row->{num};
        return $num; 
      });


    $app->helper(num_pubs_for_tag => sub {
        my $self = shift;
        my $tid = shift;

        my $num = $self->app->db->resultset('Tag')->search({ id => $tid })->first->entries->count;

        # my $sth = $self->app->db->prepare( "SELECT COUNT(Entry_to_Tag.entry_id) as num FROM Entry_to_Tag LEFT JOIN Entry ON Entry.id = Entry_to_Tag.entry_id WHERE tag_id=?" );  
        # $sth->execute($tid); 
        # my $row = $sth->fetchrow_hashref();
        # my $num = $row->{num};
        return $num; 
      });

    $app->helper(get_author_mids_arr => sub {
        my $self = shift;

        my @rs = $self->app->db->resultset('Author')->search(
          {'display' => 1}, 
          {
            columns => [{ 'distinct_master_id' => { distinct => 'me.master_id' }}, 'id', 'master', 'display'],
            order_by => { '-asc' => ['master'] },
            }
        )->get_column('id')->all;


        # SELECT DISTINCT( me.master_id ), me.master, me.display 
        # FROM Author me 
        # WHERE ( display = ? ) ORDER BY master ASC: '1'
        my @arr = @rs;#->get_column('id');



        # WAS: SELECT DISTINCT master_id, master FROM Author WHERE display = 1 ORDER BY master ASC

            
        return @arr; 
      });

    $app->helper(get_master_for_id => sub {
        my $self = shift;
        my $aid = shift;

        my $row = $self->app->db->resultset('Author')->search({ id => $aid })->first;
        return $row->master if defined $row;
        return "undef";

      });

    $app->helper(get_first_letters => sub {
           my $self = shift;
           my $dbh = $self->app->db;

           my $sth = $dbh->prepare( "SELECT DISTINCT substr(master, 0, 2) as let FROM Author
                 WHERE display=1
                 ORDER BY let ASC" ); 
           $sth->execute(); 
           my @letters;
           while(my $row = $sth->fetchrow_hashref()) {
              my $letter = $row->{let} || "*";
              push @letters, uc($letter);
           }
           # @letters = uniq(@letters);
           return sort(@letters);
    });

    $app->helper(bibtex_help => sub {
        my $hlp = '
            <strong>Remember!</strong><br><br>
            <i class="fa fa-asterisk"></i> DE <i class="fa fa-asterisk"></i><br>
            &auml; <i class="fa fa-hand-o-right"></i> \"{a} <br>
            &uuml; <i class="fa fa-hand-o-right"></i> \"{u} <br>
            &ouml; <i class="fa fa-hand-o-right"></i> \"{o} <br>
            &szlig; <i class="fa fa-hand-o-right"></i> \ss <br>
            <br>
            <i class="fa fa-asterisk"></i> PL <i class="fa fa-asterisk"></i><br>
            &oacute; <i class="fa fa-hand-o-right"></i> \\\'{o} <br>
            &#347; <i class="fa fa-hand-o-right"></i> \\\'{s} <br>
            &#322; <i class="fa fa-hand-o-right"></i> {\l} <br>
            &#261; <i class="fa fa-hand-o-right"></i> \k{a} <br>
            <br>
            <i class="fa fa-asterisk"></i>
            Help
            <i class="fa fa-asterisk"></i>
            <br>
            <a href="http://www.bibtex.org/SpecialSymbols/">Help 1 <i class="fa fa-external-link"></i></a> <br>
            <a href="http://leptokurtosis.com/main/node/42">Help 2 <i class="fa fa-external-link"></i></a> <br>
        ';  
        return $hlp; 
    });

    $app->helper(single_publication_row => sub {
        my ($self, $obj, $burl, $j) = @_;
        # my $obj = shift;
        # my $burl = shift;
        # my $j = shift;

        my $t1 = "btn-success";
        my $t2 = "btn-default";  
        my $extra_msg = "";
        if ($obj->isTalk()) {
            $t1 = "btn-default";
            $t2 = "btn-success";
            if($obj->{bibtex_type} ne 'misc') {
                $t2="btn-danger";
                $extra_msg = ". Talks should have bibtex_type set to 'misc''"; 
            }
        }
        return $obj->isTalk();
        
        

        my $hlp = `
            <td style="width: 120px;">
                    <div class="btn-group">
                        <a class="btn btn-warning" href="/publications/manage_tags/<%= $obj->{id} %><%=$burl%>"><span class="glyphicon glyphicon-tags"></span> T</a>
                        <button type="button" class="btn btn-info dropdown-toggle" data-toggle="dropdown">
                        <span class="glyphicon glyphicon-pencil"></span>
                        <span class="caret"></span>
                        </button>
                        <ul class="dropdown-menu" role="menu">
                            <li><a href="/publications/edit/<%=$obj->{id}%><%=$burl%>"><span class="glyphicon glyphicon-pencil" style="color: #5CB85C;"></span> Edit BibTeX</a></li>
                            <li><a href="#modal-dialog-<%=$obj->{id}%>" data-toggle="modal"><span class="glyphicon glyphicon-trash"></span> Delete...</a></li>
                            <li><a href="/publications/show_authors/<%=$obj->{id}%><%=$burl%>"><span class="glyphicon glyphicon-user"></span> Show authors</a></li>
                            <li><a href="/publications/regenerate/<%=$obj->{id}%><%=$burl%>"><span class="glyphicon glyphicon-refresh" style="color: #5CB85C;"></span> Regenerate HTML</a></li>
                            <li><a href="/publications/add_pdf/<%=$obj->{id}%><%=$burl%>"><i class="fa fa-upload"></i><i class="fa fa-file-pdf-o"></i><i class="fa fa-file-powerpoint-o"></i> Upload pdf/slides</a></li>
                            <li><a href="/publications/manage_tags/<%=$obj->{id}%><%=$burl%>"><span class="glyphicon glyphicon-tags"></span> Manage tags</a></li>
                            <li><a href="/publications/manage_exceptions/<%=$obj->{id}%><%=$burl%>"><i class="fa fa-exclamation "></i> Manage exceptions</a></li>
                        </ul>
                    </div>


                    <!-- MODAL DIALOG FOR DELETE -->
                    <div id="modal-dialog-<%=$obj->{id}%>" class="modal">
                        <div class="modal-dialog">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <a href="#" data-dismiss="modal" aria-hidden="true" class="close">×</a>
                                    <h3>Are you sure?</h3>
                                    <p>Are you sure you want to delete item <span class="btn btn-default btn-sm"><%= $j %></span> key <span class="badge"><%=$obj->{key} %></span> ?</p>
                                </div>
                                <div class="modal-body">
                                    %== $obj->{html}
                                    <div class="modal-footer">
                                        <a href="/publications/delete_sure/<%=$obj->{id}%><%=$burl%>" class="btn btn-danger"> Yes, delete it <span class="glyphicon glyphicon-trash"></span></a>
                                        <a href="#" data-dismiss="modal" aria-hidden="true" class="btn btn-success">No, I want to keep it <span class="glyphicon glyphicon-heart"></span> </button></a>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                  <!-- END OF MODAL DIALOG FOR DELETE -->
                </td>

                <!-- TALK/PAPER switch -->
                <td style="width: 120px;">
                    <div class="btn-group">

                        <a class="btn <%=$t1%> btn-sm" href="/publications/make_paper/<%= $obj->{id} %><%=$burl%>" data-toggle="tooltip" data-placement="top" title="Click to set entry type to PAPER" data-container="body">
                                <span class="glyphicon glyphicon-file"></span>
                            </span>
                        </a>
                        <a href="/publications/make_talk/<%= $obj->{id} %><%=$burl%>" class="btn <%=$t2%> btn-sm" data-toggle="tooltip" data-placement="top" title="Click to set entry type to TALK<%=$extra_msg%>" data-container="body">
                                <span class="glyphicon glyphicon-volume-up"></span>
                            </span>
                        </a>
                    </div>
                </td>
                <!-- ID switch -->
                <td>
                  <button class="btn btn-default btn-sm" tooltip="Entry ID"> <span class="glyphicon glyphicon-barcode"></span> <%= $obj->{id} %></button>
                </td>
                <td>
                    <span class="btn btn-default btn-sm" data-toggle="tooltip" data-placement="top" title="Created: <%=$obj->{ctime}%>, Modified: <%=$obj->{mtime}%>">
                        <span class="glyphicon glyphicon-calendar"></span>
                    </span>
                </td>
                <td>
                  <p class="btn btn-default btn-sm"><%= $j %></p>
                </td>
                
                <td class="bibtexitem">
                  %== $obj->{html}
                </td>
        `;  
        return $hlp; 
    });


}


1;
