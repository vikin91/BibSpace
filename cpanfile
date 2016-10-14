requires 'DBI', '>= 1.619';
requires 'Dist::Zilla' , '>= 0.0';
requires 'Module::Build::Mojolicious' , '>= 0.0';
requires 'Module::CPANfile' , '>= 0.0';
requires 'Mojolicious' , '>= 0.0';
requires 'DBD::mysql' , '>= 0.0';
requires 'Module::Build::Mojolicious' , '>= 0.0';
requires 'Time::Piece' , '>= 0.0';
requires 'Data::Dumper' , '>= 0.0';
requires 'Crypt::Eksblowfish::Bcrypt' , '>= 0.0';
requires 'Cwd' , '>= 0.0';
requires 'File::Find' , '>= 0.0';
requires 'DateTime' , '>= 0.0';
requires 'File::Copy' , '>= 0.0';
requires 'Scalar::Util' , '>= 0.0';
requires 'utf8' , '>= 0.0';
requires 'File::Slurp' , '>= 0.0';
requires 'Exporter' , '>= 0.0';
requires 'Set::Scalar' , '>= 0.0';
requires 'Session::Token' , '>= 0.0';
requires 'LWP::UserAgent' , '>= 0.0';
requires 'Text::BibTeX' , '>= 0.0';
requires 'HTML::TagCloud::Sortable' , '>= 0.0';
requires 'Crypt::Random' , '>= 0.0';
requires 'WWW::Mechanize' , '>= 0.0';
requires 'Mojolicious::Plugin::RenderFile' , '>= 0.0';
requires 'Path::Tiny' , '>= 0.0';
requires 'Moose' , '>= 0.0';
requires 'TeX::Encode' , '>= 0.0';
requires 'Array::Utils' , '>= 0.0';
requires 'File::Spec' , '>= 0.0';
requires 'Text::ASCIIMathML' , '>= 0.0';
requires 'Mojo::Redis2' , '>= 0.0';


on 'test' => sub {
  requires 'Devel::Cover::Report::Coveralls', '>= 0.0';
  requires 'Test::Pod::Coverage' , '>= 0.0';
  requires 'Test::Differences' , '>= 0.0';
  requires 'Test::MockModule' , '>= 0.0';
};

on 'develop' => sub {
  
};