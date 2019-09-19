C256MGR -- A command line tool for connecting to the C256 Foenix Debug Port

C256MGR can be used to send Intel HEX files to the C256 or to read memory from the board.

To send a hex file:
c256mgr -p <port> -s <hexfile>

To display memory:
c256mgr -p <port> -a <address in hex> -c <count of bytes in hex>

If you have a 64TASS label file (*.lbl), you can provide that as an option
and display the contents of a memory location by its label:
c256mgr -p <port> -l <label file> -v <label> -c <count of bytes in hex>

If you have a 64TASS label file (*.lbl), you can provide that as an option
and display the contents of a memory location by deferencing the pointer
at a location in the label file:
c256mgr -p <port> -l <label file> -d <label> -c <count of bytes in hex>

The count of bytes is optional and defaults to 16.

=====

Usage: c256mgr.py [options]

Options:
  -h, --help            show this help message and exit
  -s TO_SEND, --send=TO_SEND
                        Intel HEX file to send.
  -p PORT, --port=PORT  communication port for the C256
  -a START_ADDRESS, --address=START_ADDRESS
                        starting address for memory to fetch (in hex)
  -v LABEL, --variable=LABEL
                        label to look up for the starting address
  -d LABEL, --reference=LABEL
                        label of a pointer to look up and dereference for the starting address
  -c COUNT, --count=COUNT
                        number of bytes to read (in hex)
  -l LABEL_FILE, --label-file=LABEL_FILE
                        the name of the file containing the address labels