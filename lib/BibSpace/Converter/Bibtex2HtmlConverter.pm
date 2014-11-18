package Bibtex2HtmlConverter;

use BibSpace::Model::Entry;
use BibSpace::Functions::Core;

use List::MoreUtils qw(any uniq);

use Path::Tiny;
use File::Spec;

use Data::Dumper;
use utf8;
use Text::BibTeX;
use v5.16;

use Try::Tiny;
use TeX::Encode;
use Encode;

use Moose;
use Moose::Util::TypeConstraints;
use BibSpace::Util::ILogger;
use BibSpace::Converter::IHtmlBibtexConverter;
with 'IHtmlBibtexConverter';

has 'logger' => (is => 'ro', does => 'ILogger', required => 1);
has 'bst'    => (is => 'rw', isa  => 'Maybe[Str]');
has 'html'   => (is => 'rw', isa  => 'Maybe[Str]');
has 'warnings' =>
  (is => 'rw', isa => 'Maybe[ArrayRef[Str]]', default => sub { [] });

sub set_template {
  my ($self, $template) = @_;
  $self->bst($template);
}

sub convert {
  my ($self, $bib, $bst) = @_;
  $bst ||= $self->bst;
  die "Template not provided" unless $bst and -e $bst;
  my $tmp_file_pattern = 'old_bibtex_converter_temp';

  my $tmp_dir = Path::Tiny->new(File::Spec->tmpdir());
  my $cmd_output_file
    = Path::Tiny->new($tmp_dir, $tmp_file_pattern . '.cmd_output.txt');
  my $inputFile  = Path::Tiny->new($tmp_dir, $tmp_file_pattern . '.input.bib');
  my $outputFile = Path::Tiny->new($tmp_dir, $tmp_file_pattern . '.out');

  # say "tmp_dir ".$tmp_dir;
  # say "cmd_output_file ".$cmd_output_file;
  # say "inputFile ".$inputFile;
  # say "outputFile ".$outputFile;

  $inputFile->append_utf8({truncate => 1}, $bib);    # write file

  $bst =~ s/\.bst$//g;    # because bibtex2html doesn't want the extension

  # processes 100 entries in 11 seconds - requires to write input_file
  my $bibtex2html_command
    = "bibtex2html -s "
    . $bst
    . " -nf slides slides -d -r --revkeys -no-keywords -no-header -nokeys --nodoc -no-footer -o $outputFile $inputFile";

# processes 100 entries in 11 seconds - gives input via stdin, stores output to file
# echo escaping problems!!
# my $bibtex2html_command
#     = "echo -n '\Q$bib\E' | bibtex2html -s "
#     . $bst
#     . " -nf slides slides -d -r --revkeys -no-keywords -no-header -nokeys --nodoc -no-footer -o $outputFile";

# processes 100 entries in 11 seconds - gives input via stdin and reads output via stdout
# my $bibtex2html_command
#     = "echo \"$bib\" | bibtex2html -s "
#     . $bst
#     . " -nf slides slides -d -r --revkeys -no-keywords -no-header -nokeys --nodoc -no-footer ";

  my $syscommand
    = "TMPDIR=$tmp_dir "
    . $bibtex2html_command . ' &> '
    . $cmd_output_file->absolute;

  # say "=================\n $syscommand\n =================";

  my $command_output;
  try {
    $command_output = qx($syscommand);
  }
  catch {
    warn "Cannot execute command '$syscommand'. Reason $_ ";
  };

  # clean warnings
  $self->warnings([]);

  # search for warnings and errors
  foreach my $line ($cmd_output_file->lines) {
    if ($line =~ m/^Warning/i or $line =~ m/^Error/i) {
      push @{$self->warnings}, $line;
    }
  }

  my $file_html = $tmp_dir->child($tmp_file_pattern . '.out.html')->slurp;

  # my $html = $command_output;

  # say "=============input -o file: $file_html";
  # say "=============input stdout: $result";

  my $html_tuned_file = tune_html_old($file_html, $bib, "key");

  # my $html_tuned = tune_html_old( $html, $bib, "key" );

  # say "=============tuned file: $html_tuned_file";
  # say "=============tuned out: $html_tuned";

  $self->html($html_tuned_file);

}

sub get_html {
  my $self = shift;
  $self->html;
}

sub get_warnings {
  my $self = shift;
  return @{$self->warnings};
}

