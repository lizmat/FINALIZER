[![Actions Status](https://github.com/lizmat/FINALIZER/actions/workflows/linux.yml/badge.svg)](https://github.com/lizmat/FINALIZER/actions) [![Actions Status](https://github.com/lizmat/FINALIZER/actions/workflows/macos.yml/badge.svg)](https://github.com/lizmat/FINALIZER/actions) [![Actions Status](https://github.com/lizmat/FINALIZER/actions/workflows/windows.yml/badge.svg)](https://github.com/lizmat/FINALIZER/actions)

NAME
====

FINALIZER - dynamic finalizing for objects that need finalizing

SYNOPSIS
========

```raku
{
    use FINALIZER;   # enable finalizing for this scope
    my $foo = Foo.new(...);
    # do stuff with $foo
}
# $foo has been finalized by exiting the above scope

# different file / module
use FINALIZER <role-only>;   # only get the Finalizable role
class Foo is Finalizable {
    method FINALIZE() {
        # do whatever we need to finalize, e.g. close db connection
    }
}
```

DESCRIPTION
===========

FINALIZER allows one to register finalization of objects in the scope that you want, rather than in the scope where objects were created (like one would otherwise do with `LEAVE` blocks or the `is leave` trait).

AS A MODULE DEVELOPER
=====================

If you are a module developer, you need to use the Finalizable role in your code. Objects created with the `Finalizable` role applied may implement `FINALIZE` method to perform cleanup tasks after scope is completed.

```raku
use FINALIZER <role-only>;   # only get the Finalizable role
class Foo is Finalizable {
   method FINALIZE {
       # do whatever we need to finalize, e.g. close db connection
   }
}
```

It is also possible to use the `FINALIZER` class from `FINALIZE` module in your code. In any logic that returns an object (typically the `new` method) that you want finalized at the moment the client decides, you register a code block to be executed when the object should be finalized. Typically that looks something like:

```raku
use FINALIZER <class-only>;  # only get the FINALIZER class
class Foo {
    has &!unregister;

    submethod TWEAK() {
        &!unregister = FINALIZER.register: { .finalize with self }
    }
    method finalize() {
        &!unregister();  # make sure there's no registration anymore
        # do whatever we need to finalize, e.g. close db connection
    }
}
```

AS A PROGRAM DEVELOPER
======================

Just use the module in the scope you want to have objects finalized for when that scope is left. If you don't use the module at all, all objects that have been registered for finalization, will be finalized when the program exits. If you want to have finalization happen for some scope, just add `use FINALIZER` in that scope. This could e.g. be used inside `start` blocks, to make sure all registered resources of a job run in another thread, are finalized:

```raku
await start {
    use FINALIZER;
    # open database handles, shared memory, whatever
    my $foo = Foo.new(...);
}   # all finalized after the job is finished
```

RELATION TO DESTROY METHOD
==========================

This module has **no** direct connection with the `.DESTROY` method functionality in Raku. However, if you, as a module developer, use this module, you do not need to supply a `DESTROY` method as well, as the finalization will have been done by the `FINALIZER` module. And as the finalizer code that you have registered, will keep the object otherwise alive until the program exits.

It therefore makes sense to reset the variable in the code doing the finalization. For instance, in the above class Foo:

```raku
method finalize(\SELF: --> Nil) {
    # do stuff with SELF
    SELF = Nil
}
```

The `\SELF:` is a way to get the invocant without it being decontainerized. This allows resetting the variable containing the object (by assigning `Nil` to it).

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/FINALIZER . Comments and Pull Requests are welcome.

If you like this module, or what I’m doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

COPYRIGHT AND LICENSE
=====================

Copyright 2018, 2019, 2021, 2024, 2025 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

