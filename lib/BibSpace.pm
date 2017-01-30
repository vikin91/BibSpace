package BibSpace v0.5.0;

# ABSTRACT: BibSpace is a system to manage Bibtex references for authors and research groups web page.

use BibSpace::Controller::Core;
use BibSpace::Controller::BackupFunctions;
use BibSpace::Controller::Publications;
use BibSpace::Controller::PublicationsLanding;
use BibSpace::Controller::PublicationsExperimental;
use BibSpace::Controller::PublicationsSEO;
use BibSpace::Controller::Helpers;

use BibSpace::Model::SimpleLogger;

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

use BibSpace::Model::DAO::DAOFactory;
use BibSpace::Model::SmartArray;

use BibSpace::Model::SmartUidProvider;
use BibSpace::Model::Repository::LayeredRepository;
use BibSpace::Model::Repository::RepositoryLayer;
use BibSpace::Model::Repository::RepositoryFacade;

use Storable;

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
  return;
};


has config_file => sub {
  my $self = shift;
  return $ENV{BIBSPACE_CONFIG} if $ENV{BIBSPACE_CONFIG};
  return $self->app->home->rel_file('/etc/bibspace.conf') if -e $self->app->home->rel_file('/etc/bibspace.conf');
  return $self->app->home->rel_file('lib/BibSpace/files/config/default.conf')
    if -e $self->app->home->rel_file('lib/BibSpace/files/config/default.conf');
  return $self->app->home->rel_file('config/default.conf')    # for travis
    if -e $self->app->home->rel_file('config/default.conf');
};

# has db => sub {
#   my $self = shift;
#   state $db = db_connect(
#     $self->config->{db_host},
#     $self->config->{db_user},
#     $self->config->{db_database},
#     $self->config->{db_pass}
#   );
# };

has version => sub {
  return $BibSpace::VERSION // "0.5.0";
};

has appStateDumpFileName => sub {
  return 'bibspace.dat';
};

has useDumpFixture => sub {
  return $ENV{BIBSPACE_USE_DUMP} if $ENV{BIBSPACE_USE_DUMP};
  return;
};

has logger => sub { state $logger = SimpleLogger->new };


has smartArrayBackend => sub {
  my $self = shift;
  return SmartArray->new( logger => $self->logger );
};


has layeredRepository => sub {
  my $self = shift;
  $self->app->logger->warn("Calling layeredRepository");
  my $sup = SmartUidProvider->new(logger=> $self->logger, idProviderClassName => 'IntegerUidProvider');
  my $LR = LayeredRepository->new(logger => $self->logger, uidProvider => $sup);

  my $smartArrayLayer = RepositoryLayer->new(
    name => 'smart',
    priority => 1,
    backendFactoryName => "SmartArrayDAOFactory", 
    logger => $self->logger,
    handle => $self->smartArrayBackend,
    is_read => 1);

  my $mySQLLayer = RepositoryLayer->new( 
    name => 'mysql',
    priority => 99,
    backendFactoryName => "MySQLDAOFactory", 
    logger => $self->logger,
    handle => $self->db);

  $LR->add_layer($smartArrayLayer);
  $LR->add_layer($mySQLLayer);
  return $LR;
};

has repo => sub {
  my $self = shift;
  return RepositoryFacade->new(lr => $self->layeredRepository);

};

################################################################
sub startup {
  my $self = shift;
  $self->app->logger->info("*** Starting BibSpace ***");


  $self->app->logger->info("Setup config...");
  $self->setup_config;

  $self->helper(
    db => sub {
      my $self = shift;
      my $db = db_connect(
        $self->config->{db_host},
        $self->config->{db_user},
        $self->config->{db_database},
        $self->config->{db_pass}
      );
      return $db;
    }
  );

  $self->app->logger->info("Setup plugins...");
  $self->setup_plugins;

  $self->app->logger->info("Setup routes...");
  $self->setup_routes;

  $self->app->logger->info("Setup hooks...");
  $self->setup_hooks;

  $self->app->logger->info("Connecting to database...");
  $self->app->db;

  $self->app->logger->info("Setup repositories...");
  $self->setup_repositories;

  $self->app->logger->info("Setup done.");

  $self->app->logger->info( "Using CONFIG: " . $self->app->config_file );
  $self->app->logger->info( "App home is: " . $self->app->home );
  $self->app->logger->info( "Active bst file is: " . $self->app->bst );

  # $self->logger->info("this is info");
  # $self->logger->warn("this is warning");
  # $self->logger->error("this is error");
  # foreach (0..1){
  #   my $testEntry = Entry->new(bib=>'@article{title={xyz'.$_.'}, year={2099}}');
  #   $self->repo->entries_save($testEntry);
  # }
}

