use Module::Build::Mojolicious clean_install => 1;
my $builder = Module::Build::Mojolicious->new(
module_name => 'Hex64Publications',
dist_author => 'me',
license => 'perl',
configure_requires => {
  'Module::Build::Mojolicious' => 0,
  'Module::Build' => 0.38,
},
requires => {
                'Mojolicious' => 0,
                'Time::Piece' => 0,
                'Data::Dumper' => 0,
                'Crypt::Eksblowfish::Bcrypt' => 0,
                'Cwd' => 0,
                'File::Find' => 0,
                'DateTime' => 0,
                'File::Copy' => 0,
                'Scalar::Util' => 0,
                'utf8' => 0,
                'File::Slurp' => 0,
                'DBI' => 0,
                'Exporter' => 0,
                'Set::Scalar' => 0,
                'Session::Token' => 0,
                'LWP::UserAgent' => 0,
                'Net::Address::IP::Local' => 0,
                'Text::BibTeX' => 0,
                'HTML::TagCloud::Sortable' => 0,
                'Crypt::Random' => 0,
                'Test::Differences' => 0,
                'Test::MockModule' => 0,
                'WWW::Mailgun' => 0,
            },

share_dir => 'lib/Hex64Publications/files',
);

$builder->create_build_script;


