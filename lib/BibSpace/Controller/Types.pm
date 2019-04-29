package BibSpace::Controller::Types;

use Data::Dumper;
use utf8;
use v5.16;    #because of ~~
use strict;
use warnings;

use List::MoreUtils qw(any uniq);
use BibSpace::Functions::Core;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';
use Mojo::Log;

sub all_our {
  my $self = shift;

  my @types
    = sort { $a->our_type cmp $b->our_type } $self->app->repo->types_all;

  $self->stash(otypes => \@types);
  $self->render(template => 'types/types');
}

sub add_type {
  my $self = shift;
  $self->render(template => 'types/add');
}

sub post_add_type {
  my $self     = shift;
  my $new_type = $self->param('new_type');

  my $type = $self->app->entityFactory->new_Type(our_type => $new_type);

  # Databse requires that each type must have at least one bibtex_type
  $type->bibtexTypes_add('dummy');
  $self->app->repo->types_save($type);
  $self->flash(
    msg_type => 'warning',
    message =>
      "Type $new_type has been added and mapped onto dummy bibtex type."
  );
  $self->redirect_to($self->url_for('all_types'));
}

sub manage {
  my $self      = shift;
  my $type_name = $self->param('name');

  my @all  = $self->app->repo->types_all;
  my $type = $self->app->repo->types_find(sub { $_->our_type eq $type_name });

  my @all_our_types         = uniq map { $_->our_type } @all;
  my @all_bibtex_types      = BibSpace::Functions::Core::official_bibtex_types;
  my @assigned_bibtex_types = $type->bibtexTypes_all;

  # # cannot use objects as keysdue to stringification!
  my %types_hash        = map  { $_ => 1 } @assigned_bibtex_types;
  my @unassigned_btypes = grep { not $types_hash{$_} } @all_bibtex_types;

  $self->stash(
    all_otypes        => \@all_our_types,
    unassigned_btypes => \@unassigned_btypes,
    all_btypes        => \@all_bibtex_types,
    assigned_btypes   => \@assigned_bibtex_types,
    type              => $type
  );
  $self->render(template => 'types/manage_types');
}

sub toggle_landing {
  my $self      = shift;
  my $type_name = $self->param('name');
  my $type_obj
    = $self->app->repo->types_find(sub { $_->our_type eq $type_name });

  if ($type_obj->onLanding == 0) {
    $type_obj->onLanding(1);
  }
  else {
    $type_obj->onLanding(0);
  }
  $self->app->repo->types_update($type_obj);

  $self->redirect_to($self->get_referrer);
}

sub post_store_description {
  my $self        = shift;
  my $type_name   = $self->param('our_type');
  my $description = $self->param('new_description');
  my $type_obj
    = $self->app->repo->types_find(sub { $_->our_type eq $type_name });

  if (defined $type_obj and defined $description) {
    $type_obj->description($description);
    $self->app->repo->types_update($type_obj);
  }
  $self->redirect_to($self->url_for('edit_type', name => $type_name));
}

sub delete_type {
  my $self      = shift;
  my $type_name = $self->param('name');

  my $type_obj
    = $self->app->repo->types_find(sub { $_->our_type eq $type_name });
  if ($type_obj and $type_obj->can_be_deleted) {
    $self->app->repo->types_delete($type_obj);

    $self->flash(
      msg_type => 'success',
      message  => "$type_name and its mappings have been deleted."
    );
  }
  else {
    $self->flash(
      msg_type => 'warning',
      message =>
        "$type_name cannot be deleted. Possible reasons: mappings exist or it is native bibtex type."
    );
  }
  $self->redirect_to($self->url_for('all_types'));
}

sub map_types {
  my $self   = shift;
  my $o_type = $self->param('our_type');
  my $b_type = $self->param('bibtex_type');

  my $type_obj = $self->app->repo->types_find(sub { $_->our_type eq $o_type });

  if ((!$o_type) or (!$b_type) or (!$type_obj)) {
    $self->flash(
      message  => "Cannot map. Incomplete input.",
      msg_type => 'danger'
    );
    $self->redirect_to($self->get_referrer);
    return;

  }
  elsif ($type_obj) {
    use List::Util qw(first);
    my $found = first { $_ eq $b_type } official_bibtex_types;
    if ($found) {
      $type_obj->bibtexTypes_add($b_type);
      $self->app->repo->types_update($type_obj);
      $self->flash(message => "Mapping successful!", msg_type => 'success');
    }
    else {
      $self->flash(
        message  => "MAP ERROR: $b_type is not a valid bibtex type!",
        msg_type => 'danger'
      );
    }
  }
  else {
    $self->flash(
      message  => "Cannot map. Type not found.",
      msg_type => 'danger'
    );
  }
  $self->redirect_to($self->url_for('edit_type', name => $o_type));
}

sub unmap_types {
  my $self   = shift;
  my $o_type = $self->param('our_type');
  my $b_type = $self->param('bibtex_type');

  my $type_obj = $self->app->repo->types_find(sub { $_->our_type eq $o_type });

  if ((!$b_type) or (!$type_obj)) {
    $self->flash(
      message  => "Cannot unmap. Incomplete input.",
      msg_type => 'danger'
    );
    $self->redirect_to($self->get_referrer);
    return;

  }
  elsif ($type_obj) {
    my $idx_to_del = $type_obj->bibtexTypes_find_index(sub { $_ eq $b_type });
    if ($idx_to_del > -1) {
      $type_obj->bibtexTypes_delete($idx_to_del);
      $self->app->repo->types_update($type_obj);
      $self->flash(message => "Unmapping successful!", msg_type => 'success');
    }
    else {
      $self->flash(
        message  => "Unmap error: $b_type is not a valid bibtex type!",
        msg_type => 'danger'
      );
    }
  }
  else {
    $self->flash(
      message  => "Cannot unmap. Type not found.",
      msg_type => 'danger'
    );
  }
  $self->redirect_to($self->url_for('edit_type', name => $o_type));
}

1;
