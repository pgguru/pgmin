#!/usr/bin/env perl
use strict;
use warnings;
use PostgreSQL::Test::Cluster;
use Test::More qw/no_plan/;
use IPC::Run qw/run/;

my $node = PostgreSQL::Test::Cluster->new('primary');

$node->init();
$node->start();

my @pgmin = qw(./pgmin);

sub test_pgmin_query {
    my ($query) = @_;
    my $out;

    run \@pgmin, \$query, \$out;
    return $out;
}

print(test_pgmin_query("SELECT 1"));

# test idempotency
for my $query (
    "select 1",
    "select 'abc', 123 from table where foo = 'bar'",
    "WITH foo AS (select 1, 2, 3 from
table::thing), bar AS (values (1)) select * from foo join bar
where 1
!=2 and status = 'something something something 1234'"
) {
    my $minimized = test_pgmin_query($query);

    is(test_pgmin_query($minimized), $minimized, 're-processing output is idempotent');
}

# test minimized output for validity
for my $query (
    "select 1",
    "select generate_series(1,100)",
    "select generate_series(1,100)::text || 'BLAH BLAH !?\@'",
) {
    my $minimized = test_pgmin_query($query);

    is($node->safe_psql('postgres', $query), $node->safe_psql('postgres', $minimized), 'compare results of query and minimized query');
}
