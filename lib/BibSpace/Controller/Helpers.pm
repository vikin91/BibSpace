package BibSpace::Controller::Helpers;

use Data::Dumper;
use utf8;
use Text::BibTeX;    # parsing bib files
use DateTime;
# use File::Slurp;

use v5.16;           #because of ~~
use strict;
use warnings;


use List::MoreUtils qw(any uniq);

use BibSpace::Functions::Core;
use BibSpace::Controller::Publications;
use BibSpace::Functions::MySqlBackupFunctions;
use BibSpace::Functions::FDB;

use BibSpace::Functions::FPublications;


use base 'Mojolicious::Plugin';

sub register {

  my ( $self, $app ) = @_;

  # this must be a helper, 
  # because smartIDprovider can be exchanged during system lifetime (e.g. restore backup), 
  # so the reference must always point to the currently valid id provider
  # smartIDProvider must be instantiated INSIDE LayeredRepository
  $app->helper(
    smartIDProvider => sub {
      my $self = shift;
      return $self->app->layeredRepository->uidProvider;
    }
  );

  # this must be a helper, 
  # because entityFactory can be exchanged during system lifetime (e.g. restore backup), 
  # so the reference must always point to the currently valid id provider
  # entityFactory must be instantiated INSIDE LayeredRepository
  $app->helper(
    entityFactory => sub {
      my $self = shift;
      return $self->app->layeredRepository->e_factory;
    }
  );


  $app->attr(layeredRepository => sub {
    my $self = shift;
    $self->app->logger->info("Building layeredRepository");
    

    my $LR = LayeredRepository->new(
        logger      => $self->logger,
        preferences => $self->preferences
    );

    my $smartArrayLayer = RepositoryLayer->new(
        name               => 'smart',
        priority           => 1,
        creates_on_read    => undef,
        backendFactoryName => "SmartArrayDAOFactory",
        logger             => $self->logger,
        handle             => $self->smartArrayBackend,

# reset_data_callback must be undef if you want to create and restore backups using Storable.
        reset_data_callback => undef,
        is_read             => 1
    );
    $LR->add_layer($smartArrayLayer);

    if ( !$self->db ) {
        $self->logger->error(
            "You add SQL layer, but there is no connection to the database! Skipping this layer."
            . " You need to start MySQL server and restart BibSpace to use this layer"
        );
    }
    else {
        my $mySQLLayer = RepositoryLayer->new(
            name                          => 'mysql',
            priority                      => 99,
            creates_on_read               => 1,
            backendFactoryName            => "MySQLDAOFactory",
            logger                        => $self->logger,
            handle                        => $self->db,
            reset_data_callback           => \&reset_db_data,
            reset_data_callback_arguments => [ $self->db ],
        );
        $LR->add_layer($mySQLLayer);
    }
    return $LR;
  });

  $app->helper(
    is_demo => sub {
      my $self = shift;
      return 1 if $self->config->{demo_mode};
      # say "helper->is_demo: run_in_demo_mode: ".$self->app->preferences->run_in_demo_mode;
      return 1 if $self->app->preferences->run_in_demo_mode == 1;
      return;
    }
  );

  $app->helper(
    db => sub {
      my $self = shift;
      return db_connect(
        $self->app->config->{db_host},     $self->app->config->{db_user},
        $self->app->config->{db_database}, $self->app->config->{db_pass}
      );
    }
  );

  $app->helper(
    bst => sub {
      my $self = shift; 

      my $bst_candidate_file = $self->app->home . '/lib/descartes2.bst';

      if ( defined $self->app->config->{bst_file} ) {
        $bst_candidate_file = $self->app->config->{bst_file};
        return File::Spec->rel2abs($bst_candidate_file)
          if File::Spec->file_name_is_absolute($bst_candidate_file)
          and -e File::Spec->rel2abs($bst_candidate_file);

        $bst_candidate_file = $self->app->home . $self->app->config->{bst_file};

        return File::Spec->rel2abs($bst_candidate_file)
          if File::Spec->file_name_is_absolute($bst_candidate_file)
          and -e File::Spec->rel2abs($bst_candidate_file);
      }

      $bst_candidate_file = $self->app->home . '/lib/descartes2.bst';

      return File::Spec->rel2abs($bst_candidate_file) if -e File::Spec->rel2abs($bst_candidate_file);

      $self->app->logger->error("Cannot find any valid bst file!");
      return './bst-not-found.bst';
    }
  );

  $app->helper(
    bibtexConverter => sub {
      my $self = shift;
      try{
          my $class = $self->app->preferences->bibitex_html_converter;
          Class::Load::load_class($class);
          if($class->does('IHtmlBibtexConverter')){
            return $class->new( logger => $self->app->logger );  
          }
          die "Requested class '$class' does not implement interface 'IHtmlBibtexConverter'";
      }
      catch{
          $self->logger->error("Requested unknown type of bibitex_html_converter: '".$self->app->preferences->bibitex_html_converter."'. Error: $_.");
      }
      finally{
        return BibStyleConverter->new( logger => $self->app->logger );
      };
    }
  );

  ## pop the previous GET page from the stack 
  $app->helper(
      pop_url_history => sub {
          my $self     = shift;
          my $last_url = shift @{ $self->session('url_history') };
          $last_url //= $self->url_for('start');
          return $last_url;
      }
  );

  $app->helper(
      get_url_history => sub {
          my $self     = shift;
          return qw(/) unless $self->session('url_history');
          return @{ $self->session('url_history') };
      }
  );

  ## add url to the stack
  $app->helper(
      push_url_history => sub {
          my $self     = shift;
          # unshift @{ $self->session('url_history') }, "".$self->req->url->path->absolute;
          if( $self->session('url_history') ){
            unshift @{ $self->session('url_history') }, "".$self->req->url;    
            # say "STACK: " . Dumper $c->session('url_history');
        } 
      }
  );

  $app->helper(
      get_referrer => sub {
        my $self = shift;
        return $self->get_referrer_old;
      }
  );

  $app->helper(
    get_referrer_new => sub {
      my $self = shift;
      my $ret  = $self->req->headers->referrer;
      # $ret //= $self->url_for('start');
      return $ret;
    }
  );
  $app->helper(
    get_referrer_old => sub {
      my $s   = shift;
      my $ret = $s->url_for('start');
      $ret = $s->req->headers->referrer
          if defined $s->req->headers->referrer
          and $s->req->headers->referrer ne '';
      return $ret;
    }
  );

  $app->helper(
      nohtml => sub {
          my $s = shift;
          return nohtml( shift, shift );
      }
  );

  $app->helper(
      is_manager => sub {
          my $self = shift;
          return 1 if $self->app->is_demo;
          return   if !$self->session('user');
          my $me = $self->app->repo->users_find(
              sub { $_->login eq $self->session('user') } );
          return if !$me;
          return $me->is_manager;
      }
  );

  $app->helper(
      is_admin => sub {
          my $self = shift;
          return 1 if $self->app->is_demo;
          return   if !$self->session('user');
          my $me = $self->app->repo->users_find(
              sub { $_->login eq $self->session('user') } );
          return if !$me;
          return $me->is_admin;
      }
  );


  $app->helper(
    current_year => sub {
      return BibSpace::Functions::Core::get_current_year();
    }
  );
  $app->helper(
    current_month => sub {
      return BibSpace::Functions::Core::get_current_month();
    }
  );

  $app->helper(
    get_year_of_oldest_entry => sub {
      my $self = shift;
      my $author = shift;

      my @entries = $self->app->repo->entries_all;

      if(defined $author){

        my $author_obj = $self->app->repo->authors_find( sub {$_->get_master->uid eq $author} );
        $author_obj ||= $self->app->repo->authors_find( sub {$_->get_master->id eq $author} );
        @entries = $author_obj->get_entries;
      }

      my @entryYears = map { $_->year } grep { defined $_->year } @entries;
      @entryYears = uniq @entryYears;
      @entryYears = sort { $a <=> $b } @entryYears;
      return $entryYears[0];
    }
  );


  $app->helper(
    can_delete_backup_helper => sub {
      my $self = shift;
      my $bid  = shift;

      return can_delete_backup( $self->app->db, $bid, $self->app->config );
    }
  );

  $app->helper(
    num_pubs => sub {
      my $self = shift;
      return $self->app->repo->entries_all;
    }
  );

  $app->helper(
    get_important_tag_types => sub {
      my $self = shift;
      return $self->app->repo->tagTypes_filter(sub{$_->id < 4});
    }
  );

  $app->helper(
    get_tag_type_obj => sub {
      my $self = shift;
      my $type = shift || 1;
      return $self->app->repo->tagTypes_find( sub { $_->id == $type } );
    }
  );

  $app->helper(
    get_tags_of_type_for_paper => sub {
      my $self = shift;
      my $eid  = shift;
      my $type = shift // 1;

      my $paper = $self->app->repo->entries_find( sub { $_->id == $eid } );
      my @tags = $paper->get_tags($type);
      @tags = sort {$a->name cmp $b->name} @tags;
      return @tags;
    }
  );

  $app->helper(
    get_unassigned_tags_of_type_for_paper => sub {
      my $self = shift;
      my $eid  = shift;
      my $type = shift // 1;

      my $paper = $self->app->repo->entries_find( sub { $_->id == $eid } );
      my %has_tags = map {$_ => 1} $paper->get_tags($type);
      my @all_tags = $self->app->repo->tags_filter( sub{$_->type == $type} );
      my @unassigned = grep { not $has_tags{$_} } @all_tags;
      @unassigned = sort {$a->name cmp $b->name} @unassigned;
      return @unassigned;
    }
  );

  $app->helper(
    num_authors => sub {
      my $self = shift;
      return $self->app->repo->authors_all;

      # return $self->storage->authors_all;

    }
  );

  $app->helper(
    get_visible_authors => sub {
      my $self = shift;
      return $self->app->repo->authors_filter( sub { $_->is_visible } );
    }
  );

  $app->helper(
    num_visible_authors => sub {
      my $self = shift;
      return scalar $self->get_visible_authors();
    }
  );

  $app->helper(
    get_num_members_for_team => sub {
      my $self   = shift;
      my $id     = shift;
      my $author = $self->storage->authors_find( sub { $_->id == $id } );
      return scalar $author->teams_count;
    }
  );

  $app->helper(
    get_num_teams => sub {
      my $self = shift;
      return $self->app->repo->teams_count;
    }
  );


  $app->helper(
    num_tags => sub {
      my $self = shift;
      my $type = shift // 1;
      return scalar $self->app->repo->tags_filter( sub { $_->type == $type } );
    }
  );

  $app->helper(
    num_pubs_for_year => sub {
      my $self = shift;
      my $year = shift;
      return 0 unless defined $year;

      return
        scalar grep { defined $_->year and $_->year == $year and $_->hidden == 0 }
        $self->app->repo->entries_all;
    }
  );




  $app->helper(
    num_pubs_for_author_and_tag => sub {
      my $self   = shift;
      my $author = shift;
      my $tag    = shift;

      return
        scalar $author->authorships_filter( sub { defined $_ and defined $_->entry and $_->entry->has_tag($tag) } );
    }
  );

  $app->helper(
    get_recent_years_arr => sub {
      my $self = shift;

      my @arr = grep { defined $_ } map { $_->year } $self->app->repo->entries_all;
      @arr = uniq @arr;
      @arr = sort { $b <=> $a } @arr;
      my $max = scalar @arr;
      $max = 10 if $max > 10;
      return @arr[ 0 .. $max-1 ];
    }
  );

  $app->helper(
    num_entries_for_author => sub {
      my $self   = shift;
      my $author = shift;

      return $author->authorships_count;
    }
  );

  $app->helper(
    num_talks_for_author => sub {
      my $self   = shift;
      my $author = shift;

      return scalar $author->authorships_filter( sub { $_->entry->is_talk } ) // 0;
    }
  );

  $app->helper(
    num_papers_for_author => sub {
      my $self   = shift;
      my $author = shift;
      return scalar $author->authorships_filter( sub { $_->entry->is_paper } ) // 0;
    }
  );


  $app->helper(
    num_pubs_for_tag => sub {
      my $self = shift;
      my $tag  = shift;
      return $tag->labelings_count // 0;
    }
  );

}

1;
