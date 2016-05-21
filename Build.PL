use strict;
use warnings;
use Module::Build::Mojolicious clean_install => 1;

my $builder = Module::Build::Mojolicious->new(
	module_name         => 'BibSpace',
  license             => 'perl',
  version							=> '0.4',
  dist_abstract       => 'BibSpace is a system to manage Bibtex references for authors and research groups.',
  dist_author         => 'Piotr Rygielski <piotr@linux.pl>',                                              
	configure_requires => {
    'Module::Build' => 0.38,
    'Module::Build::Mojolicious' => 0,
  },
	requires => {
		'Mojolicious' => 0,
		'DBD::mysql' => 0,
		'Module::Build::Mojolicious' => 0,
		'Time::Piece' => 0,
		'Data::Dumper' => 0,
		'Crypt::Eksblowfish::Bcrypt' => 0,
		'Cwd' => 0,
		'File::Find' => 0,
		'DateTime' => 0,
		'File::Copy' => 0,
		'File::ShareDir' => 0,
		'Scalar::Util' => 0,
		'utf8' => 0,
		'File::Slurp' => 0,
		'DBI' => 0,
		'Exporter' => 0,
		'Set::Scalar' => 0,
		'Session::Token' => 0,
		'LWP::UserAgent' => 0,
		'Text::BibTeX' => 0,
		'HTML::TagCloud::Sortable' => 0,
		'Crypt::Random' => 0,
		'Test::Differences' => 0,
		'Test::MockModule' => 0,
		'WWW::Mailgun' => 0,
		'Mojolicious::Plugin::RenderFile' => 0,
		'Path::Tiny' => 0,
	},
	share_dir => 'lib/BibSpace/files',
  meta_merge => {
		resources  => {
    	repository => "https://github.com/vikin91/BibSpace",
      bugtracker => "https://github.com/vikin91/BibSpace/issues",
    },
    no_index => {
    	file      => [ 'README.md' ],
    },
	});

$builder->create_build_script();