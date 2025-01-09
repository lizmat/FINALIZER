class FINALIZER {
    # The blocks that this finalizer needs to finalize
    has @.blocks;
    has $!lock;

    # Make sure we have a lock for adding / removing from blocks
    submethod TWEAK() { $!lock = Lock.new }

    # The actual method calling the registered blocks for this finalizer
    method FINALIZE(FINALIZER:D:) {
        $!lock.protect: {
            my @exceptions;
            for @!blocks -> &code {
                code();
                CATCH { default { @exceptions.push($_) } }
            }
            dd @exceptions if @exceptions;
        }
    }

    # Run code with a lock protecting changes to blocks
    method !protect(FINALIZER:D: &code) { $!lock.protect: &code }

    # Register a block for finalizing if there is a dynamic variable with
    # a FINALIZER object in it.
    method register(FINALIZER:U: &code --> Callable:D) {
        with $*FINALIZER -> $finalizer {
            $finalizer!protect: { $finalizer.blocks.push(&code) }
            -> { $finalizer!unregister(&code) }
        }
        else {
            -> --> Nil { }
        }
    }

    # Unregister a finalizing block: done as a private object method to
    # make access to blocks easier.  Assumes we're already in protected
    # mode wrt making changes to blocks.
    method !unregister(FINALIZER:D: &code --> Nil) {
        my $WHICH := &code.WHICH;
        @!blocks.splice($_,1) with @!blocks.first( $WHICH eq *.WHICH, :k );
    }
}

# Exporting for a client environment
multi sub EXPORT() {

    # The magic incantation to export a LEAVE phaser to the scope where
    # the -use- statement is placed, Zoffix++ for producing this hack!
    $*W.add_phaser: $*LANG, 'LEAVE', { $*FINALIZER.FINALIZE }

    # Make sure we export a dynamic variable as well, to serve as the
    # check point for the finalizations that need to happen in this scope.
    my %export;
    %export.BIND-KEY('$*FINALIZER',my $*FINALIZER = FINALIZER.new);
    %export
}

# Exporting for a module environment
multi sub EXPORT('class-only') { {} }

# Role to be used by objects
role Finalizable {
    has &!finalizer = FINALIZER.register: { self.finalize() }

    method FINALIZE { }

    method finalize(\SELF:) {
        &!finalizer();
        SELF.FINALIZE()
    }
}

multi sub EXPORT('role-only') {
    BEGIN Map.new('Finalizable' => Finalizable)
}

# vim: expandtab shiftwidth=4
