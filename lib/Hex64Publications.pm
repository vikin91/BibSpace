package Hex64Publications;

use Hex64Publications::Controller::DB;
use Hex64Publications::Controller::Core;
use Hex64Publications::Controller::Search;
use Hex64Publications::Controller::BackupFunctions;
use Hex64Publications::Controller::Publications;
use Hex64Publications::Controller::Helpers;
use Hex64Publications::Functions::MyUsers;

use Mojo::Base 'Mojolicious';
use Mojo::Base 'Mojolicious::Plugin::Config';


use Net::Address::IP::Local;
use Time::Piece;
use Data::Dumper;
use File::Slurp;
use POSIX qw/strftime/;
use Try::Tiny;

# 0 4,12,20 * * * curl http://localhost:8081/cron/day
# 0 2 * * * curl http://localhost:8081/cron/night
# 5 2 * * 0 curl http://localhost:8081/cron/week
# 10 2 1 * * curl http://localhost:8081/cron/month


has db_connect_string => sub {
    my $self = shift;
    
    return 'dbi:SQLite:dbname='.$self->config->{normal_db};
    
};

has db => sub {
    my $self = shift;
    # DBI->connect($self->app->db_connect_string, '', '') or die $DBI::errstr .". File is: ".$self->config->{normal_db};

    my $db_host = $self->config->{db_host};
    my $db_user = $self->config->{db_user};
    my $db_database = $self->config->{db_database};
    my $db_pass = $self->config->{db_pass};


    my $dbh = DBI->connect("DBI:mysql:database=$db_database;host=$db_host",
                         "$db_user", "$db_pass",
                         {'RaiseError' => 1});
    $dbh->{mysql_auto_reconnect} = 1;
    return $dbh;
};

has backup_db => sub {
    my $self = shift;
    say "call: app->backup_db. DEPRECATED!!";
    return $self->app->db;

    # DBI->connect('dbi:SQLite:dbname='.$self->config->{backup_db}, '', '') or die $DBI::errstr;
};


