use Test::More;
use Module::Build;
use Try::Tiny;
use URI::bolt;
use Cwd qw/getcwd/;
use Neo4j::Bolt;
use strict;

my $build;
try {
  $build = Module::Build->current();
} catch {
  my $d = getcwd;
  chdir '..';
  $build = Module::Build->current();
  chdir $d;
};

unless (defined $build) {
  plan skip_all => "No build context. Run tests with ./Build test.";
}

unless (defined $build->notes('db_url')) {
  plan skip_all => "Local db tests not requested.";
}

my $url = URI->new($build->notes('db_url'));

if ($build->notes('db_user')) {
  $url->userinfo($build->notes('db_user').':'.$build->notes('db_pass'));
}

ok my $badcxn = Neo4j::Bolt->connect("bolt://localhost:16444");
ok !$badcxn->connected;
$badcxn->run_query("match (a) return count(a)");
like $badcxn->errmsg, qr/Not connected/, "client error msg correct";

ok my $cxn = Neo4j::Bolt->connect($url->as_string);
unless ($cxn->connected) {
  diag $cxn->errmsg;
}

SKIP: {
  skip "Couldn't connect to server", 1 unless $cxn->connected;
  ok my $stream = $cxn->run_query(
    "MATCH (a) RETURN labels(a) piece of crap doesn't work",
   ), 'label count query';
  ok !$stream->success, "Not Succeeded";
  ok $stream->failure, "Failure";
  like $stream->server_errcode, qr/SyntaxError/, "got syntax error code";

  $cxn = Neo4j::Bolt->connect('snarf://localhost:7687');
  is $cxn->errnum, -12, "got error";
  like $cxn->errmsg, qr/scheme/, "got errmsg";
}

done_testing;

