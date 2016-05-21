require 5.010;
use ExtUtils::MakeMaker;

my @scripts = qw(fontsampler pfb2pfa pfa2pfb);
WriteMakefile(
	NAME            => 'BibTeX::BibSpace',
	AUTHOR   => 'Piotr Rygielski <piotr@linux.pl>',
	ABSTRACT => 'BibSpace is a system to manage Bibtex references for authors and research groups web page.',
	VERSION_FROM    => 'lib/BibSpace.pm',
 	PREREQ_PM => { 
 		'Getopt::Long' => 2.00, 
 		'IO' => 0 
 	},
  EXE_FILES => [ "bin/bibspace" ],
  META_MERGE => {
		resources  => {
    	repository => "https://github.com/vikin91/BibSpace",
      bugtracker => "https://github.com/vikin91/BibSpace/issues",
    },
	},
	CONFIGURE_REQUIRES => {
    'Module::Build' => 0.38,
    'Module::Build::Mojolicious' => 0,
    'Module::Build::CleanInstall' => 0,
    'Mojolicious' => 0,
	},
	BUILD_REQUIRES => {
		'Module::CPANfile' => 0,
		'Mojolicious' => 0,
		'FindBin' => 0,
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
		'Mojolicious::Plugin::RenderFile' => 0,
		'Path::Tiny' => 0,
		'IO::Socket::IP' => 0,
		'IO::Socket::SSL' => 0,
		'WWW::Mechanize' => 0,
		},
);