sub startup {
    my $self = shift;
    $self->app->plugin('InstallablePaths');
    $self->app->plugin('RenderFile');
    my $address = Net::Address::IP::Local->public;
    # print $address;

    # my $config = $self->plugin('Config');
    my $config = $self->app->config;
    my $mode = $self->app->mode;

    $self->hook(before_dispatch => sub {
      my $c = shift;
      $c->req->url->base->scheme('https') if $c->req->headers->header('X-Forwarded-HTTPS');

      # TODO!!
      # only for directory deployment!!
      # push @{$c->req->url->base->path->trailing_slash(1)}, shift @{$c->req->url->path->leading_slash(0)};
    });

    

    say "Starting app in mode: $mode";    

    # load default
    $config = $self->plugin('Config' => {file => 'config/default.conf'});

    if($mode eq "demo"){
        $config = $self->plugin('Config' => {file => 'config/demo.conf'});
    }
    elsif($mode eq "test-server"){
        $config = $self->plugin('Config' => {file => 'config/test-server.conf'});    
    }
    elsif($mode eq "testing"){
        $config = $self->plugin('Config' => {file => 'config/testing.conf'});    
    }
    elsif($mode eq "production"){
        $config = $self->plugin('Config' => {file => 'config/production.conf'});
    }
    elsif($mode eq "development"){
        $config = $self->plugin('Config' => {file => 'config/development.conf'});
    }
    else{   # DEFAULT
        $config = $self->plugin('Config' => {file => 'config/default.conf'});
    }

    $self->create_main_db($self->app->db);
    create_backup_table($self->app->db);


    $self->plugin('Hex64Publications::Controller::Helpers');
    $self->plugin('Hex64Publications::Controller::CronHelpers');

    $self->secrets( [$config->{key_cookie}] );

    $self->helper(users => sub { state $users = Hex64Publications::Functions::MyUsers->new });
    $self->helper(proxy_prefix => sub { $config->{proxy_prefix} });

    $self->helper(version => sub {

        my $version = "uknown";
        my $cmd_out = 0;
        try{
            $cmd_out=`bash git-getrevision.sh`;
        }
        catch{
            warn "Exception by cacluating version $_ Ignoring";
        };
        
        try{
            $version = read_file('version');
            $version .="/".$cmd_out;
        }
        catch{
            warn "Exception by reading version $_ . Ignoring";
        };
        $version;
    });

    $self->helper(backurl => sub {
        my $s = shift; 
        my $short_url = $s->backurl_short;
        my $burl = "?back_url=".$short_url;
        $burl =~ s/&/%26/g;
        $burl;
    });

    $self->helper(get_referrer => sub {
        my $s = shift; 
        my $ref = $s->req->headers->referrer;
        $ref = $s->url_for('/') if $ref eq '';
        return $ref;
    });


    $self->helper(backurl_short => sub {
        my $s = shift;         
        # say "url: ".$s->req->url;
        # say "path: ".$s->req->url->path;
        # say "base: ".$s->req->url->base;
        # say "url_with: ".$s->url_with;
        return $s->url_with;
    });

    $self->helper(is_manager => sub {
        my $self = shift; 
        my $usr = $self->session('user');
        my $rank = $self->users->get_rank($usr, $self->app->db) || 0;
        return 1 if $rank > 0;
        return undef;
    });

    $self->helper(is_admin => sub {
        my $self = shift; 
        my $usr = $self->session('user');
        my $rank = $self->users->get_rank($usr, $self->app->db) || 0;
        return 1 if $rank > 1;
        return undef;
    });


    # $self->helper(log => sub {
    #     Mojo::Log->new( path => $config->{log_file}, level => 'debug' );
    # });

    $self->helper(write_log => sub {        
        my $c = shift;
        my $msg = shift;
        my $usr = $c->session('user') || "not_logged_in";
        my $usr_str = "(".$usr."): ";

        my $datetime_string = strftime('%Y-%m-%d %H:%M:%S',localtime);

        my $filename = $config->{log_file};
        my $msg_to_log = "[".$datetime_string."] ".$usr_str.$msg."\n";

        try{
            if(open(my $fh, '>>', $filename)){
                print $fh $msg_to_log;
                close $fh;
            }    
        }
        catch{
            say "Opening log failed! Msg was: ".$msg_to_log;
            say "Trying to create directory";
            try{
                mkdir "log";
                if(open(my $fh, '>>', $filename)){
                    print $fh $msg_to_log;
                    close $fh;
                }
            }
            catch{
                say "Creating dir and ppening log failed again! Ingoring.";
            }    
        };
    });

    # $self->app->db->do("PRAGMA foreign_keys = ON");
    # $self->app->db->do("PRAGMA cache_size = 100000"); # sets cache to 100MB


    # my $r0 = $self->routes;
    my $pa = $self->routes;#->under('/pa');

    my $anyone = $self->routes;
    $anyone->get('/pa')->to('display#index')->name('startpa');           #### THIS DEPENDS ON APACHE PROXY CONFIGURATION! SHAME, I KNOW.
    $anyone->get('/')->to('display#index')->name('start');
    $anyone->get('/start')->to('display#index');

    $anyone->get('/test')->to('display#test');


    $anyone->get('/forgot')->to('login#forgot');
    $anyone->post('/forgot/gen')->to('login#post_gen_forgot_token');
    $anyone->get('/forgot/reset/:token')->to('login#token_clicked')->name("token_clicked");
    $anyone->post('/forgot/store')->to('login#store_password');
    

    $anyone->get('/login_form')->to('login#login_form')->name('login_form');
    $anyone->post('/do_login')->to('login#login')->name('do_login');
    $anyone->get('/youneedtologin')->to('login#not_logged_in')->name('youneedtologin');
    $anyone->get('/badpassword')->to('login#bad_password')->name('badpassword');

    $anyone->get('/logout')->to('login#logout')->name('logout');

    $anyone->any('/test/500')->to('display#test500');
    $anyone->any('/test/404')->to('display#test404');

    $anyone->get('/register')->to('login#register')->name('register');
    $anyone->get('/register_dummy')->to('login#dummy')->name('dummy');
    $anyone->post('/register')->to('login#post_do_register')->name('post_do_register');
    $anyone->any('/noregister')->to('login#register_disabled');

  
    my $logged_user = $anyone->under->to('login#check_is_logged_in');
    my $manager = $logged_user->under->to('login#under_check_is_manager');
    my $superadmin = $logged_user->under->to('login#under_check_is_admin');


    

    ################ SETTINGS ################
    $logged_user->get('/profile')->to('login#profile');
    $superadmin->get('/manage_users')->to('login#manage_users')->name('manage_users');
    $superadmin->get('/profile/:id')->to('login#foreign_profile');
    $superadmin->get('/profile/delete/:id')->to('login#delete_user');

    $superadmin->get('/profile/make_user/:id')->to('login#make_user');
    $superadmin->get('/profile/make_manager/:id')->to('login#make_manager');
    $superadmin->get('/profile/make_admin/:id')->to('login#make_admin');
    
    $manager->get('/log')->to('display#show_log');
    $superadmin->get('/settings/fix_entry_types')->to('publications#fixEntryType');
    $superadmin->get('/settings/fix_months')->to('publications#fixMonths');
    
    
    $manager->get('/settings/clean_all')->to('publications#clean_ugly_bibtex');
    $manager->get('/settings/regenerate_all_force')->to('publications#regenerate_html_for_all_force');
    $logged_user->get('/settings/regenerate_all')->to('publications#regenerate_html_for_all');
    
    $anyone->get('/backup/do')->to('backup#save');
    $logged_user->get('/backup')->to('backup#index');
    $logged_user->get('/backup/download/:file')->to('backup#backup_download');    
    $superadmin->get('/restore/delete/:id')->to('backup#delete_backup');
    $manager->get('/restore/do/:id')->to('backup#restore_backup');
    $manager->get('/backup/cleanup')->to('backup#cleanup');


    ################ TYPES ################    
    $logged_user->get('/types')->to('types#all_our');
    $logged_user->get('/types/add')->to('types#add_type');
    $logged_user->post('/types/add')->to('types#post_add_type');
    $logged_user->get('/types/manage/:type')->to('types#manage');
    $logged_user->get('/types/delete/:type_to_delete')->to('types#delete_type');

    $logged_user->post('/types/store_description')->to('types#post_store_description');
    $logged_user->get('/types/toggle/:type')->to('types#toggle_landing');
    
    $logged_user->get('/types/:our_type/map/:bibtex_type')->to('types#map_types');
    $logged_user->get('/types/:our_type/unmap/:bibtex_type')->to('types#unmap_types');

    ################ AUTHORS ################

    $logged_user->get('/authors/')->to('authors#show');
    $logged_user->get('/authors/add')->to('authors#add_author');
    $logged_user->post('/authors/add/')->to('authors#add_post');

    $logged_user->get('/authors/edit/:id')->to('authors#edit_author');
    $logged_user->post('/authors/edit/')->to('authors#edit_post');
    $logged_user->get('/authors/delete/:id')->to('authors#delete_author');
    $logged_user->get('/authors/delete/:id/force')->to('authors#delete_author_force');
    $logged_user->post('/authors/edit_membership_dates')->to('authors#post_edit_membership_dates');

    $logged_user->get('/authors/:id/add_to_team/:tid')->to('authors#add_to_team');
    $logged_user->get('/authors/:id/remove_from_team/:tid')->to('authors#remove_from_team');
    $logged_user->get('/authors/:id/remove_uid/:uid')->to('authors#remove_uid');

    $logged_user->get('/authors/reassign')->to('authors#reassign_authors_to_entries');
    $logged_user->get('/authors/reassign_and_create')->to('authors#reassign_authors_to_entries_and_create_authors');
    
    $logged_user->get('/authors/visible')->to('authors#show_visible');
    $logged_user->get('/authors/toggle_visibility/:id')->to('authors#toggle_visibility');  

    ################ SEARCH ################
    $anyone->get('/search/:type/:q')->to('search#search');

    ################ TAG TYPES ################
    # $logged_user->get('/tags/')->to('tags#index')->name("tags_index");
    $logged_user->get('/tagtypes')->to('tagtypes#index');
    $logged_user->get('/tagtypes/add')->to('tagtypes#add');
    $logged_user->post('/tagtypes/add')->to('tagtypes#add_post');
    $logged_user->get('/tagtypes/delete/:id')->to('tagtypes#delete');
    $logged_user->any('/tagtypes/edit/:id')->to('tagtypes#edit');

    ################ TAGS ################
    $logged_user->get('/tags/:type')->to('tags#index', type => 1);
    $logged_user->get('/tags/add/:type')->to('tags#add', type => 1);
    $logged_user->post('/tags/add/:type')->to('tags#add_post', type => 1);
    $logged_user->get('/tags/authors/:tid/:type')->to('tags#get_authors_for_tag', type => 1);
    $logged_user->any('/tags/add_and_assign/:eid')->to('tags#add_and_assign');
    $logged_user->get('/tags/delete/:id_to_delete')->to('tags#delete');
    $logged_user->get('/tags/edit/:id')->to('tags#edit');

    

    ################ TEAMS ################
    $logged_user->get('/teams')->to('teams#show');
    $logged_user->get('/teams/members/:teamid')->to('teams#team_members');

    $logged_user->get('/teams/edit/:teamid')->to('teams#edit');
    $logged_user->get('/teams/delete/:id_to_delete')->to('teams#delete_team');
    $logged_user->get('/teams/delete/:id_to_delete/force')->to('teams#delete_team_force');
    $logged_user->get('/teams/unrealted_papers/:teamid')->to('publications#show_unrelated_to_team');

    $logged_user->get('/teams/add')->to('teams#add_team');
    $logged_user->post('/teams/add/')->to('teams#add_team_post');

    ################ EDITING PUBLICATIONS ################

    # EXPERIMENTAL
    $logged_user->get('/publications-set')->to('publications#all_defined_by_set'); 
    # description of this function is included with the code
    # $anyone->get('/publications/special/:id')->to('publications#special_map_pdf_to_local_file'); # use with extreeme caution!
    $superadmin->get('/publications/fix_urls')->to('publications#replace_urls_to_file_serving_function');
    # EXPERIMENTAL END

    $logged_user->get('/publications')->to('publications#all'); # logged_user icons!
    $logged_user->get('/publications/recently_added/:num')->to('publications#all_recently_added'); # logged_user icons!
    $logged_user->get('/publications/recently_modified/:num')->to('publications#all_recently_modified'); 
    $logged_user->get('/publications/orphaned')->to('publications#all_without_author'); 
    $logged_user->get('/publications/untagged/:tagtype')->to('publications#all_without_tag', tagtype => 1);
    $logged_user->get('/publications/untagged/:author/:tagtype')->to('publications#all_without_tag_for_author', tagtype => 1);
    
    $logged_user->get('/publications/candidates_to_delete')->to('publications#all_candidates_to_delete');
    $logged_user->get('/publications/missing_month')->to('publications#all_without_missing_month');
    
    $logged_user->get('/publications/sdqpdf')->to('publications#all_with_pdf_on_sdq'); 
    $logged_user->get('/publications/get/:id')->to('publications#single'); 
    $logged_user->get('/publications/download/:filetype/:id')->to('publications#download')->name('download_publication'); 

    $logged_user->get('/publications/hide/:id')->to('publications#hide'); 
    $logged_user->get('/publications/unhide/:id')->to('publications#unhide'); 
    $logged_user->get('/publications/toggle_hide/:id')->to('publications#toggle_hide'); 
    
    # $anyone->get('/publications/get/:id')->to('publications#single_read'); 
    

    $logged_user->get('/publications/add')->to('publications#get_add');
    $logged_user->get('/publications/add_many')->to('publications#get_add_many');
    $logged_user->post('/publications/add_many/store')->to('publications#post_add_many_store');
    $logged_user->post('/publications/add/store')->to('publications#post_add_store');

    # $logged_user->post('/publications/store/:id')->to('publications#post_store');

    $logged_user->get('/publications/make_paper/:id')->to('publications#make_paper');
    $logged_user->get('/publications/make_talk/:id')->to('publications#make_talk');

    $logged_user->get('/publications/edit/:id')->to('publications#get_edit');
    $logged_user->post('/publications/edit/store/:id')->to('publications#post_edit_store');
    $logged_user->get('/publications/edit/store/:id')->to('publications#get_edit');

    $logged_user->get('/publications/regenerate/:id')->to('publications#regenerate_html');
    $logged_user->get('/publications/delete/:id')->to('publications#delete');
    $logged_user->get('/publications/delete_sure/:id')->to('publications#delete_sure');

    $logged_user->get('/publications/add_pdf/:id')->to('publications#add_pdf');
    $logged_user->post('/publications/add_pdf/do/:id')->to('publications#add_pdf_post');
    

    $logged_user->get('/publications/manage_tags/:id')->to('publications#manage_tags');
    $logged_user->get('/publications/:eid/remove_tag/:tid')->to('publications#remove_tag');
    $logged_user->get('/publications/:eid/add_tag/:tid')->to('publications#add_tag');

    $logged_user->get('/publications/manage_exceptions/:id')->to('publications#manage_exceptions');
    $logged_user->get('/publications/:eid/remove_exception/:tid')->to('publications#remove_exception');
    $logged_user->get('/publications/:eid/add_exception/:tid')->to('publications#add_exception');

    $logged_user->get('/publications/show_authors/:id')->to('publications#show_authors_of_entry');

    
    

    # $logged_user->get('/publications/decimate')->to('publications#decimate');
    


    ################ TYPES ################





    ################ OPEN ACCESS ################

    # contains meta info for every paper. Optimization for google scholar
    $anyone->get('/read/publications/meta/')->to('publications#metalist');
    $anyone->get('/read/publications/meta/:id')->to('publications#meta');

    $anyone->get('/read/publications')->to('publications#all_read');
    $anyone->get('/r/publications')->to('publications#all_read'); #ALIAS
    $anyone->get('/r/p')->to('publications#all_read'); #ALIAS

    $anyone->get('/read/bibtex')->to('publications#all_bibtex');
    $anyone->get('/r/bibtex')->to('publications#all_bibtex'); #ALIAS
    $anyone->get('/r/b')->to('publications#all_bibtex'); #ALIAS

    # TODO: document this
    $anyone->get('/read/publications/get/:id')->to('publications#single_read');
    $anyone->get('/r/p/get/:id')->to('publications#single_read'); #ALIAS

    #OLD #$anyone->get('/landing/publications')->to('publications#landing');
    #OLD #$anyone->get('/l/p')->to('publications#landing'); #ALIAS
    #OLD #$anyone->get('/landing-years/publications')->to('publications#landing_years');
    #OLD #$anyone->get('/ly/p')->to('publications#landing_years'); #ALIAS

    
    $anyone->get('/landing/publications')->to('publications#landing_types_obj');
    $anyone->get('/l/p')->to('publications#landing_types_obj'); #ALIAS

    $anyone->get('/landing-years/publications')->to('publications#landing_years_obj');
    $anyone->get('/ly/p')->to('publications#landing_years_obj'); #ALIAS
    

    $anyone->get('/read/authors-for-tag/:tid/:team')->to('tags#get_authors_for_tag_read');
    $anyone->get('/r/a4t/:tid/:team')->to('tags#get_authors_for_tag_read'); #ALIAS

    $anyone->get('/read/tags-for-author/:aid')->to('tags#get_tags_for_author_read');
    $anyone->get('/r/t4a/:aid')->to('tags#get_tags_for_author_read'); #ALIAS

    $anyone->get('/read/tags-for-team/:tid')->to('tags#get_tags_for_team_read');
    $anyone->get('/r/t4t/:tid')->to('tags#get_tags_for_team_read'); #ALIAS



    ################ CRON ################

    # $anyone->get('/settings/regenerate')->to('publications#regenerate_html_for_all');
    # $anyone->get('/settings/clean_ugly')->to('publications#clean_ugly_bibtex');
    # $anyone->get('/backup/do_backup')->to('backup#save');
    # $anyone->get('/settings/reassign_papers')->to('authors#reassign_authors_to_entries');

    $anyone->get('/cron')->to('cron#index');
    $anyone->get('/cron/day')->to('cron#cron_day');
    $anyone->get('/cron/night')->to('cron#cron_night');
    $anyone->get('/cron/week')->to('cron#cron_week');
    $anyone->get('/cron/month')->to('cron#cron_month');


    ################ Water Sensor ################
    # $anyone->post('/private/add')->to('display#private');
    # $anyone->post('/pa/private/add')->to('display#private');
    # $anyone->get('/private/NOW/:now/TT/:tt/TTU/:ttu/TTI/:tti/WA/:wa/WAU/:wau/WAI/:wai/TI/:ti/TIU/:tiu/TII/:tii/LW/:lw')->to('display#private');
    # $anyone->get('/pa/private/NOW/:now/TT/:tt/TTU/:ttu/TTI/:tti/WA/:wa/WAU/:wau/WAI/:wai/TI/:ti/TIU/:tiu/TII/:tii/LW/:lw')->to('display#private');
    # $anyone->get('/private/:num')->to('display#private_read');
    # $anyone->get('/pa/private/:num')->to('display#private_read');
    # $anyone->get('/private/alm/:num')->to('display#private_read_alm');
    # $anyone->get('/pa/private/alm/:num')->to('display#private_read_alm');
        

}



1;