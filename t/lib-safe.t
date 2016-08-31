#!perl
use strict;
use warnings;
use File::Path;
use File::Spec::Functions;
use File::Temp qw< tempdir >;
use Test::More;


plan tests => 11;

use_ok "lib::safe" or die "could not load module, abort tests";
ok grep(ref, @INC) == 1, "check that the \@INC hook is installed";

# check that requiring a module that doesn't exists still fails
eval "require Foo::Bar";
like $@, qr/^Can't locate Foo\/Bar.pm in \@INC \(you may need to install the Foo::Bar module\)/, "require Foo::Bar";

# check that requiring standard modules still works
require_ok "POSIX";
use_ok "Sys::Syslog";

# build a hierarchy to perform the actual tests
my $tmpdir = tempdir("lib-safe-XXXXXX", TMPDIR => 1, CLEANUP => 1);
mkpath catdir($tmpdir, qw< lib Should >);
mkpath catdir($tmpdir, qw< lib Should Not >);

open my $fh, ">", catfile($tmpdir, qw< lib Should Work.pm >);
print {$fh} "package Should::Work;\n__PACKAGE__\n";
close $fh;

open $fh, ">", catfile($tmpdir, qw< lib Should Not Work.pm >);
print {$fh} "package Should::Not::Work;\n__PACKAGE__\n";
close $fh;

open $fh, ">", catfile($tmpdir, qw< lib Should FailUnderStrict.pm >);
print {$fh} "package Should::FailUnderStrict;\n__PACKAGE__\n";
close $fh;

my $tmplib = catdir($tmpdir, "lib");
my $tmppmdir = catdir($tmplib, qw< Should Not >);
chmod 0500, $tmplib, catdir($tmpdir, qw< lib Should >);

# add this hierarchy to @INC
push @INC, $tmplib;

# this one should work
use_ok "Should::Work";

# this one shouldnt'
eval "use Should::Not::Work";
like $@, qr/^directory '$tmppmdir.' in \@INC is writable by the current user/,
    "use Should::Not::Work";

# in strict mode, a single writable directory at the beginning of @INC
# will prevent any module from being loaded
my $writable = catdir($tmpdir, qw< strict Should >);
mkpath $writable;
splice @INC, 1, 0, catdir($tmpdir, "strict");

use_ok "lib::safe", "strict";

eval "use Should::FailUnderStrict;";
like $@, qr/^directory '$writable.' in \@INC is writable by the current user/,
    "use Should::FailUnderStrict;";

# uninstall lib::safe hook
eval "no lib::safe";
is $@, "", "no lib::safe";
ok grep(ref, @INC) == 0, "check that the \@INC hook is no longer installed";

