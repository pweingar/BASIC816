BASIC816 Accessing Assembly Code
===

There will be two approaches to access machine code from BASIC. The first is a simple
method to call out to an assembly language routine in any section of the system's memory.
The other is a method for exending BASIC's set of statements, functions, and commands using
custom machine code.

With both methods of providing machine code, the machine code to run might have a need to
use some of BASIC816's internal routines to communicate with BASIC itself or with the
BASIC program that is running. BASIC816 will provide a jump table to access cricital
subroutines. For example, if an extension needs to evaluate an expression to provide a
parameter to a statement, it could call the EVALEXPR subroutine through the jump table.
This jump table might be useful for other purposes as well, like running the BASIC interpreter
within a windowing GUI.

The CALL Statement
---

```
CALL <address> [, <A register> [, <X register> [, <Y register>]]]
```

The `CALL` statement performs a `JSL` instruction to the address provided to exectute
the machine code at that location. The machine code can return to the BASIC program by
executing an `RTL` instruction.

The program may optionally provide values for the A, X, and Y registers. If the progam wants
to provide a value for X, a value for A _must_ be provided. Likewise, if a value for Y is
provided, values for A and X _must_ be provided as well. The registers will be treated as
16-bit registers, so values may be provided up to 16-bits in width. If a value wider than
16 bits is provided, only the least significant 16 bits will be used.

No value is returned by the `CALL` statement.

Extension Framework
---

For more complex integration of machine language and BASIC, the interpreter will allow for
the program to load a binary file containing code for extending the commands, statements,
and functions of the interpreter. An extension may be loaded with the statement:

```
EXTENSION <path>
```

Executing this statement will load the extension file off the storage device, given its path.
The statement will also implicitly execute a `CLR` statement, removing all variable
definitions and heap storage objects. The reason for this is that the extenstions will be loaded
into what would be the top of the heap, and the heap will need to be moved down to accomodate
the extension. Therefore, if a program needs to use an extension, the first thing it should do
is to load the extension.

Note that multiple extensions can be loaded at one time. The interpreter will assign an extension
token sequence to each keyword defined by the extensions. Since multiple extensions can be used,
the token sequence can vary from program to program. That means that if an extension provides a
statement `PLAY`, it might have the token $F1 in one program, but in another program, it might
have the token $F8.

Coding an Extension
---

An extension will be a binary file on a storage device (SD Card, floppy disk, hard drive). Each
extension will be loaded into its own memory bank of 64KB. The extension will have free use of all
memory within that bank for whatever purpose it desires. The beginning of that memory bank must be
laid out in a particular structure, however (see below). While the extension will always be loaded so
that the first byte of the file corresponds to the first byte of the bank, the particular bank the
extension will be loaded into will be determined at runtime by the interpreter. The memory size of
the computer and the load order of other extensions the program may use can affect the particular
bank used. All addresses used by the extension for accessing its own memory should therefore be
16-bit addresses (_e.g._ bank relative, PC relative, _etc._).

Format (Tentative!)

The following is a simple map of the first section of an extension, starting with byte 0:

```
struct {
    char magic[3];              // A three-character magic code indicating this is an extension
    uint8_t version;            // A single byte version code for the extension format
    uint16_t init_ptr;          // A 16-bit offset to any initialization code (0 if none)
    struct {
        uint8_t type;           // A byte indicating the type of the token (statement, comment, function, operator, punctuation)
        uint16_t name_ptr;      // A 16-bit offset to an ASCIIZ string for the keyword of the token
        uint16_t exec_ptr;      // A 16-bit offset to the code to call to evaluate the token
    } tokens[];
    uint8_t eot;                // Always equal to $FF
    uint8_t code[];             // The code for the extension
}
```

The first three bytes are the required magic number (TBD), identifying the file as a BASIC816 extension.
The fourth byte is a binary version number. It will be $00 for the first version. If there are any changes to the extension
layout, they can be flagged here.

Next comes an offset pointer (16-bits) to an initialization routine that will be called when the extension has been loaded
but before the `EXTENSION` statement completes execution. This can be used for any sort of set up housekeeping the
extension needs to do. If there is nothing to do here, the offset should be set to $0000.

Next comes a token record, one per keyword provided by the extension. The record contains a byte indicating what type
of keyword is being defined (statement, function, command, operator, or even punctuation). The next byte indicates the
evaluation precedence (relevant for operators). Then there is a 16-bit offset pointer to the name of the keyword (an
upper-case ASCIIZ string). Then there is a 16-bit offset pointer to the code to execute when executing the keyword. The
subroutine at that location should return with an `RTL` instruction.

After all the token records have been provided, the next byte should be $FF to indicate there are no more records to process.
All other bytes in the file after that point are left for the extension's use. They may be arranged however the extension
author desires.