################################################################
sub setup_repositories {
  my $self = shift;


  $self->app->logger->debug($self->repo->lr->get_summary_string);

  if( -e $self->appStateDumpFileName and $self->useDumpFixture ){
    my $layer = retrieve($self->appStateDumpFileName);
    $self->repo->lr->replace_layer('smart', $layer);
  }
  # no data, no fun = no need copy, link, and store
  if( $self->repo->entries_empty ){
    $self->repo->lr->copy_data( { from => 'mysql', to => 'smart' } );
    $self->link_data;
    store $self->repo->lr->get_read_layer, $self->appStateDumpFileName;  
  }

  $self->app->logger->debug($self->repo->lr->get_summary_string);


  # my $eidP = $self->repo->entries_idProvider;
  # foreach (0..100){
  #   my $testEntry = Entry->new(idProvider => $eidP, bib=>'@article{key'.$_.', title={xyz'.$_.'}, year={2099}}');
  #   say "testEntry:".$testEntry->id;
  #   $self->repo->entries_save($testEntry);
  # }

  # $self->app->logger->debug($self->repo->lr->get_summary_string);


  # my $rf = $self->repo;

  # my @allAuthors = $rf->authors_filter(sub{$_->is_visible}); #good!!

  # for my $e (@allAuthors) {
  #   say $e->uid;    
  # }

}
################################################################
sub link_data {
  my $self = shift;
  $self->app->logger->info("Linking data...");

  $self->app->logger->info("Linking Authors (N) to (1) Authors.");
  foreach my $author ( $self->repo->authors_filter( sub { $_->id != $_->master_id } ) ) {
    my $master = $self->repo->authors_find( sub { $_->id == $author->master_id } );
    if ( $master and $author ) {
      $author->set_master($master);
    }
  }


  $self->app->logger->info("Linking Authors (N) to (M) Entries.");
  foreach my $auth ( $self->repo->authorships_all ) {
    my $entry  = $self->repo->entries_find( sub { $_->id == $auth->entry_id } );
    my $author = $self->repo->authors_find( sub { $_->id == $auth->author_id } );
    if ( $entry and $author ) {
      $auth->entry($entry);
      $auth->author($author);
      $entry->authorships_add($auth);
      $author->authorships_add($auth);
    }
  }

  $self->app->logger->info("Linking Tags (N) to (M) Entries.");
  foreach my $labeling ( $self->repo->labelings_all ) {
    my $entry = $self->repo->entries_find( sub { $_->id == $labeling->entry_id } );
    my $tag   = $self->repo->tags_find( sub    { $_->id == $labeling->tag_id } );
    if ( $entry and $tag ) {
      $labeling->entry($entry);
      $labeling->tag($tag);
      $entry->labelings_add($labeling);
      $tag->labelings_add($labeling);
    }
  }

  $self->app->logger->info("Linking Teams (Exceptions) (N) to (M) Entries.");
  foreach my $exception ( $self->repo->exceptions_all ) {
    my $entry = $self->repo->entries_find( sub { $_->id == $exception->entry_id } );
    my $team  = $self->repo->teams_find( sub   { $_->id == $exception->team_id } );
    if ( $entry and $team ) {
      $exception->entry($entry);
      $exception->team($team);
      $entry->exceptions_add($exception);
      $team->exceptions_add($exception);
    }
  }


  $self->app->logger->info("Linking Teams (N) to (M) Authors.");
  foreach my $membership ( $self->repo->memberships_all ) {
    my $author = $self->repo->authors_find( sub { $_->id == $membership->author_id } );
    my $team   = $self->repo->teams_find( sub   { $_->id == $membership->team_id } );
    if ( defined $author and defined $team ) {
      $membership->author($author);
      $membership->team($team);
      $author->memberships_add($membership);
      $team->memberships_add($membership);
    }
  }

  $self->app->logger->info("Linking TagTypes (N) to (1) Tags.");
  foreach my $tag ( $self->repo->tags_all ) {
    my $tagtype = $self->repo->tagTypes_find( sub { $_->id == $tag->type } );
    if ( $tag and $tagtype ) {
      $tag->tagtype($tagtype);
    }
  }

  $self->app->logger->info("TODO: Linking OurTypes (N) to (1) Entries.");

  $self->app->logger->info("Linking Finished.");
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

  push @{ $self->app->static->paths }, $self->app->home->rel_file('public');

  # push @{$self->app->static->paths}, $self->config->{backups_dir};

  say "App version: " . $self->app->version;

  say "=== Creating directories.";
  for my $dir ( ( $self->config->{backups_dir}, $self->config->{upload_dir}, $self->config->{log_dir} ) ) {
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
      $ret = $s->req->headers->referrer if defined $s->req->headers->referrer and $s->req->headers->referrer ne '';
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

      my $filename   = $self->config->{log_file};
      my $msg_to_log = "[" . $datetime_string . "] " . $usr_str . $msg . "\n";

      try {
        if ( open( my $fh, '>>', $filename ) ) {
          print $fh $msg_to_log;
          close $fh;
        }
      }
      catch {
        warn "Opening log failed! Message to log: $msg_to_log . Reason: $_ ";
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
  $anyone->get('/forgot/reset/:token')->to('login#token_clicked')->name("token_clicked");
  $anyone->post('/forgot/store')->to('login#store_password');

  $anyone->get('/login_form')->to('login#login_form')->name('login_form');
  $anyone->post('/do_login')->to('login#login')->name('do_login');
  $anyone->get('/youneedtologin')->to('login#not_logged_in')->name('youneedtologin');
  $anyone->get('/badpassword')->to('login#bad_password')->name('badpassword');

  $anyone->get('/logout')->to('login#logout')->name('logout');

  $anyone->any('/test/500')->to('display#test500')->name('error500');
  $anyone->any('/test/404')->to('display#test404');

  $anyone->get('/register')->to('login#register')->name('register');
  $anyone->post('/register')->to('login#post_do_register')->name('post_do_register');
  $anyone->any('/noregister')->to('login#register_disabled');

  my $logged_user = $anyone->under->to('login#check_is_logged_in');
  my $manager     = $logged_user->under->to('login#under_check_is_manager');
  my $superadmin  = $logged_user->under->to('login#under_check_is_admin');

  ################ SETTINGS ################
  $logged_user->get('/profile')->to('login#profile');
  $superadmin->get('/manage_users')->to('login#manage_users')->name('manage_users');
  $superadmin->get('/profile/:id')->to('login#foreign_profile')->name('show_user_profile');
  $superadmin->get('/profile/delete/:id')->to('login#delete_user')->name('delete_user');

  $superadmin->get('/profile/make_user/:id')->to('login#make_user')->name('make_user');
  $superadmin->get('/profile/make_manager/:id')->to('login#make_manager')->name('make_manager');
  $superadmin->get('/profile/make_admin/:id')->to('login#make_admin')->name('make_admin');

  $manager->get('/log')->to('display#show_log');
  $superadmin->get('/settings/fix_months')->to('publications#fixMonths');

  $manager->get('/settings/clean_all')->to('publications#clean_ugly_bibtex')->name('clean_ugly_bibtex');
  $manager->get('/settings/regenerate_all_force')->to('publications#regenerate_html_for_all_force');
  $logged_user->get('/settings/regenerate_all')->to('publications#regenerate_html_for_all');

  # RESTIfied begin
  # GET '/backups'
  $logged_user->get('/backups')->to('backup#index')->name('backup_index');

  # PUT '/backups'
  $anyone->put('/backups')->to('backup#save')->name('backup_do');

  # GET '/backups/id'
  $logged_user->get('/backups/:id')->to('backup#backup_download')->name('backup_download');

  # DELETE '/backups/id'
  $superadmin->delete('/backups/:id')->to('backup#delete_backup')->name('backup_delete');

#$superadmin->post('/backups')->to('backup#delete_backup')->name('backup_delete');

# PUT '/backups/id'
# $manager->get('/restore/do/:id')->to('backup#restore_backup')->name('backup_restore');
  $manager->put('/backups/:id')->to('backup#restore_backup')->name('backup_restore');

  # DELETE '/backups'
  $manager->delete('/backups')->to('backup#cleanup')->name('backup_cleanup');

  # RESTIfied end

  ################ TYPES ################
  $logged_user->get('/types')->to('types#all_our');
  $logged_user->get('/types/add')->to('types#add_type');
  $logged_user->post('/types/add')->to('types#post_add_type');
  $logged_user->get('/types/manage/:type')->to('types#manage');
  $logged_user->get('/types/delete/:type_to_delete')->to('types#delete_type');

  $logged_user->post('/types/store_description')->to('types#post_store_description');
  $logged_user->get('/types/toggle/:type')->to('types#toggle_landing');

  $logged_user->get('/types/:our_type/map/:bibtex_type')->to('types#map_types');
  $logged_user->get('/types/:our_type/unmap/:bibtex_type')->to('types#unmap_types')->name('unmap_bibtex_type');

  ################ AUTHORS ################

  $logged_user->get('/authors/')->to('authors#all_authors')->name('all_authors');
  $logged_user->get('/authors/add')->to('authors#add_author')->name('add_author');
  $logged_user->post('/authors/add/')->to('authors#add_post');

  $logged_user->get('/authors/edit/:id')->to('authors#edit_author')->name('edit_author');
  $logged_user->post('/authors/edit/')->to('authors#edit_post')->name('edit_author_post');
  $logged_user->get('/authors/delete/:id')->to('authors#delete_author')->name('delete_author');
  $logged_user->get('/authors/delete/:id/force')->to('authors#delete_author_force');
  $logged_user->post('/authors/edit_membership_dates')->to('authors#post_edit_membership_dates')
    ->name('edit_author_membership_dates');

  $logged_user->get('/authors/:id/add_to_team/:tid')->to('authors#add_to_team')->name('add_author_to_team');
  $logged_user->get('/authors/:id/remove_from_team/:tid')->to('authors#remove_from_team')
    ->name('remove_author_from_team');
  $logged_user->get('/authors/:masterid/remove_uid/:uid')->to('authors#remove_uid')->name('remove_author_uid');

  $logged_user->post('/authors/merge/')->to('authors#merge_authors')->name('merge_authors');

  $logged_user->get('/authors/reassign')->to('authors#reassign_authors_to_entries');
  $logged_user->get('/authors/reassign_and_create')->to('authors#reassign_authors_to_entries_and_create_authors');

  $logged_user->get('/authors/toggle_visibility/:id')->to('authors#toggle_visibility')
    ->name('toggle_author_visibility');

  # $logged_user->get('/authors/toggle_visibility')
  #     ->to('authors#toggle_visibility');

  ################ TAG TYPES ################
  # $logged_user->get('/tags/')->to('tags#index')->name("tags_index");
  $logged_user->get('/tagtypes')->to('tagtypes#index')->name('all_tag_types');
  $superadmin->get('/tagtypes/add')->to('tagtypes#add')->name('add_tag_type');
  $superadmin->post('/tagtypes/add')->to('tagtypes#add_post')->name('add_tag_type_post');
  $superadmin->get('/tagtypes/delete/:id')->to('tagtypes#delete')->name('delete_tag_type');
  $manager->any('/tagtypes/edit/:id')->to('tagtypes#edit')->name('edit_tag_type');

  ################ TAGS ################
  $logged_user->get('/tags/:type')->to( 'tags#index', type => 1 )->name('all_tags');
  $superadmin->get('/tags/add/:type')->to( 'tags#add', type => 1 );
  $superadmin->post('/tags/add/:type')->to( 'tags#add_post', type => 1 );
  $logged_user->get('/tags/authors/:tid/:type')->to( 'tags#get_authors_for_tag', type => 1 )
    ->name('get_authors_for_tag');
  $superadmin->get('/tags/delete/:id')->to('tags#delete')->name('delete_tag');
  $manager->get('/tags/edit/:id')->to('tags#edit');

  ################ TEAMS ################
  $logged_user->get('/teams')->to('teams#show')->name('all_teams');
  $logged_user->get('/teams/members/:teamid')->to('teams#team_members');

  $logged_user->get('/teams/edit/:teamid')->to('teams#edit')->name('edit_team');
  $logged_user->get('/teams/delete/:id')->to('teams#delete_team')->name('delete_team');
  $logged_user->get('/teams/delete/:id/force')->to('teams#delete_team_force')->name('delete_team_force');
  $logged_user->get('/teams/unrealted_papers/:teamid')->to('publications#show_unrelated_to_team')
    ->name('unrelated_papers_for_team');

  $logged_user->get('/teams/add')->to('teams#add_team')->name('add_team_get');
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

   
  ################ OPEN ACCESS ################

  # contains meta info for every paper. Optimization for google scholar
  $anyone->get('/read/publications/meta')
    ->to('publicationsSEO#metalist')
    ->name("metalist_all_entries");
  $anyone->get('/read/publications/meta/:id')
    ->to('publicationsSEO#meta')
    ->name("metalist_entry");

  ################

  $anyone->get('/read/publications')->to('publications#all_read');
  $anyone->get('/r/publications')->to('publications#all_read');    #ALIAS
  $anyone->get('/r/p')->to('publications#all_read');               #ALIAS

  $anyone->get('/read/bibtex')->to('publications#all_bibtex');
  $anyone->get('/r/bibtex')->to('publications#all_bibtex');        #ALIAS
  $anyone->get('/r/b')->to('publications#all_bibtex');             #ALIAS

  $anyone->get('/read/publications/get/:id')
    ->to('publications#single_read')
    ->name('get_single_publication_read');
  $anyone->get('/r/p/get/:id')
    ->to('publications#single_read');

  ######## PublicationsLanding

  $anyone->get('/landing/publications')
    ->to('PublicationsLanding#landing_types_obj')
    ->name('landing_publications');
  $anyone->get('/l/p')
    ->to('PublicationsLanding#landing_types_obj')
    ->name('lp');

  $anyone->get('/landing-years/publications')
    ->to('PublicationsLanding#landing_years_obj')
    ->name('landing_years_publications');
  $anyone->get('/ly/p')
    ->to('PublicationsLanding#landing_years_obj');    #ALIAS

  ########

  $anyone->get('/read/authors-for-tag/:tid/:team')
    ->to('tags#get_authors_for_tag_read')
    ->name('get_authors_for_tag_read');

  #ALIAS
  $anyone->get('/r/a4t/:tid/:team')
    ->to('tags#get_authors_for_tag_read')
    ->name('get_authors_for_tag_read');

  $anyone->get('/read/tags-for-author/:author_id')
    ->to('tags#get_tags_for_author_read')
    ->name('tags_for_author');
  $anyone->get('/r/t4a/:author_id')
    ->to('tags#get_tags_for_author_read');    #ALIAS

  $anyone->get('/read/tags-for-team/:tid')
    ->to('tags#get_tags_for_team_read')
    ->name('tags_for_team');
  $anyone->get('/r/t4t/:tid')
    ->to('tags#get_tags_for_team_read');            #ALIAS

  ################ CRON ################

  $anyone->get('/cron')->to('cron#index');
  $anyone->get('/cron/:level')->to('cron#cron');

  $anyone->get('/cron/night')->to('cron#cron_day');
  $anyone->get('/cron/night')->to('cron#cron_night');
  $anyone->get('/cron/week')->to('cron#cron_week');
  $anyone->get('/cron/month')->to('cron#cron_month');
   #>>> 
}

################################################################

sub setup_hooks {
  my $self = shift;

  $self->hook(
    before_dispatch => sub {
      my $c = shift;

      # {
      #   # my $db_host     = $self->config->{db_host};
      #   # my $db_user     = $self->config->{db_user};
      #   # my $db_database = $self->config->{db_database};
      #   # my $db_pass     = $self->config->{db_pass};
      #   if ( !$self->app->db ) {
      #     my $err_msg = "MySQL is not running!";
      #     $err_msg .= " BibSpace cannot work without a database.";
      #     $self->logger->error($err_msg);
      #     $c->render( text => $err_msg, status => 500 );
      #     return;
      #   }
      # }

      $c->req->url->base->scheme('https') if $c->req->headers->header('X-Forwarded-HTTPS');

      # dirty fix for production deployment in a directory
      my $proxy_prefix = $self->config->{proxy_prefix};
      if ( $proxy_prefix ne "" ) {

        # we remove the leading slash
        $proxy_prefix =~ s|^/||;
        push @{ $c->req->url->base->path->trailing_slash(1) }, $proxy_prefix;
      }
    }
  );
}

1;
