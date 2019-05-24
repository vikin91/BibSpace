package BibStyleConverter;

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

use BibStyle::LocalBibStyle;

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

  my ($bbl_dirty, $dirty_bbl_array_ref, $warnings_arr_ref)
    = _convert_bib_to_bbl($bib, $bst);
  $self->warnings($warnings_arr_ref);

  # stateless call
  my $clean_bbl = _clean_bbl($dirty_bbl_array_ref);
  my $html_code = _add_html_links($clean_bbl, $bib);
  $self->html($html_code);
}

sub get_html {
  my $self = shift;
  $self->html;
}

sub get_warnings {
  my $self = shift;
  return @{$self->warnings};
}

sub _convert_bib_to_bbl {
  my ($input_bib, $bst_file_path) = @_;

  my $bibstyle = BibStyle::LocalBibStyle->new(); #Text::BibTeX::BibStyle->new();
  die "Cannot find bst file under: $bst_file_path  ." if !-e $bst_file_path;
  $bibstyle->read_bibstyle($bst_file_path);

  my $bbl = $bibstyle->execute([], $input_bib);
  my $out = $bibstyle->get_output();

  my @bibstyle_output = @{$bibstyle->{output}};

  my $warnings_arr_ref = $bibstyle->{warnings};

  my $bbl_dirty           = join '', @bibstyle_output;
  my $dirty_bbl_array_ref = \@bibstyle_output;

  return ($bbl_dirty, $dirty_bbl_array_ref, $warnings_arr_ref);
}

sub _clean_bbl {
  my ($bbl_arr_ref) = @_;

  my @arr = @{$bbl_arr_ref};
  my @useful_lines;

  foreach my $f (@arr) {
    chomp $f;

# fix strange commas
# before: J\'{o}akim von Kistowski, , Hansfried Block, , John Beckett, , Cloyce Spradling, , Klaus-Dieter Lange, , and Samuel Kounev, .
# after: J\'{o}akim von Kistowski, Hansfried Block, John Beckett, Cloyce Spradling, Klaus-Dieter Lange, and Samuel Kounev.
    $f =~ s/(\w+),\s+,/$1,/g;
    $f =~ s/(\w+),\s+([\.,])/$1$2/g;

    if ($f =~ m/^\\begin/ or $f =~ m/^\\end/) {

      # say "BB".$f;
    }
    elsif ($f =~ m/\\bibitem/) {

      # say "II".$f;
      push @useful_lines, $f;
    }
    elsif ($f =~ m/^\s*$/) {    # line containing only whitespaces
      ;
    }
    else {
      push @useful_lines, $f;
    }
  }

  my $useful_str = join '', @useful_lines;
  my $s          = $useful_str;

  # say "\nXXXX1\n".$s."\nXXXX\n";

  $s =~ s/\\newblock/\n\\newblock/g
    ;    # every newblock = newline in bbl (but not in html!)
  $s =~ s/\\bibitem\{([^\}]*)\}/\\bibitem\{$1\}\n/
    ;    # new line after the bibtex key

  my ($bibtex_key, $rest)
    = $s
    =~ m/\\bibitem\{([^\}.]*)\}(.*)/;    # match until the first closing bracket
      # extract the bibtex key and the rest - just in case you need it

  $s =~ s/\\bibitem\{([^\}]*)\}\n?//;    #remove first line with bibitem
  $s =~ s/\\newblock\s+//g;              # remove newblocks

# nested parenthesis cannot be handled with regexp :(
# I use this because it counts brackets!
# string_replace_with_counting($s, $opening, $closing, $avoid_l, $avoid_r, $opening_replace, $closing_replace)
  $s = string_replace_with_counting($s, '{\\em', '}', '{', '}',
    '<span class="em">', '</span>');

  # if there are more (what is very rare), just ignore
  $s = string_replace_with_counting($s, '{\\em', '}', '{', '}', '', '');

