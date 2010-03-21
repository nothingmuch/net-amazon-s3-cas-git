package Net::Amazon::S3::CAS::Git::Cmd;
use Moose;

use Path::Class;
use MooseX::Types::Path::Class qw(Dir);
use MooseX::Types::Moose qw(Str ArrayRef);

use Git;
use Net::Amazon::S3;

use Try::Tiny;

use Net::Amazon::S3::CAS;
use Net::Amazon::S3::CAS::Git::Directory;

use namespace::clean -except => 'meta';

with qw(MooseX::Getopt::Dashes);

has treeish => (
    traits        => [qw(Getopt)],
    isa           => Str,
    is            => "ro",
    default       => "HEAD",
    documentation => "the treeish object to pass to ls-tree (defaults to HEAD)",
);

has filter => (
    traits        => [qw(Getopt)],
    isa           => ArrayRef [Str],
    is            => "ro",
    lazy_build => 1,
    documentation => "additional filters to pass to git-ls-tree",
);

sub _build_filter { shift->extra_argv }

has aws_access_key_id => (
    traits        => [qw(Getopt)],
    isa           => Str,
    is            => "ro",
    required      => 1,
    default       => sub { $ENV{AWS_ACCESS_KEY_ID} },
    documentation => "your AWS access key",
);

has aws_secret_access_key => (
    traits        => [qw(Getopt)],
    isa           => Str,
    is            => "ro",
    required      => 1,
    default       => sub { $ENV{AWS_SECRET_ACCESS_KEY} },
    documentation => "your AWS secret key",
);

has git_dir => (
    traits        => [qw(Getopt)],
    isa           => Dir,
    is            => "ro",
    default       => sub { dir(".") },
    documentation => "the Git repository to work from (defaults to cwd)"
);

has bucket => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "ro",
    required      => 1,
    documentation => "the S3 bucket to use"
);

has prefix => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "ro",
    predicate     => "has_prefix",
    documentation => "The prefix in the bucket to use (defaults to the emtpy string)",
);

has prune => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "ro",
    default       => 0,
    documentation => "Whether to remove objects under prefix/ not in the ls-tree output (defaults to false)",
);

has public => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "ro",
    default       => 1,
    documentation => "Set the ACL to public-read (defaults to true)",
);

has max_age => (
    traits        => [qw(Getopt)],
    isa           => "Maybe[Int]",
    is            => "ro",
    default       => 10 * 365 * 24 * 60 * 60,                                                      # 10 years
    documentation => "The number of seconds to set in the cache headers (defaults to 10 years)",
);

has include_name => (
    traits  => [qw(Getopt)],
    isa     => "Bool",
    is      => "ro",
    default => 0,
    documentation =>
      "Incorperate the filename and extension to the final resource name in addition to the hash (defaults to false)",
);

has only_basename => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "ro",
    default       => 1,
    documentation => "Only prepend the basename when including name (defaults to true)",
);

has delimiter => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "ro",
    documentation => "The delimiter to use when mangling keys (defaults to . or / depending on hash_as_dir)",
    predicate     => "has_delimiter",
);

has hash_as_dir => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "ro",
    documentation => "Use the hash as if it were a directory name (defaults to false).",
);

has vhost => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "ro",
    documentation => 'use the bucket name as a vhost (instead of http://s3.amazonaws.com/$bucket)',
);

has print_rewritemap => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "ro",
    default       => 1,
    documentation => "Whether an Apache compatible RewriteMap is written to standard output",
);

has n_proc => (
    traits        => [qw(Getopt)],
    isa           => "Maybe[Int]",
    is            => "ro",
    lazy_build    => 1,
    documentation => "The number of concurrent workers to use (defaults to 5 if Parallel::ForkManager is available)",
);

has verbose => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "ro",
    documentation => "Prints information about files to STDERR as they are being processed",
);

sub _build_n_proc {
    my $self = shift;

    if ( try { require Parallel::ForkManager; 1 } ) {
        return 5;
    } else {
        return 1;
    }
}

has s3 => (
    traits     => [qw(NoGetopt)],
    isa        => "Net::Amazon::S3",
    is         => "ro",
    lazy_build => 1,
);

sub _build_s3 {
    my $self = shift;

    Net::Amazon::S3->new(
        # FIXME MooseX::Builder::SimilarAttrs? construct an object using the
        # same named attrs in another object?
        aws_access_key_id => $self->aws_access_key_id,
        aws_secret_access_key => $self->aws_secret_access_key,
        retry => 1,
    );
}

has collection => (
    traits     => [qw(NoGetopt)],
    isa        => "Net::Amazon::S3::CAS::Git::Directory",
    is         => "ro",
    lazy_build => 1,
);

sub _build_collection {
    my $self = shift;

    Net::Amazon::S3::CAS::Git::Directory->new(
        filter => $self->filter,
        treeish => $self->treeish,
        repo => Git->repository( $self->git_dir ),
    );
}

has cas => (
    traits     => [qw(NoGetopt)],
    isa        => "Net::Amazon::S3::CAS",
    is         => "ro",
    lazy_build => 1,
);

sub _build_cas {
    my $self = shift;

    Net::Amazon::S3::CAS->new(
        bucket     => $self->s3->bucket( $self->bucket ),
        collection => $self->collection,
        ( $self->vhost      ? ( base_uri     => $self->base_uri     ) : () ),
        ( $self->n_proc > 1 ? ( fork_manager => $self->fork_manager ) : () ),
        map { ( !$self->can("has_$_") || $self->${\"has_$_"} ) ? ( $_ => $self->$_ ) : () } qw(
            verbose
            prune
            public
            include_name
            only_basename
            delimiter
            hash_as_dir
            prefix
        ),
    );
}

sub base_uri {
    my $self = shift;

    my $vhost = $self->bucket;

    $vhost = "http://$vhost" unless $vhost =~ /^http:/;

    URI->new($vhost);
}

sub fork_manager {
    my $self = shift;

    require Parallel::ForkManager;
    Parallel::ForkManager->new($self->n_proc);
}

sub run {
    my $self = shift;

    my $uris = $self->cas->sync;

    if ( $self->print_rewritemap ) {
        my @keys = sort keys %$uris;
        local $, = " ";
        local $\ = "\n";
        foreach my $key (@keys) {
            print $key, $uris->{$key};
        }
    }
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__
