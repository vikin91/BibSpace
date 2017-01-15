package BibSpace v0.4.7;

# ABSTRACT: BibSpace is a system to manage Bibtex references for authors and research groups web page.

use BibSpace::Controller::Core;
use BibSpace::Controller::BackupFunctions;
use BibSpace::Controller::Publications;
use BibSpace::Controller::PublicationsLanding;
use BibSpace::Controller::PublicationsExperimental;
use BibSpace::Controller::PublicationsSEO;
use BibSpace::Controller::Helpers;

use BibSpace::Model::M::MUser;


use BibSpace::Model::M::CMUsers;
use BibSpace::Model::M::CMObjectStore;
use BibSpace::Model::M::StorageBase;

use BibSpace::Functions::FDB;
use BibSpace::Functions::FPublications;

use Mojo::Base 'Mojolicious';
use Mojo::Base 'Mojolicious::Plugin::Config';

use Time::Piece;
use Data::Dumper;
use File::Slurp;
use POSIX qw/strftime/;
use Try::Tiny;
use Path::Tiny;    # for creating directories
use Mojo::Home;
use File::Spec;
use Cwd;

use Redis;

# for Makemake. Needs to be removed for Dist::Zilla
# our $VERSION = '0.4.4';

# 0 4,12,20 * * * curl http://localhost:8081/cron/day
# 0 2 * * * curl http://localhost:8081/cron/night
# 5 2 * * 0 curl http://localhost:8081/cron/week
# 10 2 1 * * curl http://localhost:8081/cron/month

# this is deprecated and should not be used
our $bibtex2html_tmp_dir = "./tmp";

has is_demo => sub {
    return 1 if shift->config->{demo_mode};
    return 0;
};


has config_file => sub {
    my $self = shift;
    return $ENV{BIBSPACE_CONFIG} if $ENV{BIBSPACE_CONFIG};
    return $self->app->home->rel_file('/etc/bibspace.conf')
        if -e $self->app->home->rel_file('/etc/bibspace.conf');
    return $self->app->home->rel_file(
        'lib/BibSpace/files/config/default.conf')
        if -e $self->app->home->rel_file(
        'lib/BibSpace/files/config/default.conf');
    return $self->app->home->rel_file('config/default.conf')    # for travis
        if -e $self->app->home->rel_file('config/default.conf');
};

has db => sub {
    my $self = shift;
    return db_connect(
        $self->config->{db_host},     $self->config->{db_user},
        $self->config->{db_database}, $self->config->{db_pass}
    );
};

# TODO: turn into helper if the option is changeable at run-time
has cache_enabled => sub {
    return 0;
};

has version => sub {
    my $self = shift;
    return $BibSpace::VERSION // "0.4.7";
};