# find all that is between {}, count all pairs of {} replace the outermost with nothing
# does {zzz {aaa} ggg} => zzz {aaa} ggg

  $s = string_replace_with_counting($s, '\\url{', '}', '{', '}',
    '<span class="url">', '</span>');

 # and here are the custom replacement functions in case something goes wrong...
  $s = german_letters_latex_to_html($s);
  $s = polish_letters_latex_to_html($s);
  $s = other_letters_latex_to_html($s);

  $s = str_replace_handle_tilde($s);

  my $new_s = "";
  $new_s = string_replace_with_counting($s, '{', '}', '{', '}', '', '');
  while ($new_s ne $s) {
    $s     = $new_s;
    $new_s = string_replace_with_counting($s, '{', '}', '{', '}', '', '');
  }

  $s = str_replace_as_pod_latex($s)
    ;    # this should catch everything but it doesn't

  $s =~ s!\\%!&#37;!g;    # replace % escape
  $s =~ s!\\&!&#38;!g;    # replace & escape

  return $s;
}

sub _add_html_links {
  my ($bbl_clean, $bib) = @_;

  my $s = $bbl_clean;

  my $entry = new Text::BibTeX::Entry();
  $entry->parse_s($bib);
  return -1 unless $entry->parse_ok;

  my $entry_hidden_abstract = new Text::BibTeX::Entry();
  $entry_hidden_abstract->parse_s($bib);
  $entry_hidden_abstract->delete('abstract');
  my $bib_hidden_abstract = $entry_hidden_abstract->print_s;

  my $bibtex_key = $entry->key;

  $s .= "\n";

  my @code = ();

  if ($entry->exists('pdf')) {
    push @code, build_link('pdf', $entry->get('pdf'));
  }
  if ($entry->exists('slides')) {
    push @code, build_link('slides', $entry->get('slides'));
  }
  if ($entry->exists('doi')) {
    push @code, build_link('DOI', "https://doi.org/" . $entry->get('doi'));
  }
  if ($entry->exists('url')) {
    push @code, build_link('http', $entry->get('url'));
  }

  my $abstract_preview_a;
  my $abstract_preview_div;
  if ($entry->exists('abstract')) {
    my $content = $entry->get('abstract');

# $abstract_preview_a = '<a class="abstract-preview-a" onclick="showAbstract(\'abstract-of-'.$bibtex_key.'\')">abstract</a>';
    $abstract_preview_a
      = '<a class="abstract-preview-link" data-id="'
      . $bibtex_key
      . '">abstract</a>';

# $abstract_preview_div = '<div id="abstract-of-'.$bibtex_key.'" class="inline-bib" style="display:none;"><pre>'.$content.'</pre></div>';

    $abstract_preview_div
      = '<div class="bibspace-entry-abstract" data-id="'
      . $bibtex_key
      . '" class="inline-bib" style="display:none;">';
    $abstract_preview_div .= '<pre>' . $content . '</pre>';
    $abstract_preview_div .= '</div>';

  }

# my $bib_preview_a = '<a class="bib-preview-a" onclick="showAbstract(\'bib-of-'.$bibtex_key.'\')">bib</a>';
  my $bib_preview_a
    = '<a class="bib-preview-link" data-id="' . $bibtex_key . '">bib</a>';

# my $bib_preview_div = '<div id="bib-of-'.$bibtex_key.'" class="inline-bib" style="display:none;"><pre>'.$bib_hidden_abstract.'</pre></div>';
  my $bib_preview_div
    = '<div class="bibspace-entry-bib" data-id="'
    . $bibtex_key
    . '" class="inline-bib" style="display:none;">';
  $bib_preview_div .= '<pre>' . $bib_hidden_abstract . '</pre>';
  $bib_preview_div .= '</div>';

  $s .= "[&nbsp;" . $bib_preview_a;
  $s .= "&nbsp;|&nbsp;" . $abstract_preview_a . "\n"
    if defined $abstract_preview_a;

  while (my $e = shift @code) {
    $s .= "&nbsp;|&nbsp;" . $e . "\n";
  }
  $s .= "&nbsp;]";

  $s =~ s/\|\&nbsp\;\]/\]/g;

  $s .= "\n" . $bib_preview_div;
  $s .= "\n" . $abstract_preview_div if defined $abstract_preview_div;

  $s;
}

sub build_link {
  my $name  = shift;
  my $value = shift;

  return "<a href=\"$value\" target=\"_blank\">$name</a>";

}

