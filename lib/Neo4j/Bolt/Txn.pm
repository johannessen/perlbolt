package Neo4j::Bolt::Txn;
# use Neo4j::Client;

BEGIN {
  our $VERSION = "0.40";
  require Neo4j::Bolt::TypeHandlersC;
}

require XSLoader;
XSLoader::load();

# use Inline 'global';
# use Inline P => Config => LIBS => Neo4j::Client->libs,
#   INC => Neo4j::Client->cflags,
#   version => $VERSION,
#   name => __PACKAGE__;

sub errnum { shift->errnum_ }
sub errmsg { shift->errmsg_ }

sub new {
  my $class = shift;
  my ($cxn, $params) = @_;
  $params //= {};
  unless ($cxn && (ref($cxn) =~ /Cxn$/)) {
    die "Arg 1 should be a Neo4j::Bolt::Cxn";
  }
  unless ($cxn->connected) {
    warn "Not connected";
    return;
  }

  return $class->begin_($cxn, $params->{tx_timeout}, $params->{mode}, $params->{dbname});
}

sub commit { !shift->commit_ }
sub rollback { !shift->rollback_ }

sub run_query {
  my $self = shift;
  my ($query, $parms) = @_;
  unless ($query) {
    die "Arg 1 should be Cypher query string";
  }
  if ($parms && !(ref $parms == 'HASH')) {
    die "Arg 2 should be a hashref of { param => $value, ... }";
  }
  return $self->run_query_($query, $parms ? $parms : {}, 0);
}

sub send_query {
  my $self = shift;
  my ($query, $parms) = @_;
  unless ($query) {
    die "Arg 1 should be Cypher query string";
  }
  if ($parms && !(ref $parms == 'HASH')) {
    die "Arg 2 should be a hashref of { param => $value, ... }";
  }
  return $self->run_query_($query, $parms ? $parms : {}, 1);
}

sub do_query {
  my $self = shift;
  my $stream = $self->run_query(@_);
  my @results;
  if ($stream->success_) {
    while (my @row = $stream->fetch_next_) {
      push @results, [@row];
    }
  }
  return wantarray ? ($stream, @results) : $stream;
}

=head1 NAME

Neo4j::Bolt::Txn - Container for a Neo4j Bolt explicit transaction

=head1 SYNOPSIS

 use Neo4j::Bolt;
 $cxn = Neo4j::Bolt->connect("bolt://localhost:7687");
 unless ($cxn->connected) {
   print STDERR "Problem connecting: ".$cxn->errmsg;
 }
 $txn = Neo4j::Bolt::Txn->new($cxn);
 $stream = $txn->run_query(
   "CREATE (a:booga {this:'that'}) RETURN a;"
 );
 if ($stream->failure) {
   print STDERR "Problem with query run: ".
                 ($stream->client_errmsg || $stream->server_errmsg);
   $txn->rollback;
 }
 else {
   $txn->commit;
 }

=head1 DESCRIPTION

L<Neo4j::Bolt::Txn> is a container for a Bolt explicit transaction, a feature
available in Bolt versions 3.0 and greater.

=head1 METHODS

=over

=item new()

Create (begin) a new transaction. Execute within the transaction with run_query(), send_query(), do_query().

=item commit()

Commit the changes staged by execution in the transaction.

=item rollback()

Rollback all changes.

=item run_query(), send_query(), do_query()

Completely analogous to same functions in L<Neo4j::Bolt::Cxn>.

=back

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN
 majensen -at- cpan -dot- org

=head1 LICENSE

This software is Copyright (c) 2019-2020 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

1;
