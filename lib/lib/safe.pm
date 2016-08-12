package lib::safe;

use strict;
use version;

use Carp qw< croak >;


sub import {
    unshift @INC, \&my_require;
}


sub unimport {
    @INC = grep { $_ ne \&my_require } @INC;
}


sub my_require {
    my ($sub, $filename) = @_;

    print STDERR "[my_require] filename=$filename\n";
    croak "Missing or undefined argument to require"
        if not defined $filename or not length $filename;

    # handle "require v5..."
    if (my $version = eval { version->parse($filename) }) {
        if ($version > $^V) {
           my $vn = $version->normal;
           croak "Perl $vn required--this is only $^V, stopped";
        }

        return 1;
    }

    if (exists $INC{$filename}) {
        return 1 if $INC{$filename};
        croak "Compilation failed in require";
    }

    for my $prefix (@INC) {
        if (ref $prefix) {
            # handle other coderefs, excluding ourselves
            next if ref $prefix eq $sub;
        }

        # (see text below about possible appending of .pmc
        # suffix to $filename)
        my $realfilename = "$prefix/$filename";
        next if ! -e $realfilename || -d _ || -b _;
        $INC{$filename} = $realfilename;
        my $pkg = caller();
        my $result = do $realfilename;
                     # but run in caller's namespace

        if (not defined $result) {
            $INC{$filename} = undef;
            croak $@ ? "$@Compilation failed in require"
                     : "Can't locate $filename: $!\n";
        }

        if (not $result) {
            delete $INC{$filename};
            croak "$filename did not return true value";
        }

        $! = 0;
        return $result;
    }

    croak "Can't locate $filename in \@INC ...";
}


__PACKAGE__

__END__

