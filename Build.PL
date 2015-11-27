use Module::Build::Mojolicious clean_install => 1;
my $builder = Module::Build::Mojolicious->new(
module_name => 'test',
dist_author => 'me,
license => 'perl',
configure_requires => {
  'Module::Build::Mojolicious' => 0,
  'Module::Build' => 0.38,
},
requires => {
                'File::Find::Rule' => 0,
                'File::MMagic' => 0,
                'Mojolicious' => 0,
                'Mojolicious::Plugin::Authorization' => 0,
                'Crypt::Blowfish' => 0,
                'Experimental' => 0,
            },

share_dir => 'lib/Jacaranda/files',
);

$builder->create_build_script;