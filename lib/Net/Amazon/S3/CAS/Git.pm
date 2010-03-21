package Net::Amazon::S3::CAS::Git;
use Moose;

use namespace::clean -except => 'meta';

our $VERSION = "0.01";

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 REWRITEMAP SUPPORT

You can use the rewritemap output with this configuration:

    RewriteEngine On

    # this is used to escape key URIs
    RewriteMap esc int:escape

    # this is the actual lookup
    RewriteMap s3 txt:/path/to/rewritemap.txt

    # only do the rewrite if there's a match in the map
    RewriteCond ${s3:${esc:$1}} !=""

    # rewrite the URI to the S3 URI
    # R redirects, noescape doesn't double escape the S3 URIs
    RewriteRule ^/(.*)$ ${s3:${esc:$1}} [R,noescape]

