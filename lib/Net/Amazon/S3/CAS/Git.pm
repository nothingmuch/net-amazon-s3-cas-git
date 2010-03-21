package Net::Amazon::S3::CAS::Git;
use Moose;

use namespace::clean -except => 'meta';

our $VERSION = "0.01";

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

Net::Amazon::S3::CAS::Git - Use Git as a data source for
L<Net::Amazon::S3::CAS>

=head1 SYNOPSIS

    % git to-s3 --treeish $tree_id --bucket $bucket_name

=head1 DESCRIPTION

This module implements a L<Net::Amazon::S3::CAS::Collection> that's based on
Git tree objects, and also provides a C<git to-s3> command that can upload
blobs easily.

See L<Net::Amazon::S3::CAS::Git::Cmd> and
L<Net::Amazon::S3::CAS::Git::Directory> for more details.
