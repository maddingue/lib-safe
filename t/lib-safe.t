#!perl -T
use strict;
use warnings;
use Test::More;


plan tests => 2;

use_ok "lib::safe" or die "could not load module, abort tests";
ok grep(ref, @INC) == 1, "check that the \@INC hook is installed";



eval "require Foo";
like $@, qr/^Can't locate Foo.pm in \@INC/, "require Foo";