####### CORE

sub str_replace_as_pod_latex {
  my $s = shift;

  my %h = %Pod::LaTeX::HTML_Escapes;

  while (my ($html, $tex) = each %h) {
    next if $tex =~ m/^\$/;
    next
      if $html eq
      'verbar';    # because it changes every letter to letter with vertialbar

    next if $tex eq '<';     # we want our html to stay
    next if $tex eq '>';     # we want our html to stay
    next if $tex eq '"';     # we want our html to stay
    next if $tex eq '\'';    # we want our html to stay

    # say "str_replace_as_pod_latex: tex before escaping: '$tex'.";
    # escaping the stuff
    $tex =~ s!\\!\\\\!g;
    $tex =~ s!\{!\\\{!g;
    $tex =~ s!\}!\\\}!g;

    $s =~ s![{}]!!g;    # you need to remove this before decoding...

    # say "tex $tex -> $html" if $html =~ /ouml/;
    # say "BEFORE $s" if $html =~ /ouml/;
    # say "str_replace_as_pod_latex: changing: '$tex' to '&$html;'";
    $s =~ s!$tex!&$html;!g;

    # say "AFTER $s" if $html =~ /ouml/;
    # m/\\texttwosuperior\\{ <-- HERE \\}/ at

  }

  $s;
}

sub str_replace_handle_tilde {
  my $s = shift;
  $s =~ s!~!&nbsp;!g;

  $s;
}

sub polish_letters_latex_to_html {
  my $s = shift;

  $s =~ s!\\k\{A\}!&#260;!g;
  $s =~ s!\\k\{a\}!&#261;!g;
  $s =~ s!\\k\{E\}!&#280;!g;
  $s =~ s!\\k\{e\}!&#281;!g;

  $s =~ s!\\L\{\}!&#321;!g;
  $s =~ s!\\l\{\}!&#322;!g;

  $s =~ s!\{\\L\}!&#321;!g;    # people may have imagination
  $s =~ s!\{\\l\}!&#322;!g;

  $s =~ s!\\\.\{Z\}!&#379;!g;
  $s =~ s!\\\.\{z\}!&#380;!g;

  $s =~ s!\{\\\.Z\}!&#379;!g;    #imagination again
  $s =~ s!\{\\\.z\}!&#380;!g;

#
  # $s = decode('latex', $s); # does not work :(

  # http://www.utf8-chartable.de/unicode-utf8-table.pl

  $s = delatexify($s, '\'', 'Z', '&#377;');
  $s = delatexify($s, '\'', 'z', '&#378;');
  $s = delatexify($s, '\'', 'S', '&#346;');
  $s = delatexify($s, '\'', 's', '&#347;');
  $s = delatexify($s, '\'', 'C', '&#262;');
  $s = delatexify($s, '\'', 'c', '&#263;');
  $s = delatexify($s, '\'', 'N', '&#323;');
  $s = delatexify($s, '\'', 'n', '&#324;');
  $s = delatexify($s, '\'', 'O', '&#211;');
  $s = delatexify($s, '\'', 'o', '&#243;');

  $s;
}

sub german_letters_latex_to_html {
  my $s = shift;

  # say "before replace: $s";

  $s =~ s!\\ss\{\}!&#223;!g;
  $s =~ s!\\ss!&#223;!g;

  $s = delatexify($s, '"', 'A', '&#196;');
  $s = delatexify($s, '"', 'a', '&#228;');
  $s = delatexify($s, '"', 'O', '&#214;');
  $s = delatexify($s, '"', 'o', '&#246;');
  $s = delatexify($s, '"', 'U', '&#220;');
  $s = delatexify($s, '"', 'u', '&#252;');

  $s;
}

