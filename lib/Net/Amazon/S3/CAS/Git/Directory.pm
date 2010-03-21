package Net::Amazon::S3::CAS::Git::Directory;
use Moose;

use File::Temp ();
use File::Path qw(remove_tree);
use Path::Class qw(file);

use Data::Stream::Bulk::Array;

use Net::Amazon::S3::CAS::Git::BLOB;
use Net::Amazon::S3::CAS::Entry;

use namespace::clean -except => 'meta';

with qw(Net::Amazon::S3::CAS::Directory);

has filter => (
    isa => "ArrayRef[Str]",
    is  => "ro",
    default => sub { [] },
);

has repo => (
    isa => "Object",
    is  => "ro",
    required => 1,
);

has treeish => (
    isa => "Str",
    is  => "ro",
    default => "HEAD",
);

has tempfile_threshold => (
    isa => "Int",
    is  => "ro",
    default => 4096,
);

has tempdir => (
    is  => "ro",
    lazy_build => 1,
);

sub _build_tempdir {
    my $self = shift;

    File::Temp::tempdir();
}

sub DEMOLISH {
    my $self = shift;

    if ( $self->has_tempdir ) {
        remove_tree( $self->tempdir );
    }
}

sub ls_tree {
    my $self = shift;

    local $/ = "\0";

    map {
        my %entry;
        @entry{qw(mode type hash name)} = split /\s+/, $_, 4;
        \%entry;
    } $self->repo->command([qw(ls-tree -r -z --full-name), $self->treeish, @{ $self->filter }]);
}

sub entries {
    my $self = shift;

    my @entries = map {
        Net::Amazon::S3::CAS::Entry->new(
            key => $_->{hash},
            blob => Net::Amazon::S3::CAS::Git::BLOB->new(
                dir => $self,
                %$_,
            ),
        ),
    } $self->ls_tree;

    Data::Stream::Bulk::Array->new(
        array => \@entries,
    );
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

Net::Amazon::S3::CAS::Git::Directory - L<Net::Amazon::S3::CAS::Collection> for
Git treeish objects.

=head1 SYNOPSIS

    my $dir = Net::Amazon::S3::CAS::Collection->new(

        # anything that resolves into a commit or tree object
        treeish => $ref_or_whatever,

        repo => Git->repository(...),

        filter => \@args_to_ls_tree
    );

    $dir->entries;

=head1 DESCRIPTION

This class implements the L<Net::Amazon::S3::CAS::Collection> API, where the
source of the blobs is a Git tree object.

=head1 ATTRIBUTES

=over 4

=item treeish

A ref, tree sha1, commit sha1 or other rev specification. See Git's
C<rev-parse> manpage for more details on what this can be.

=item filter

An array ref of arguments to pass to C<git ls-tree>.

=item tempfile_threshold

Blobs larger than this value will return true from
L<Net::Amazon::S3::CAS::BLOB/prefer_handle>.

Defaults to 4096.

=item tempdir

The directory to use for temporary files.

Defaults to L<File::Temp::tempdir()>.

=item repo

The L<Git> object to use.

=back
