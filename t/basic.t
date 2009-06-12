#!/usr/bin/perl

use strict;
use warnings;
use autodie;

use Test::More 'no_plan';
use Test::TempDir qw(scratch);

use Git;

use ok 'Net::Amazon::S3::CAS::Git::Directory';

my $s = scratch();

$s->touch('foo.txt', 'foo');
$s->touch('bar/a space', qw(oh noes));

chdir $s->base;

# FIXME hate Git.pm
print STDERR qx(git init);
print STDERR qx(git add .);
print STDERR qx(git commit -am init);

my $repo = Git->repository;

my $dir = Net::Amazon::S3::CAS::Git::Directory->new( repo => $repo, tempfile_threshold => 5 );

my @entries = $dir->entries->all;

is( scalar(@entries), 2, "two entries" );

is( $entries[0]->blob->slurp, "oh\nnoes\n", "first entry contents" );
is( $entries[0]->blob->name, "bar/a space", "name" );

is( $entries[1]->blob->slurp, "foo\n", "second entry contents" );

