use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Test::Mojo;

my $t_logged_in = Test::Mojo->new('BibSpace');
$t_logged_in->post_ok(
  '/do_login' => {Accept => '*/*'},
  form        => {user   => 'pub_admin', pass => 'asdf'}
);
my $self = $t_logged_in->app;
use BibSpace::TestManager;
TestManager->apply_fixture($self->app);

use JSON -convert_blessed_universally;

my $bibspaceDTOObject = BibSpaceDTO->fromLayeredRepo($self->repo);
my $jsonString        = $bibspaceDTOObject->toJSON();

subtest 'DTO  create' => sub {
  ok($jsonString, "Shall produce non-empty string");
  lives_ok { JSON->new->decode($jsonString) }
  "Json string should be valid - decodable";
  ok(JSON->new->decode($jsonString),
    "Json string should return non-undef object after decode");
  lives_ok {
    bless(JSON->new->decode($jsonString), 'BibSpaceDTO')
  }
  "JSON string should be blessable back to BibSpaceDTO";
};

subtest 'DTO  restore from JSON' => sub {
  use Try::Tiny;
  my $decodedJson;
  try {
    $decodedJson = JSON->new->decode($jsonString);
  }
  finally {
    # Just mute errors
  };
  my $decodedDTO;
  lives_ok {
    $decodedDTO = bless(JSON->new->decode($jsonString), 'BibSpaceDTO')
  }
  "Json string should be blessable into BibSpaceDTO class";

  $decodedDTO = $bibspaceDTOObject->toLayeredRepo($jsonString, $self->repo);
  isa_ok($decodedDTO, 'BibSpaceDTO',
    "Decoded class should be BibSpaceDTO, but is " . ref $decodedDTO);
  is(
    ref $decodedDTO,
    ref $bibspaceDTOObject,
    "Obj type should be " . ref $bibspaceDTOObject
  );
  is(
    ref $decodedDTO->data,
    ref $bibspaceDTOObject->data,
    "->data type should be " . ref $bibspaceDTOObject->data
  );

  isa_ok($decodedDTO->data, 'HASH', "Bad class, " . ref $decodedDTO->data);

  for my $entity (keys %{$decodedDTO->data}) {
    note("Testing collection holding objects of type $entity");
    my $value         = $decodedDTO->data->{$entity};
    my $expectedValue = $bibspaceDTOObject->data->{$entity};
    is(
      ref $value,
      ref $expectedValue,
      "->data->{$entity} should be " . ref $expectedValue
    );

    # FIXME: Assume that there is at least 1 object of each type stored
    my $obj   = $value->[0];
    my $exObj = $expectedValue->[0];
    is(ref $obj, ref $exObj, "->data->{$entity}->[0] should be " . ref $exObj);
  }

  # Additional test for entity if further blessing is needed
# TODO: {
#     local $TODO = "Do not bless but use constructor instead!";
  my $oTest     = $decodedDTO->data->{'Entry'}->[0]->creation_time;
  my $oExpected = $bibspaceDTOObject->data->{'Entry'}->[0]->creation_time;
  is(
    ref $oTest,
    ref $oExpected,
    "->data->{Entry}->[0]->creation_time should be " . ref $oExpected
  );

#   }

  # TODO: {
  #     local $TODO = "Do not bless but use constructor instead!";
  #     my $oTest     = $decodedDTO->data->{'Entry'}->[0]->attachments;
  #     my $oExpected = $bibspaceDTOObject->data->{'Entry'}->[0]->attachments;
  #     is(
  #       ref $oTest,
  #       ref $oExpected,
  #       "->data->{Entry}->[0]->attachments should be " . ref $oExpected
  #     );
  #   }
  #
  # TODO: {
  #     local $TODO = "Do not bless but use constructor instead!";
  #     my $oTest     = $decodedDTO->data->{'Entry'}->[0]->title;
  #     my $oExpected = $bibspaceDTOObject->data->{'Entry'}->[0]->title;
  #     is(
  #       ref $oTest,
  #       ref $oExpected,
  #       "->data->{Entry}->[0]->title should be " . ref $oExpected
  #     );
  #   }
};

done_testing();
