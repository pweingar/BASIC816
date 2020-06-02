# Change Log

## Release: v0.1.0-alpha+XXX

* DIR updated to accept an optional string parameter for a path.
* BRUN updated to assign the 16-bit value in A to the variable ERR on return [Github Issue #7]
* BRUN updated to pass the ASCIIZ path string (with arguments) to the exectuted program [Github Issue #6]
* Re-arranged memory layout. BASIC program code now goes in bank $36, with the heap going in bank $37. This leaves lower memory free for binaries to use as they please and for a standard loading address to start at $01:0000.