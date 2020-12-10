use v6.c;
use Test;
use FINALIZER <role-only>;

plan 1;

my @expected;
my @reality;

class Foo is Finalizable {
   has $.i;
   method FINALIZE { @reality.push($.i) }
};

{
    use FINALIZER;
    for ^20 {
        Foo.new(i => $_);
        @expected.push($_);
    }
}

END is-deeply @reality, @expected, 'All finalizers were executed';

# vim: ft=perl6 expandtab sw=4
