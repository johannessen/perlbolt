requires 'Alien::OpenSSL';
requires 'DateTime';
requires 'JSON::PP';
requires 'Neo4j::Client', '0.54';
requires 'Neo4j::Types', '2.00';
requires 'URI';
requires 'XSLoader', '0.14';  # XSLoader::load()
requires 'perl', '5.012';
recommends 'Mozilla::CA';

on configure => sub {
  requires 'Alien::OpenSSL';
  requires 'ExtUtils::MakeMaker', '7.12';
  requires 'Neo4j::Client', '0.54';
  requires 'Try::Tiny';
};

on build => sub {
  requires 'ExtUtils::Typemaps', '3.24';  # embedded typemap
};

on test => sub {
  requires 'Carp';
  requires 'Cwd';
  requires 'Encode';
  requires 'Fcntl';
  requires 'File::Spec';
  requires 'IPC::Run';
  requires 'Test::Exception';
  requires 'Test::More';
  requires 'Test::Neo4j::Types', '0.06';
  requires 'blib';
  recommends 'Test::CPAN::Changes';  # 099_cpan_changes.t
  recommends 'Test::Pod';  # 098_pod.t
};

on develop => sub {
  requires 'Devel::PPPort', '3.63';
  requires 'Inline::C';  # in t/Boltfile.pm, used via xt/003_stream.t
  #requires 'IPC::Run';  # in t/lib/NeoCon.pm, but not actually used anywhere
  recommends 'Path::Tiny';  # pod2md.PL
  recommends 'Pod::Markdown';  # pod2md.PL
};