################################################################
sub startup {
    my $self = shift;

    $self->setup_config;
    $self->setup_plugins;
    $self->setup_routes;
    $self->setup_hooks;

    my $dbh = $self->app->db;
    # StorageBase::init();
    # StorageBase::load($self->app->db);

    use BibSpace::Model::SmartArray;
    my $globalEntriesArray = SmartArray->new;

    use BibSpace::Model::DAO::DAOFactory;
    use BibSpace::Model::Repository::RepositoryFactory;
    use BibSpace::Model::SimpleLogger;
    # this should be helper!
    my $logger = SimpleLogger->new(); 
    my %backendConfig = (
        idProviderType => 'IntegerUidProvider',
        backends => [ 
            { prio => 1, type => 'SmartArrayDAOFactory', handle => $globalEntriesArray },
            # { prio => 2, type => 'RedisDAOFactory', handle => $redisHandle },
            { prio => 2, type => 'MySQLDAOFactory', handle => $dbh },
        ]
    );
    my $factory = RepositoryFactory->new(logger => $logger)->getInstance('LayeredRepositoryFactory',\%backendConfig);
    # this factory holds idProvider for each business entity (e.g. idProviderEntry, idProviderAuthor)
    # this factory holds instances of repositories for each business entity (e.g. instanceEntriesRepo, instanceAuthorsRepo)
    # there should be single factory in BibSpace!!!
    

    my $erepo = $factory->getEntriesRepository();
    my $arepo = $factory->getAuthorsRepository();
    
    $erepo->copy(2,1); # COPY from MySQL to Array
    

    my @allEntries = $erepo->all();
    # $logger->debug( "ALL Entries: ".join(', ', map{$_->uid} @allEntries ) );
    # @allEntries = $erepo->filter( sub{$_->id > 600} ); 
    # $logger->debug( "FILTERED Entries: ".join(', ', map{$_->id} @allEntries ) );

    my $entry  = Entry->new( idProvider=>$factory->idProviderEntry, id => 5, bib => "sth", year => 2012 );
    $logger->debug( "NEW ENTRY: ". $entry->toString );
    my $entry2 = Entry->new( idProvider=>$factory->idProviderEntry, bib => "sth", year => 2011 );
    my @entries = ( $entry, $entry2 );
    

    $logger->debug( "COUNT Entries before saving: ". $erepo->count() );
    $erepo->save(@entries);
    $logger->debug( "COUNT Entries after saving: ". $erepo->count() );

    # # my @someEntries = $erepo->filter( sub { $_->year == 2011 } );    #fake!
    # my $code = sub{defined $_ and defined $_->year and $_->year == 2011};
    # my $anEntry1 = $erepo->filter( $code ); 
    # $logger->debug( "Filter found so many entries: ". $anEntry1 );
    # my $anEntry2 = $erepo->find( $code );   

    # my $anEntry61 = $erepo->find( sub{$_->id == 61} );   
    # $logger->debug( "Filter found entry 61: ". $anEntry61->toString ) if defined $anEntry61;
    # $anEntry61->year(2077);
    # $logger->debug( "After edit 61: ". $anEntry61->toString );
    # ## NO NEED TO CALL UPDATE!!
    # $anEntry61 = $erepo->find( sub{$_->id == 61} );   
    # $logger->debug( "Filter found entry 61: ". $anEntry61->toString );

    # $logger->debug( "Exists 61?: ". $erepo->exists($anEntry61) );
    # $logger->debug( "Delete 61: ". $erepo->delete($anEntry61) );
    # $logger->debug( "Exists 61?: ". $erepo->exists($anEntry61) );

    # $logger->info("this is info");
    # $logger->warn("this is warning");
    # $logger->error("this is error");
    
    # my $en = MEntry->new();

    # say Dumper $en;

    # How I want to build the ***MySQL classes
    #
    # use BibSpace::Model::M::MAuthorMySQL2;
    # my $a1 = MAuthorMySQL->new(uid=>'sss');
    # my $a2 = MAuthorMySQL2->new(object => $a1);



    # say "##############################";
    # say "### entries count: ". $self->storage->entries_count;
    # say "### authors count: ". $en->authors_count;
    # $en->authors($dbh);
    # say "### Authors : " . Dumper $en->authors_all;


    # 
    # 
    # my $entriesJSONstring = $self->storage->freeze(); 
    # # say "Serialized Entries have length of " . length($entriesJSONstring);
    # my $storage2 = CMObjectStore->thaw($entriesJSONstring);
    # say Dumper $storage2->authors->[0];




    say "Using CONFIG: " . $self->app->config_file;
    # say "App home is: " . $self->app->home;
    # say "Active bst file is: " . $self->app->bst;


}


