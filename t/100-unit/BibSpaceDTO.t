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

subtest 'Type Objects Should have arrays serialized properly' => sub {
  my $type = $self->app->entityFactory->new_Type(our_type => "test");
  is($type->get_first_bibtex_type, undef);
  $type->bibtexTypes_add("Article");
  is($type->get_first_bibtex_type, 'Article');

  use JSON -convert_blessed_universally;
  my $json_obj = JSON->new->convert_blessed->utf8->pretty;
  my $jStr     = $json_obj->encode($type);

  unlike(
    $jStr,
    qr/bibtexTypes" : \[\]/,
    "JSON should not contain empty 'bibtexTypes' arrays"
  );
  like(
    $jStr,
    qr/bibtexTypes" : \[\W*Article\W*\]/s,
    "JSON should contain 'Article' in the 'bibtexTypes' array"
  );

# unlike($jsonString, qr/bibtexTypes" : \[\]/, "JSON should not contain empty 'bibtexTypes' arrays");
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

  $decodedDTO = $bibspaceDTOObject->toLayeredRepo(
    $jsonString,
    $self->repo->lr->uidProvider,
    $self->repo->lr->preferences
  );
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
my $singleEntryJSON = <<'EOS';
{
   "formatVersion" : "1",
   "dateTimeFormat" : "%Y-%m-%dT%T",
   "data" : {
      "Entry" : [
         {
            "html" : "SPEC.\nSPECjms2007 - First industry-standard benchmark for enterprise messaging servers (JMS&nbsp;1.1).\nStandard Performance Evaluation Corporation, October 2007.\n<b>SPECtacular Performance Award</b>.\n[&nbsp;<a class=\"bib-preview-a\" onclick=\"showAbstract('bib-of-sp2007-SPEC-SPECjms2007')\">bib</a>&nbsp;|&nbsp;<a href=\"http://www.spec.org/jms2007/\" target=\"_blank\">http</a>\n&nbsp;]\n<div id=\"bib-of-sp2007-SPEC-SPECjms2007\" class=\"inline-bib\" style=\"display:none;\"><pre>@misc{sp2007-SPEC-SPECjms2007,\n  author = {SPEC},\n  howpublished = {Standard Performance Evaluation Corporation},\n  month = {October},\n  note = {<b>SPECtacular Performance Award</b>},\n  title = {{SPECjms2007 - First industry-standard benchmark for enterprise messaging servers (JMS~1.1).}},\n  url = {http://www.spec.org/jms2007/},\n  year = {2007},\n}\n\n</pre></div>",
            "_bibtex_type" : "misc",
            "hidden" : 0,
            "bibtex_key" : "sp2007-SPEC-SPECjms2007",
            "month" : 10,
            "html_bib" : "<a name=\"sp2007-SPEC-SPECjms2007\"></a><pre>\n@misc{sp2007-SPEC-SPECjms2007,\n  author = {SPEC},\n  howpublished = {Standard Performance Evaluation Corporation},\n  month = {October},\n  note = {<b>SPECtacular Performance Award</b>},\n  title = {{SPECjms2007 - First industry-standard benchmark for enterprise messaging servers (JMS~1.1).}},\n  url = {<a target=\"blank\" href=\"http://www.spec.org/jms2007/\">http://www.spec.org/jms2007/</a>},\n  year = {2007}\n}\n</pre>\n\n",
            "bib" : "@misc{sp2007-SPEC-SPECjms2007,\n  author = {SPEC},\n  howpublished = {Standard Performance Evaluation Corporation},\n  month = {October},\n  note = {<b>SPECtacular Performance Award</b>},\n  title = {{SPECjms2007 - First industry-standard benchmark for enterprise messaging servers (JMS~1.1).}},\n  url = {http://www.spec.org/jms2007/},\n  year = {2007},\n}\n\n",
            "old_mysql_id" : 584,
            "creation_time" : "2017-02-08T17:53:53",
            "abstract" : null,
            "year" : 2007,
            "entry_type" : "paper",
            "id" : 584,
            "need_html_regen" : 0,
            "title" : "{SPECjms2007 - First industry-standard benchmark for enterprise messaging servers (JMS~1.1).}",
            "modified_time" : "2017-02-08T02:00:03"
         }
      ]
   }
}
EOS

subtest 'DTO restore Entry from JSON and check blessing to DateTime' => sub {
  use Try::Tiny;
  my $decodedJson;
  try {
    $decodedJson = JSON->new->decode($singleEntryJSON);
  }
  finally {
    # Just mute errors
  };
  my $decodedDTO;
  lives_ok {
    $decodedDTO = bless(JSON->new->decode($jsonString), 'BibSpaceDTO')
  }
  "Json string should be blessable into BibSpaceDTO class";

  # Creates DTO. Requires repo only for uid provider and preferences
  $decodedDTO = $bibspaceDTOObject->toLayeredRepo(
    $singleEntryJSON,
    $self->repo->lr->uidProvider,
    $self->repo->lr->preferences
  );
  isa_ok($decodedDTO, 'BibSpaceDTO',
    "Decoded class should be BibSpaceDTO, but is " . ref $decodedDTO);
  is(
    ref $decodedDTO,
    ref $bibspaceDTOObject,
    "Obj type should be of type " . ref $bibspaceDTOObject
  );
  is(ref $decodedDTO->data, 'HASH', "->data type should be HASH");

  isa_ok($decodedDTO->data, 'HASH', "Bad class, " . ref $decodedDTO->data);

  note("Testing collection holding objects of type Entry");
  my $value = $decodedDTO->data->{'Entry'};
  is(ref $value, 'ARRAY', "->data->{'Entry'} should be ARRAY");

  my $obj = $value->[0];
  is(ref $obj, 'Entry', "->data->{'Entry'}->[0] should be Entry");
  is(ref $obj->creation_time,
    'DateTime', "->data->{'Entry'}->[0]->creation_time should be DateTime");
};

done_testing();
