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