sub tune_html_old {
  my $html = shift;
  my $bib  = shift;
  my $key  = shift // 'key';

  my $htmlbib = $bib;
  my $s       = $html;

  $s =~ s/out_bib.html#(.*)/\/publications\/get\/bibtex\/$1/g;

  # FROM .pdf">.pdf</a>&nbsp;]
  # TO   .pdf" target="blank">.pdf</a>&nbsp;]
  # $s =~ s/.pdf">/.pdf" target="blank">/g;

  $s =~ s/>.pdf<\/a>/ target="blank">.pdf<\/a>/g;
  $s =~ s/>slides<\/a>/ target="blank">slides<\/a>/g;
  $s =~ s/>http<\/a>/ target="blank">http<\/a>/g;
  $s =~ s/>.http<\/a>/ target="blank">http<\/a>/g;
  $s =~ s/>DOI<\/a>/ target="blank">DOI<\/a>/g;

  $s =~ s/<a (.*)>bib<\/a>/BIB_LINK_ID/g;

  # # replace &lt; and &gt; b< '<' and '>' in Samuel's files.
  # sed 's_\&lt;_<_g' $FILE > $TMP && mv -f $TMP $FILE
  # sed 's_\&gt;_>_g' $FILE > $TMP && mv -f $TMP $FILE
  $s =~ s/\&lt;/</g;
  $s =~ s/\&gt;/>/g;

# ### insert JavaScript hrefs to show/hide abstracts on click ###
# #replaces every newline command with <NeueZeile> to insert the Abstract link in the next step properly
# perl -p -i -e "s/\n/<NeueZeile>/g" $FILE
  $s =~ s/\n/<NeueZeile>/g;

# #inserts the link to javascript
# sed 's_\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">_\&nbsp;\|\&nbsp;<a href=\"javascript:showAbstract(this);\" onclick=\"showAbstract(this)\">Abstract</a><noscript> (JavaScript required!)</noscript>\&nbsp;\]<div style=\"display:none;\"><blockquote id=\"abstractBQ\">_g' $FILE > $TMP && mv -f $TMP $FILE
# sed 's_</font></blockquote><NeueZeile><p>_</blockquote></div>_g' $FILE > $TMP && mv -f $TMP $FILE
# $s =~ s/\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">/\&nbsp;\|\&nbsp;<a href=\"javascript:showAbstract(this);\" onclick=\"showAbstract(this)\">Abstract<\/a><noscript> (JavaScript required!)<\/noscript>\&nbsp;\]<div style=\"display:none;\"><blockquote id=\"abstractBQ\">/g;

#$s =~ s/\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">/\&nbsp;\|\&nbsp;<a class="abstract-a" onclick=\"showAbstract(\'$key\')\">Abstract<\/a>\&nbsp; \]<div id=\"$key\" style=\"display:none;\"><blockquote id=\"abstractBQ\">/g;
  $s
    =~ s/\&nbsp;\]<NeueZeile><blockquote><font size=\"-1\">/\&nbsp;\|\&nbsp;<a class="abstract-a" onclick=\"showAbstract(\'$key\')\">Abstract<\/a>\&nbsp; \] <div id=\"$key\" style=\"display:none;\"><blockquote class=\"abstractBQ\">/g;
  $s =~ s/<\/font><\/blockquote><NeueZeile><p>/<\/blockquote><\/div>/g;

  #inserting bib DIV marker
  $s =~ s/\&nbsp;\]/\&nbsp; \]/g;
  $s =~ s/\&nbsp; \]/\&nbsp; \] BIB_DIV_ID/g;

  $key =~ s/\./_/g;

  # handling BIB_DIV_ID marker
  $s
    =~ s/BIB_DIV_ID/<div id="bib-of-$key" class="inline-bib" style=\"display:none;\"><pre>$htmlbib<\/pre><\/div>/g;

  # handling BIB_LINK_ID marker
  $s
    =~ s/BIB_LINK_ID/<a class="abstract-a" onclick=\"showAbstract(\'bib-of-$key\')\">bib<\/a>/g;

  # #undo the <NeueZeile> insertions
  # perl -p -i -e "s/<NeueZeile>/\n/g" $FILE
  $s =~ s/<NeueZeile>/\n/g;

  $s =~ s/(\s)\s+/$1/g;    # !!! TEST

  $s =~ s/<p>//g;
  $s =~ s/<\/p>//g;

  $s =~ s/<a name="(.*)"><\/a>//g;

  # $s =~ s/<a name=/<a id=/g;

  $s =~ s/\&amp /\&amp; /g;

  return $s;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
