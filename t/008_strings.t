use strict;
use warnings;
use Test::More;
use Encode ();
use Neo4j::Bolt::NeoValue;

# String encoding, esp. to and from UTF-8

plan tests => 7 + 14;

my ($i, $o, $v);

sub SVf_UTF8 { utf8::is_utf8(shift) ? 'U' : 'B' }
sub to_hex { join ' ', SVf_UTF8($_[0]), map { sprintf "%02x", ord $_ } split //, $_[0] }
sub to_str { my $s = shift; $s =~ s/([[:xdigit:]]{2})/chr(hex($1))/eg; Encode::_utf8_on($s); $s }

# GitHub issue #39
$i = "A\0B";
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
is to_hex($v->_as_perl), to_hex($i), "NUL byte in string";

# GitHub issue #38

# strings with Perl byte semantics shouldn't be treated as Unicode strings
no utf8;
$i = "\x{c4}\x{80}";  # a sequence of two bytes that also happens to be valid UTF-8 for U+0100
eval { Encode::_utf8_off($i) };  # SVf_UTF8 should already be off, but why not try to make sure
$o = $i;
$v = Neo4j::Bolt::NeoValue->_new_from_perl($i);
$v = $v->_as_perl;
isnt to_hex($v), "U 100", "bytes in string";
ok utf8::is_utf8($v), "bytes in string - Neo4j returns UTF-8";

# same for map keys
# (which are strings as well, but use a different code path in CTypeHandlers)
$v = Neo4j::Bolt::NeoValue->_new_from_perl( {$i => 1} );
$v = ( keys %{$v->_as_perl} )[0];
isnt to_hex($v), "U 100", "bytes in map key";
ok utf8::is_utf8($v), "bytes in map key - Neo4j returns UTF-8";
is to_hex($i), to_hex($o), "input SV unchanged";

# Note: The exact result in the tests above depends on the native single
# byte encoding that Perl assumes for this file under "no utf8;". This
# encoding is usually Latin-1 (which would yield "U c4 80"), but could
# be anything else. However, we know "U 100" means that the non-Unicode
# bytes were interpreted as Unicode UTF-8, which is definitely wrong.

# real Unicode char in map key
use utf8;
$i = "\x{100}";
eval { Encode::_utf8_on($i) };  # SVf_UTF8 should already be on, but why not try to make sure
$v = Neo4j::Bolt::NeoValue->_new_from_perl( {$i => 1} );
$v = ( keys %{$v->_as_perl} )[0];
is to_hex($v), to_hex($i), "Unicode char in map key";

# byte sequences that aren't valid UTF-8 shouldn't be treated as such (RFC3629)
my @seq = (
  40   => "B 40",  # valid UTF-8 for U+0040
  C2BD => "U bd",  # valid UTF-8 for U+00BD
  C1   => "B c1",  # invalid byte
  F5   => "B f5",  # invalid byte
  FF   => "B ff",  # invalid byte
  A0   => "B a0",      # unexpected continuation byte
  5885 => "B 58 85",   # unexpected continuation byte
  D0D1 => "B d0 d1",   # non-continuation byte before end of character
  C838 => "B c8 38",   # non-continuation byte before end of character
  EEBB => "B ee bb",   # ending before end of character
  EDBFBF   => "U dfff",    # invalid UTF-8 code point, but allowed in Perl
  F4908080 => "U 110000",  # invalid UTF-8 code point, but allowed in Perl
  F08282AC => "B f0 82 82 ac",  # overlong encoding (for U+20AC)
  C080     => "B c0 80",        # overlong encoding (for U+0000)
);
for (my $k = 0; $k < @seq; ) {
  $i = $seq[$k++];
  $o = $seq[$k++];
  $v = Neo4j::Bolt::NeoValue->_new_from_perl( to_str($i) );
  is to_hex($v->_as_perl), $o, "byte sequence $i";
}

done_testing;
