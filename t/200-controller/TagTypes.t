use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use BibSpace;
use BibSpace::Functions::Core;

my $admin_user = Test::Mojo->new('BibSpace');
$admin_user->post_ok(
  '/do_login' => {Accept => '*/*'},
  form        => {user   => 'pub_admin', pass => 'asdf'}
);

my $self       = $admin_user->app;
my $app_config = $admin_user->app->config;
$admin_user->ua->max_redirects(3);

use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

subtest "Add new tag type" => sub {

  my $selector1 = 'span[class$=tag-type-name tag-type-name-test-tag-type-1]';
  my $selector2
    = 'span[class$=tag-type-name tag-type-name-tag_type_with_whitespace]';

  $admin_user->post_ok(
    $self->url_for('add_tag_type_post') => form => {
      new_name    => "test-tag-type-1",
      new_comment => "testing adding tag types"
    }
  )->element_exists($selector1)->text_like($selector1 => qr/test-tag-type-1/);

  $admin_user->post_ok(
    $self->url_for('add_tag_type_post') => form => {
      new_name    => "tag type with whitespace",
      new_comment => "testing adding tag types with whitespaces"
    }
  )->element_exists($selector2)
    ->text_like($selector2 => qr/tag type with whitespace/);
};

subtest "Attempt Delete protected tag type" => sub {

  my $selector1 = 'span[class$=tag-type-id tag-type-id-1]';
  my $selector2 = 'span[class$=tag-type-id tag-type-id-2]';

  # this should be verb: DELETE
  $admin_user->get_ok($self->url_for('delete_tag_type', id => 1))
    ->element_exists($selector1)->text_like($selector1 => qr/1/)
    ->element_exists($selector2)->text_like($selector2 => qr/2/)
    ->element_exists('div[class$=alert alert-warning]')
    ->text_like('div[class$=alert alert-warning]' =>
      qr/Tag Types 1 or 2 are essential and cannot be deleted/);

  $admin_user->get_ok($self->url_for('delete_tag_type', id => 2))
    ->element_exists($selector1)->text_like($selector1 => qr/1/)
    ->element_exists($selector2)->text_like($selector2 => qr/2/)
    ->element_exists('div[class$=alert alert-warning]')
    ->text_like('div[class$=alert alert-warning]' =>
      qr/Tag Types 1 or 2 are essential and cannot be deleted/);
};

subtest "Delete regular tag type" => sub {

  my $tt1
    = $self->app->repo->tagTypes_find(sub { $_->name eq "test-tag-type-1" });
  ok($tt1, "Found a tag-type object");

  # this should be verb: DELETE
  my $selector = 'span[class$=tag-type-id tag-type-id-' . $tt1->id . ']';

  $admin_user->get_ok($self->url_for('delete_tag_type', id => $tt1->id))
    ->element_exists_not($selector)
    ->element_exists('div[class$=alert alert-success]')
    ->text_like('div[class$=alert alert-success]' => qr/Tag type deleted/);
};

subtest "Edit regular tag type" => sub {

  my $tt1 = $self->app->repo->tagTypes_find(
    sub { $_->name eq "tag type with whitespace" });
  ok($tt1, "Found a tag-type object");
  my $tt1_id = $tt1->id;

  # this should be verb: PUT
  # GET
  $admin_user->get_ok($self->url_for('edit_tag_type', id => $tt1->id))
    ->text_like('label' => qr/Edit tag type/)
    ->element_exists('input[id$=new_name]')
    ->element_exists('input[id$=new_comment]');

  # POST
  my $selector_id   = 'span[class$=tag-type-id tag-type-id-' . $tt1->id . ']';
  my $selector_name = 'span[class$=tag-type-name tag-type-name-fizz-buzz]';

  $admin_user->post_ok(
    $self->url_for('edit_tag_type', id => $tt1->id) => form =>
      {new_name => "fizz-buzz", new_comment => "comment-fizz-buzz"})
    ->element_exists($selector_id)->element_exists($selector_name)
    ->text_like($selector_id   => qr/$tt1_id/)
    ->text_like($selector_name => qr/fizz-buzz/);
};

done_testing();
