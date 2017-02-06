requires 'Array::Utils' , '>= 0.0';
requires 'Crypt::Eksblowfish::Bcrypt' , '>= 0.0';
requires 'Crypt::Random' , '>= 0.0';
requires 'Cwd' , '>= 0.0';
requires 'DBD::mysql' , '>= 0.0';
requires 'DBI', '>= 1.619';
requires 'DBIx::Connector' , '>= 0.0';
requires 'Data::Dumper' , '>= 0.0';
requires 'DateTime' , '>= 0.0';
requires 'DateTime::Format::Strptime' , '>= 0.0';
requires 'DateTime::Format::HTTP' , '>= 0.0';
requires 'Exporter' , '>= 0.0';
requires 'File::Spec' , '>= 0.0';
requires 'HTML::TagCloud::Sortable' , '>= 0.0';
requires 'JSON' , '>= 0.0';
requires 'LWP::Protocol::https' , '>= 0.0';
requires 'Module::Build::Mojolicious' , '>= 0.0';
requires 'Module::Build::Mojolicious' , '>= 0.0';
requires 'Module::CPANfile' , '>= 0.0';
requires 'Mojolicious' , '>= 7.22';
requires 'Mojolicious::Plugin::RenderFile' , '>= 0.0';
requires 'Moose' , '>= 0.0';
requires 'MooseX::ClassAttribute' , '>= 0.0';
requires 'MooseX::Singleton' , '>= 0.0';
requires 'MooseX::Storage' , '>= 0.0';
requires 'MooseX::StrictConstructor' , '>= 0.0';
requires 'Path::Tiny' , '>= 0.0';
requires 'Scalar::Util' , '>= 0.0';
requires 'Session::Token' , '>= 0.0';
requires 'Storable' , '>= 0.0';
requires 'TeX::Encode' , '>= 0.0';
requires 'Text::ASCIIMathML' , '>= 0.0';
requires 'Text::BibTeX' , '>= 0.0';
requires 'UUID::Tiny' , '>= 0.0';
requires 'WWW::Mechanize' , '>= 0.0';
requires 'utf8' , '>= 0.0';


on 'test' => sub {
  requires 'Devel::Cover::Report::Coveralls', '>= 0.0';
  requires 'Test::Differences' , '>= 0.0';
  requires 'Test::Exception' , '>= 0.0';
  requires 'Test::MockModule' , '>= 0.0';
  requires 'Test::Pod::Coverage' , '>= 0.0';
};

on 'develop' => sub {
  requires 'Dist::Zilla' , '>= 0.0';
};