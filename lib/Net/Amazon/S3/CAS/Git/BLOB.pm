package Net::Amazon::S3::CAS::Git::BLOB;
use Moose;

use autodie;

use File::Spec::Functions qw(catfile);

use namespace::clean -except => 'meta';

has dir => (
    isa => "Net::Amazon::S3::CAS::Git::Directory",
    is  => "ro",
    required => 1,
    handles => [qw(repo tempdir tempfile_threshold)],
);

has name => (
    isa => "Str",
    is  => "ro",
    predicate => "has_name",
);

has hash => (
    isa => "Str",
    is  => "ro",
    required => 1,
);

has size => (
    isa => "Int",
    is  => "ro",
    lazy_build => 1,
);

sub _build_size {
    my $self = shift;

    $self->repo->command_oneline(qw(cat-file -s), $self->hash);
}

sub prefer_handle {
    my $self = shift;

    $self->size > $self->tempfile_threshold;
}

sub openr {
    my $self = shift;

    if ( $self->prefer_handle ) {
        my $unpacked = catfile( $self->tempdir, $self->hash );

        unless ( -e $unpacked ) {
            my $tmp = join( ".", $unpacked, $$, time, rand );
            open my $fh, ">", $tmp;

            $self->repo->cat_blob( $self->hash, $fh );

            close $fh;

            rename $tmp, $unpacked;
        }

        open my $fh, "<", $unpacked;
        return $fh;
    } else {
        my $buf = "";
        open my $fh, ">", \$buf;
        $self->repo->cat_blob( $self->hash, $fh );
        close $fh;

        open my $rfh, "<", \$buf;
        return $rfh;
    }
}

sub slurp {
    my $self = shift;

    my $fh = $self->openr;

    local $/;
    <$fh>;
}

with qw(Net::Amazon::S3::CAS::BLOB);

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

Net::Amazon::S3::CAS::Git::BLOB - Get the data for 

=head1 SYNOPSIS

    my @blobs = $dir->entries->all;

    say $blob->name, " = ", $blob->hash;

    my $data = $blob->slurp;

=head1 DESCRIPTION

This is an implementation of L<Net::Amazon::S3::CAS::BLOB> for Git blobs.
