package URI::bolt;
 
require URI::_server;
@ISA=qw(URI::_server);
 
use strict;
use warnings;
 
sub default_port { 7687 }
 
1;
