use FINALIZER <role-only>;

class Frobnicate-Role is Finalizable {
    has &.code;

    method FINALIZE {
        &!code()
    }
}

sub dbiconnect(&code) is export { Frobnicate-Role.new( :&code ) }

# vim: ft=perl6 expandtab sw=4