################################################################
sub setup_cache {
    my $self = shift;
    my $app  = $self;
}
################################################################
sub setup_config {
    my $self = shift;
    my $app  = $self;
    $self->plugin( 'Config' => { file => $self->app->config_file } );
}
################################################################
sub setup_plugins {
    my $self = shift;

    $ENV{MOJO_REVERSE_PROXY} = 1;

    $self->app->plugin('InstallablePaths');
    $self->app->plugin('RenderFile');

    push @{ $self->app->static->paths }, $self->app->home->rel_dir('public');

    # push @{$self->app->static->paths}, $self->config->{backups_dir};

    say "App version: " . $self->app->version;

    say "=== Creating directories.";
    for my $dir (
        (   $self->config->{backups_dir}, $self->config->{upload_dir},
            $self->config->{log_dir}
        )
        )
    {
        $dir =~ s!/*$!/!;
        say "\t\t: $dir";
        try {
            path($dir)->mkpath;
        }
        catch {
            warn "Exception: cannot create directory $dir. Msg: $_";
        };
    }

    $self->app->db;
    $self->plugin('BibSpace::Controller::Helpers');
    $self->plugin('BibSpace::Controller::CronHelpers');
    $self->secrets( [ $self->config->{key_cookie} ] );


    $self->helper( users => sub { state $users = CMUsers->new } );
    $self->helper( proxy_prefix => sub { $self->config->{proxy_prefix} } );


    $self->helper(
        get_referrer => sub {
            my $s   = shift;
            my $ret = $s->url_for('start');
            $ret = $s->req->headers->referrer
                if defined $s->req->headers->referrer
                and $s->req->headers->referrer ne '';
            return $ret;
        }
    );

    $self->helper(
        nohtml => sub {
            my $s = shift;
            return nohtml( shift, shift );
        }
    );

    $self->helper(
        is_manager => sub {
            my $self = shift;
            return 1 if $self->app->is_demo;
            my $login = $self->session('user');
            my $usr = MUser->static_get_by_login( $self->app->db, $login );
            return $usr->is_manager();
        }
    );

    $self->helper(
        is_admin => sub {
            my $self = shift;
            return 1 if $self->app->is_demo;
            my $login = $self->session('user');
            my $usr = MUser->static_get_by_login( $self->app->db, $login );
            return $usr->is_admin();
        }
    );

    $self->helper(
        write_log => sub {
            my $c       = shift;
            my $msg     = shift;
            my $usr     = $c->session('user') || "not_logged_in";
            my $usr_str = "(" . $usr . "): ";

            my $datetime_string = strftime( '%Y-%m-%d %H:%M:%S', localtime );

            my $filename = $self->config->{log_file};
            my $msg_to_log
                = "[" . $datetime_string . "] " . $usr_str . $msg . "\n";

            try {
                if ( open( my $fh, '>>', $filename ) ) {
                    print $fh $msg_to_log;
                    close $fh;
                }
            }
            catch {
                warn
                    "Opening log failed! Message to log: $msg_to_log . Reason: $_ ";
            };
        }
    );


}
################################################################
################################################################
sub setup_routes {
    my $self = shift;

    my $anyone = $self->routes;
    $anyone->get('/')->to('display#index')->name('start');

    $anyone->get('/test')->to('display#test');

    $anyone->get('/forgot')->to('login#forgot');
    $anyone->post('/forgot/gen')->to('login#post_gen_forgot_token');
    $anyone->get('/forgot/reset/:token')->to('login#token_clicked')
        ->name("token_clicked");
    $anyone->post('/forgot/store')->to('login#store_password');

    $anyone->get('/login_form')->to('login#login_form')->name('login_form');
    $anyone->post('/do_login')->to('login#login')->name('do_login');
    $anyone->get('/youneedtologin')->to('login#not_logged_in')
        ->name('youneedtologin');
    $anyone->get('/badpassword')->to('login#bad_password')
        ->name('badpassword');

    $anyone->get('/logout')->to('login#logout')->name('logout');

    $anyone->any('/test/500')->to('display#test500')->name('error500');
    $anyone->any('/test/404')->to('display#test404');

    $anyone->get('/register')->to('login#register')->name('register');
    $anyone->post('/register')->to('login#post_do_register')
        ->name('post_do_register');
    $anyone->any('/noregister')->to('login#register_disabled');

    my $logged_user = $anyone->under->to('login#check_is_logged_in');
    my $manager     = $logged_user->under->to('login#under_check_is_manager');
    my $superadmin  = $logged_user->under->to('login#under_check_is_admin');

    ################ SETTINGS ################
    $logged_user->get('/profile')->to('login#profile');
    $superadmin->get('/manage_users')->to('login#manage_users')
        ->name('manage_users');
    $superadmin->get('/profile/:id')->to('login#foreign_profile')
        ->name('show_user_profile');
    $superadmin->get('/profile/delete/:id')->to('login#delete_user')
        ->name('delete_user');

    $superadmin->get('/profile/make_user/:id')->to('login#make_user')
        ->name('make_user');
    $superadmin->get('/profile/make_manager/:id')->to('login#make_manager')
        ->name('make_manager');
    $superadmin->get('/profile/make_admin/:id')->to('login#make_admin')
        ->name('make_admin');

    $manager->get('/log')->to('display#show_log');
    $superadmin->get('/settings/fix_entry_types')
        ->to('publications#fixEntryType');
    $superadmin->get('/settings/fix_months')->to('publications#fixMonths');

    $manager->get('/settings/clean_all')
        ->to('publications#clean_ugly_bibtex')->name('clean_ugly_bibtex');
    $manager->get('/settings/regenerate_all_force')
        ->to('publications#regenerate_html_for_all_force');
    $logged_user->get('/settings/regenerate_all')
        ->to('publications#regenerate_html_for_all');

    # RESTIfied begin
    # GET '/backups'
    $logged_user->get('/backups')->to('backup#index')->name('backup_index');

    # PUT '/backups'
    $anyone->put('/backups')->to('backup#save')->name('backup_do');

    # GET '/backups/id'
    $logged_user->get('/backups/:id')->to('backup#backup_download')
        ->name('backup_download');

    # DELETE '/backups/id'
    $superadmin->delete('/backups/:id')->to('backup#delete_backup')
        ->name('backup_delete');

#$superadmin->post('/backups')->to('backup#delete_backup')->name('backup_delete');

# PUT '/backups/id'
# $manager->get('/restore/do/:id')->to('backup#restore_backup')->name('backup_restore');
    $manager->put('/backups/:id')->to('backup#restore_backup')
        ->name('backup_restore');

    # DELETE '/backups'
    $manager->delete('/backups')->to('backup#cleanup')
        ->name('backup_cleanup');

    # RESTIfied end

    ################ TYPES ################
    $logged_user->get('/types')->to('types#all_our');
    $logged_user->get('/types/add')->to('types#add_type');
    $logged_user->post('/types/add')->to('types#post_add_type');
    $logged_user->get('/types/manage/:type')->to('types#manage');
    $logged_user->get('/types/delete/:type_to_delete')
        ->to('types#delete_type');

    $logged_user->post('/types/store_description')
        ->to('types#post_store_description');
    $logged_user->get('/types/toggle/:type')->to('types#toggle_landing');

    $logged_user->get('/types/:our_type/map/:bibtex_type')
        ->to('types#map_types');
    $logged_user->get('/types/:our_type/unmap/:bibtex_type')
        ->to('types#unmap_types');

    ################ AUTHORS ################

    $logged_user->get('/authors/')->to('authors#all_authors')->name('all_authors');
    $logged_user->get('/authors/add')->to('authors#add_author')
        ->name('add_author');
    $logged_user->post('/authors/add/')->to('authors#add_post');

    $logged_user->get('/authors/edit/:id')->to('authors#edit_author')
        ->name('edit_author');
    $logged_user->post('/authors/edit/')->to('authors#edit_post')
        ->name('edit_author_post');
    $logged_user->get('/authors/delete/:id')->to('authors#delete_author')
        ->name('delete_author');
    $logged_user->get('/authors/delete/:id/force')
        ->to('authors#delete_author_force');
    $logged_user->post('/authors/edit_membership_dates')
        ->to('authors#post_edit_membership_dates')
        ->name('edit_author_membership_dates');

    $logged_user->get('/authors/:id/add_to_team/:tid')
        ->to('authors#add_to_team')->name('add_author_to_team');
    $logged_user->get('/authors/:id/remove_from_team/:tid')
        ->to('authors#remove_from_team')->name('remove_author_from_team');
    $logged_user->get('/authors/:masterid/remove_uid/:uid')
        ->to('authors#remove_uid')->name('remove_author_uid');

    $logged_user->post('/authors/merge/')->to('authors#merge_authors')
        ->name('merge_authors');

    $logged_user->get('/authors/reassign')
        ->to('authors#reassign_authors_to_entries');
    $logged_user->get('/authors/reassign_and_create')
        ->to('authors#reassign_authors_to_entries_and_create_authors');

    $logged_user->get('/authors/toggle_visibility/:id')
        ->to('authors#toggle_visibility')->name('toggle_author_visibility');

    # $logged_user->get('/authors/toggle_visibility')
    #     ->to('authors#toggle_visibility');

    ################ TAG TYPES ################
    # $logged_user->get('/tags/')->to('tags#index')->name("tags_index");
    $logged_user->get('/tagtypes')->to('tagtypes#index')
        ->name('all_tag_types');
    $superadmin->get('/tagtypes/add')->to('tagtypes#add')
        ->name('add_tag_type');
    $superadmin->post('/tagtypes/add')->to('tagtypes#add_post')
        ->name('add_tag_type_post');
    $superadmin->get('/tagtypes/delete/:id')->to('tagtypes#delete')
        ->name('delete_tag_type');
    $manager->any('/tagtypes/edit/:id')->to('tagtypes#edit')
        ->name('edit_tag_type');

    ################ TAGS ################
    $logged_user->get('/tags/:type')->to( 'tags#index', type => 1 )
        ->name('all_tags');
    $superadmin->get('/tags/add/:type')->to( 'tags#add', type => 1 );
    $superadmin->post('/tags/add/:type')->to( 'tags#add_post', type => 1 );
    $logged_user->get('/tags/authors/:tid/:type')
        ->to( 'tags#get_authors_for_tag', type => 1 )
        ->name('get_authors_for_tag');
    $superadmin->any('/tags/add_and_assign/:eid')->to('tags#add_and_assign');
    $superadmin->get('/tags/delete/:id_to_delete')->to('tags#delete');
    $manager->get('/tags/edit/:id')->to('tags#edit');

    ################ TEAMS ################
    $logged_user->get('/teams')->to('teams#show')->name('all_teams');
    $logged_user->get('/teams/members/:teamid')->to('teams#team_members');

    $logged_user->get('/teams/edit/:teamid')->to('teams#edit')
        ->name('edit_team');
    $logged_user->get('/teams/delete/:id')
        ->to('teams#delete_team')
        ->name('delete_team');
    $logged_user->get('/teams/delete/:id/force')
        ->to('teams#delete_team_force')
        ->name('delete_team_force');
    $logged_user->get('/teams/unrealted_papers/:teamid')
        ->to('publications#show_unrelated_to_team')
        ->name('unrelated_papers_for_team');

    $logged_user->get('/teams/add')->to('teams#add_team')
        ->name('add_team_get');
    $logged_user->post('/teams/add/')->to('teams#add_team_post');

    ################ EDITING PUBLICATIONS ################
    #<<< no perltidy here
    # EXPERIMENTAL

    $logged_user->get('/publications/add_many')
        ->to('publicationsexperimental#publications_add_many_get')
        ->name('add_many_publications');
    $logged_user->post('/publications/add_many')
        ->to('publicationsexperimental#publications_add_many_post')
        ->name('add_many_publications_post');

    # EXPERIMENTAL END

    $logged_user->get('/publications')
        ->to('publications#all')
        ->name('publications');

    $logged_user->get('/publications/recently_added/:num')
        ->to('publications#all_recently_added')
        ->name('recently_added');

    $logged_user->get('/publications/recently_modified/:num')
        ->to('publications#all_recently_modified')
        ->name('recently_changed');

    $logged_user->get('/publications/orphaned')
        ->to('publications#all_without_author');

    $logged_user->get('/publications/untagged/:tagtype')
        ->to( 'publications#all_without_tag', tagtype => 1 )
        ->name('get_untagged_publications');

    $logged_user->get('/publications/untagged/:author/:tagtype')
        ->to('publications#all_without_tag_for_author')
        ->name('get_untagged_publications_for_author');

    $logged_user->get('/publications/candidates_to_delete')
        ->to('publications#all_candidates_to_delete');

    $logged_user->get('/publications/missing_month')
        ->to('publications#all_with_missing_month');

    $logged_user->get('/publications/get/:id')
        ->to('publications#single')
        ->name('get_single_publication');
    #
    $anyone->get('/publications/download/:filetype/:id')
        ->to('publications#download')
        ->name('download_publication');

    $anyone->get('/publications/download/:filetype/(:id).pdf')
        ->to('publications#download')
        ->name('download_publication_pdf');
    #
    $logged_user->get('/publications/remove_attachment/:filetype/:id')
        ->to('publications#remove_attachment')
        ->name('publications_remove_attachment');

    $logged_user->get('/publications/hide/:id')
        ->to('publications#hide');

    $logged_user->get('/publications/unhide/:id')
        ->to('publications#unhide');

    $logged_user->get('/publications/toggle_hide/:id')
        ->to('publications#toggle_hide')
        ->name('toggle_hide_publication');

    # candidate to be removed
    $superadmin->get('/publications/fix_urls')              
        ->to('publications#replace_urls_to_file_serving_function')
        ->name('fix_attachment_urls');


    $logged_user->get('/publications/add')
        ->to('publications#publications_add_get')
        ->name('add_publication');

    $logged_user->post('/publications/add')
        ->to('publications#publications_add_post')
        ->name('add_publication_post');

    $logged_user->get('/publications/edit/:id')
        ->to('publications#publications_edit_get')
        ->name('edit_publication');

    $logged_user->post('/publications/edit/:id')
        ->to('publications#publications_edit_post')
        ->name('edit_publication_post');

    $logged_user->get('/publications/make_paper/:id')
        ->to('publications#make_paper')
        ->name('make_paper');

    $logged_user->get('/publications/make_talk/:id')
        ->to('publications#make_talk')
        ->name('make_talk');

    $logged_user->get('/publications/regenerate/:id')
        ->to('publications#regenerate_html')
        ->name('regenerate_publication');


    # change to POST or DELETE
    $logged_user->get('/publications/delete_sure/:id')
        ->to('publications#delete_sure')
        ->name('delete_publication_sure');

    $logged_user->get('/publications/attachments/:id')
        ->to('publications#add_pdf')
        ->name('manage_attachments');

    $logged_user->post('/publications/add_pdf/do/:id')
        ->to('publications#add_pdf_post')
        ->name('post_upload_pdf');

    $logged_user->get('/publications/manage_tags/:id')
        ->to('publications#manage_tags')
        ->name('manage_tags');

    # change to POST or DELETE
    $logged_user->get('/publications/:eid/remove_tag/:tid')
        ->to('publications#remove_tag')
        ->name('remove_tag_from_publication');

    # change to POST or UPDATE
    $logged_user->get('/publications/:eid/add_tag/:tid')
        ->to('publications#add_tag')
        ->name('add_tag_to_publication');

    $logged_user->get('/publications/manage_exceptions/:id')
        ->to('publications#manage_exceptions')
        ->name('manage_exceptions');

    # change to POST or DELETE
    $logged_user->get('/publications/:eid/remove_exception/:tid')
        ->to('publications#remove_exception')
        ->name('remove_exception_from_publication');

    # change to POST or UPDATE
    $logged_user->get('/publications/:eid/add_exception/:tid')
        ->to('publications#add_exception')
        ->name('add_exception_to_publication');

    $logged_user->get('/publications/show_authors/:id')
        ->to('publications#show_authors_of_entry')
        ->name('show_authors_of_entry');

    #>>> 
    ################ OPEN ACCESS ################

    # contains meta info for every paper. Optimization for google scholar
    $anyone->get('/read/publications/meta')->to('publicationsSEO#metalist')
        ->name("metalist_all_entries");
    $anyone->get('/read/publications/meta/:id')->to('publicationsSEO#meta')
        ->name("metalist_entry");

    ################

    $anyone->get('/read/publications')->to('publications#all_read');
    $anyone->get('/r/publications')->to('publications#all_read');    #ALIAS
    $anyone->get('/r/p')->to('publications#all_read');               #ALIAS

    $anyone->get('/read/bibtex')->to('publications#all_bibtex');
    $anyone->get('/r/bibtex')->to('publications#all_bibtex');        #ALIAS
    $anyone->get('/r/b')->to('publications#all_bibtex');             #ALIAS

    $anyone->get('/read/publications/get/:id')
        ->to('publications#single_read')->name('get_single_publication_read');
    $anyone->get('/r/p/get/:id')->to('publications#single_read');

    ######## PublicationsLanding

    $anyone->get('/landing/publications')
        ->to('PublicationsLanding#landing_types_obj')
        ->name('landing_publications');
    $anyone->get('/l/p')->to('PublicationsLanding#landing_types_obj')
        ->name('lp');

    $anyone->get('/landing-years/publications')
        ->to('PublicationsLanding#landing_years_obj')
        ->name('landing_years_publications');
    $anyone->get('/ly/p')->to('PublicationsLanding#landing_years_obj'); #ALIAS

    ########

    $anyone->get('/read/authors-for-tag/:tid/:team')
        ->to('tags#get_authors_for_tag_read')
        ->name('get_authors_for_tag_read');

    #ALIAS
    $anyone->get('/r/a4t/:tid/:team')->to('tags#get_authors_for_tag_read')
        ->name('get_authors_for_tag_read');

    $anyone->get('/read/tags-for-author/:author_id')
        ->to('tags#get_tags_for_author_read')->name('tags_for_author');
    $anyone->get('/r/t4a/:author_id')->to('tags#get_tags_for_author_read')
        ;    #ALIAS

    $anyone->get('/read/tags-for-team/:tid')
        ->to('tags#get_tags_for_team_read')->name('tags_for_team');
    $anyone->get('/r/t4t/:tid')->to('tags#get_tags_for_team_read');    #ALIAS

    ################ CRON ################

    $anyone->get('/cron')->to('cron#index');
    $anyone->get('/cron/:level')->to('cron#cron');

    $anyone->get('/cron/night')->to('cron#cron_day');
    $anyone->get('/cron/night')->to('cron#cron_night');
    $anyone->get('/cron/week')->to('cron#cron_week');
    $anyone->get('/cron/month')->to('cron#cron_month');

}

################################################################

sub setup_hooks {
    my $self = shift;

    $self->hook(
        before_dispatch => sub {
            my $c = shift;
            {
                my $db_host     = $self->config->{db_host};
                my $db_user     = $self->config->{db_user};
                my $db_database = $self->config->{db_database};
                my $db_pass     = $self->config->{db_pass};
                my $is_up
                    = db_is_up( $db_host, $db_user, $db_database, $db_pass );
                unless ($is_up) {
                    my $err_msg
                        = "MySQL is not running! BibSpace cannot work without a database.";
                    say "\n$err_msg\n";
                    $c->render( text => $err_msg, status => 500 );
                    return;
                }
            }

            $c->req->url->base->scheme('https')
                if $c->req->headers->header('X-Forwarded-HTTPS');

            # dirty fix for production deployment in a directory
            my $proxy_prefix = $self->config->{proxy_prefix};
            if ( $proxy_prefix ne "" ) {

                # we remove the leading slash
                $proxy_prefix =~ s|^/||;
                push @{ $c->req->url->base->path->trailing_slash(1) },
                    $proxy_prefix;
            }
        }
    );
}

1;
