# BASIC816

This is an implementation of a classic, line-number based BASIC interpreter.
It is designed from the ground-up to work on the WDC65C816 CPU and compatible chips.
This version of BASIC will be tailored specifically to the C256 Foenix, but there
should be no reason it could not be ported to other 65C816 based computers, removing
or modifying certain statements as necessary.

## Current Status

The BASIC interpreter is in a very primitive (and unstable) state at the moment. Most
of the language has yet to be implemented yet, and an interactive mode has only just
been added. Most of the code is currently in the form of unit tests.

You can see the current [TODO List and Status](status.md).

You can also view the (incomplete) [Language Description](language.md) listing out the
commands, statements, and functions this version of BASIC is intended to support.
