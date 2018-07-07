
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

my $singleEntryJSON_non_standard_date_time = <<'EOS';
{
   "formatVersion" : "1",
   "dateTimeFormat" : "%Y-%m-%dT%T-STRING",
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
            "creation_time" : "2017-02-08T17:53:53-STRING",
            "abstract" : null,
            "year" : 2007,
            "entry_type" : "paper",
            "id" : 584,
            "need_html_regen" : 0,
            "title" : "{SPECjms2007 - First industry-standard benchmark for enterprise messaging servers (JMS~1.1).}",
            "modified_time" : "2017-02-08T02:00:03-STRING"
         }
      ]
   }
}
EOS

subtest 'DTO restore Entry from JSON and non-standard date-time format' => sub {
  use Try::Tiny;

  # Filling DTO object with data from the system
  my $bibspaceDTOObject = BibSpaceDTO->fromLayeredRepo($self->repo);

  # Serializing DTO object into JSON
  my $jsonString = $bibspaceDTOObject->toJSON();
  my $decodedJson;
  try {
    $decodedJson = JSON->new->decode($singleEntryJSON_non_standard_date_time);
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
  $decodedDTO
    = $bibspaceDTOObject->toLayeredRepo($singleEntryJSON_non_standard_date_time,
    $self->repo);
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