sub other_letters_latex_to_html {
  my $s = shift;

  $s = delatexify($s, '\'', 'E', '&#201;')
    ;    # E with accent line pointing to the right
  $s = delatexify($s, '\'', 'e', '&#233;');

  $s = delatexify($s, '\'', 'A', '&#193;');
  $s = delatexify($s, '\'', 'a', '&#225;');

  $s = delatexify($s, '\'', 'I', '&#205;');
  $s = delatexify($s, '\'', 'i', '&#237;');

  $s = delatexify($s, '"', 'E', '&#203;');    # E with two dots (FR)
  $s = delatexify($s, '"', 'e', '&#235;');

  $s = delatexify($s, 'c', 'C', '&#268;');    # C with hacek (CZ)
  $s = delatexify($s, 'c', 'c', '&#269;');

  $s = delatexify($s, 'c', 'S', '&#352;');    # S with hacek (CZ)
  $s = delatexify($s, 'c', 's', '&#353;');

  $s;
}

sub delatexify {
  my ($s, $accent, $src, $dest) = @_;

  $s =~ s!\\$accent\{$src\}!$dest!g;
  $s =~ s!\{\\$accent$src\}!$dest!g;
  $s =~ s!\\\{$accent$src\}!$dest!g;
  $s =~ s!\{$accent$src\}!$dest!g;
  $s =~ s!\\$accent$src!$dest!g;

  $s;
}

=item string_replace_with_counting
  uses counting to do strin replace
  Example:
    single runn of 'string_replace_with_counting' with parameters
      s = aaa{bbb{cc{dd}}}
      opening = {
      closing = }
      avoid_l = {
      avoid_r = }
      opening_replace = ''
      closing replace = ''
    returns: aaa{bbb{ccdd}}
    next run:
    returns: aaa{bbbccdd}
    next run:
    returns: aaabbbccdd
=cut

sub string_replace_with_counting {
  my ($s, $opening, $closing, $avoid_l, $avoid_r, $opening_replace,
    $closing_replace)
    = @_;

  my $opening_len = length $opening;
  my $closing_len = length $closing;

  # $s = 'some szit {\em ddd c {{ ss} ssdfes {ddd} }dssddsw }ee';

# say "======== string_replace_with_counting opening $opening closing $closing  ========";

  my $index_opening = -1;
  my $found_pair    = 0;
  my $index_closing = -1;

  my @str_arr = split //, $s;
  my $max     = scalar @str_arr;

  my $l_brackets = 0;
  my $r_brackets = 0;

  for (my $i = 0; $i < $max and $index_closing == -1; $i++)
  {    # we break when we find the first match
    my $character = $str_arr[$i];

# say "$i - $character - L $l_brackets R $r_brackets == $found_pair" if $opening eq '{';

    if ($found_pair == 1) {

      if ($character eq $avoid_l) {
        $l_brackets++;
      }
      if ($character eq $avoid_r) {
        if ($l_brackets == $r_brackets) {
          $index_closing = $i;
        }
        if ($l_brackets > 0) {
          $r_brackets++;
        }
      }
    }

    # if($character eq '{' and
    #    $i+34 < $max and
    #    $str_arr[$i+1] eq '\\' and
    #    $str_arr[$i+2] eq 'e' and
    #    $str_arr[$i+3] eq 'm')
    if ($found_pair == 0 and substr($s, $i, $opening_len) eq $opening) {
      $index_opening = $i;
      $found_pair    = 1;
    }
  }

  # say "s: $s ";
  # say "index_opening: $index_opening ".$str_arr[$index_opening];
  # say "index_closing: $index_closing ".$str_arr[$index_closing];
  # say "found_pair: $found_pair";

  if ($found_pair == 1) {
    if (
      ($index_opening == -1 and $index_closing == -1)
      or    # both -1 are ok = no {\em ..}
      (
            $index_opening >= 0
        and $index_closing >= 0
        and $index_closing > $index_opening
      )
      )
    {
      substr($s, $index_closing, $closing_len, $closing_replace)
        ;    # first closing beacuse it changes the index!!!
      substr($s, $index_opening, $opening_len, $opening_replace);

    }
    else {
      my $warn
        = "Indices are messed! No change made to string: "
        . substr($s, 0, 30)
        . " ...\n";
      $warn .= "index_opening $index_opening index_closing $index_closing "
        . $index_opening * $index_closing . "\n";
      warn $warn;
    }
  }
  else {
    # say "EM not found in  ".substr($s, 0, 30)." ...\n";
  }

  # say "======== string_replace_with_counting END ========";
  return $s;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
