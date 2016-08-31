package lib::safe;

use strict;

use Carp qw< croak >;
use File::Spec::Functions qw< catfile splitpath >;


my $strict = 0;


#
# import()
# ------
sub import {
    @INC = grep { not ref $_ or $_ != \&validate } @INC;
    unshift @INC, \&validate;
    $strict = 1 if grep { $_ eq "strict" } @_;
}


#
# unimport()
# --------
sub unimport {
    @INC = grep { not ref $_ or $_ != \&validate } @INC;
    $strict = 0 if grep { $_ eq "strict" } @_;
}


#
# validate()
# --------
sub validate {
    my ($sub, $filename) = @_;

    for my $prefix (@INC) {
        if (ref $prefix) {
            # handle other coderefs, excluding ourselves
            next if ref $prefix and $prefix == $sub;
            # ...
        }

        my $pm_path = catfile($prefix, $filename);
        my $pmc_path = $pm_path . "c";
        my (undef, $dir_path) = splitpath($pm_path);
        my $is_writable = -w $dir_path ? 1 : 0;
        my $dir_is_writable_error = "directory '$dir_path' in \@INC is "
            . "writable by the current user";

        croak $dir_is_writable_error if $strict and $is_writable;

        if (-e $pmc_path) {
            open my $fh, "<", $pmc_path
                or croak "Can't read file '$pmc_path': $!";
            croak $dir_is_writable_error if $is_writable;
            return undef, $fh, undef, undef
        }

        next if ! -e $pm_path || -d _ || -b _;
        open my $fh, "<", $pm_path
            or croak "Can't read file '$pm_path': $!";
        croak $dir_is_writable_error if $is_writable;
        return undef, $fh, undef, undef
    }

    # prevent require() from going itself through @INC
    (my $module = $filename) =~ s|/|::|g;
    $module =~ s/\.pm$//;
    croak "Can't locate $filename in \@INC (you may need to install "
        . "the $module module) (\@INC contains: @INC)";
}


__PACKAGE__

__END__

=encoding UTF-8

=head1 NAME

lib::safe - check that none of the dirs in @INC is writable by the current user

=head1 SYNOPSIS

    # silently skips over writable directories
    use lib::safe;

    # croaks on the first writable directory encounterd
    use lib::safe "strict";

=head1 DESCRIPTION

This is an experimental pragma to somehow provide a better solution
for the CVS-2016-1238 problem.

This module installs a C<require> hook in C<@INC> which checks whether
directories in C<@INC> are writable. Be default, if a directory is detected
as writable, it is skipped over. When the C<strict> option is enabled,
a writable directory trigger an exception.

=head1 AUTHOR

Sébastien Aperghis-Tramoni

