use v6.c;

class FINALIZER:ver<0.0.2>:auth<cpan:ELIZABETH> {
    # The blocks that this finalizer needs to finalize
    has @.blocks;

    # Make sure we always have a outermost finalizer
    INIT PROCESS::<$FINALIZER> = FINALIZER.new;

    # Make sure the outermost finalizer will always run
    END  PROCESS::<$FINALIZER>.FINALIZE;

    # The actual method calling the registered blocks for this finalizer
    method FINALIZE()   { .() for @!blocks }

    # Register a block for finalizing.  Make sure the currently active
    # dynamic variable actually has a FINALIZER object in it if it didn't
    # already
    method register(&a) { ($*FINALIZER //= FINALIZER.new).blocks.push(&a) }
}

sub EXPORT() {

    # The magic incantation to export a LEAVE phaser to the scope where
    # the -use- statement is placed, Zoffix++ for producing this hack!
    $*W.add_phaser: $*LANG, 'LEAVE', { $*FINALIZER.?FINALIZE }

    # Make sure we export a dynamic variable as well, to serve as the
    # check point for the finalizations that need to happen in this scope.
    my %export;
    %export.BIND-KEY('$*FINALIZER',my $*FINALIZER);
    %export
}

=begin pod

=head1 NAME

FINALIZER - dynamic finalizing for objects that need finalizing

=head1 SYNOPSIS

    {
        use FINALIZER;   # enable finalizing for this scope
        my $foo = Foo.new(...);
        # do stuff with $foo
    }
    # $foo has been finalized by exiting the above scope

    # different file / module
    class Foo {
        use FINALIZER;
        method new(|c) {
            my $object = self.bless(|c);
            FINALIZER.register: { $object.finalize }
            $object
        }
        method finalize() {
            # do whatever we need to finalize, e.g. close db connection
        }
    }

=head1 DESCRIPTION

FINALIZER allows one to register finalization of objects in the scope that
you want, rather than in the scope where objects where created (like one
would otherwise do with C<LEAVE>  blocks or the C<is leave> trait).

=head1 AS A MODULE DEVELOPER

If you are a module developer, you need to use the FINALIZE module in your
code.  In any logic that returns an object (typically the C<new> method) that
you want finalized at the moment the client decides, you register a code
block to be executed when the object should be finalized.  Typically that
looks something like:

    method new(|c) {
        my $object = self.bless(|c);
        FINALIZER.register: { $object.finalize }
        $object
    }

    FINALIZER.register: { ... }   # code that will do finalization

=head1 AS A PROGRAM DEVELOPER

Just use the module in the scope you want to have objects finalized for
when that scope is left.  If you don't use the module at all, all objects
that have been registered for finalization, will be finalized when the
program exits.

=head1 AUTHOR

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/FINALIZER . Comments and
Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
