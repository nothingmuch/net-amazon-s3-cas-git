#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Net::Amazon::S3::CAS::Git',
    VERSION_FROM => 'lib/Net/Amazon/S3/CAS/Git.pm',
    INSTALLDIRS  => 'site',
    SIGN         => 1,
    PL_FILES     => { },
    PREREQ_PM    => {
        'Net::Amazon::S3::CAS' => 0,
        'Moose' => 0,
        'MooseX::Types' => '0.08',
        'MooseX::Types::Moose' => 0,
        'MooseX::Types::Path::Class' => 0,
        'Git' => 0,
        'Data::Stream::Bulk' => 0,
        'Try::Tiny' => 0,
        'namespace::clean' => '0.11',
        'autodie' => 0,
        'Test::More' => '0.88',
        'Test::use::ok' => 0,
        'Test::TempDir' => 0,
        'Directory::Scratch' => 0,
    },
);
