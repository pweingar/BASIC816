#
# Bundle a directory's contents into a VFS file suitable for loading into BASIC816's virtual file system area
#
# usage: mkvfs.py {vfs file} {source directory}
#

import os
import sys

class VFSEntry:
    """A file entry for the BASIC816 virtual file system/RAM disk."""

    def write(self, fd_out, start_address):
        """Write the entry to the VFS file, starting at the provided address."""

        zero = 0
        bzero = zero.to_bytes(1, byteorder='little')

        self.set_entry_address(start_address)

        # Write out the name portion
        for c in self.get_name():
            if c == "$":
                fd_out.write(bzero)
            else:
                fd_out.write(c.encode("ascii"))

        # Write out the extension portion
        for c in self.get_extension():
            if c == "$":
                fd_out.write(bzero)
            else:
                fd_out.write(c.encode("ascii"))

        # Write out a NUL
        fd_out.write(bzero)

        fd_out.write(self.get_size().to_bytes(4, byteorder='little'))
        fd_out.write(self.get_file_address().to_bytes(4, byteorder='little'))
        fd_out.write(self.get_next().to_bytes(4, byteorder='little'))

        fd_out.write(self.get_data())                           # Write the contents of the file

    def write_dword(self, fd_out, value):
        """Writes a DWORD to the file in little-endian format."""
        fd_out.write(value & 0xff)
        fd_out.write((value >> 8) & 0xff)
        fd_out.write((value >> 16) & 0xff)
        fd_out.write((value >> 24) & 0xff)

    def set_file(self, filepath):
        """Set up the entry based on the file provided."""

        self.is_last = 0

        if os.path.exists(filepath) and os.path.isfile(filepath):
            filename_w_ext = os.path.basename(filepath)
            filename, file_extension = os.path.splitext(filename_w_ext)
            self.set_name(filename)
            self.set_extension(file_extension)
            self.set_size(os.path.getsize(filepath))

            # Read the file contents and attach it to the entry
            with open(filepath, "rb") as fd_in:
                data = fd_in.read()
                self.set_data(data)
        
        else:
            raise Exception("Not a file...")

    def set_is_last(self, is_last):
        """Mark whether or not this is the last entry."""
        self.is_last = is_last

    def set_entry_address(self, address):
        """Sets the address of the first byte of the entry in the VFS file."""
        self.address = address

    def get_entry_address(self):
        """Gets the address of the first byte of the entry in the VFS file."""
        return self.address

    def set_name(self, name):
        """Sets the 8 character name of the file."""
        self.name = name[:8].ljust(8, "$")

    def get_name(self):
        """Gets the 8 character name of the file."""
        return self.name

    def set_extension(self, ext):
        """Sets the 3 character extension of the file."""
        self.ext = ext[1:4].ljust(3, "$")

    def get_extension(self):
        """Gets the 3 character extension of the file."""
        return self.ext

    def set_size(self, size):
        """Sets the size of the file in bytes."""
        self.size = size

    def get_size(self):
        """Gets the size of the file in bytes."""
        return self.size

    def get_file_address(self):
        """Gets the starting address of the file contents in the VFS file."""
        return self.get_entry_address() + 24

    def get_next(self):
        """Gets the starting address of the next VFS entry."""
        if self.is_last:
            return 0
        else:
            return self.get_file_address() + self.get_size()

    def set_data(self, data):
        """Sets the contents of the file."""
        self.data = data

    def get_data(self):
        """Gets teh contents of the file."""
        return self.data

class VFSFile:
    """Represent the VFS file."""

    def load_entries(self):
        """Read the files in the directory path and create their VFS entries."""
        self.entries = []

        # Iterate over the files in the directory
        folder = os.fsencode(self.get_dirpath())
        for file in os.listdir(folder):
            filename = os.fsdecode(file)
            print(filename)
            if os.path.isfile(self.get_dirpath() + "/" + filename):
                entry = VFSEntry()
                entry.set_file(self.get_dirpath() + "/" + filename)
                print("Reading: {}.{}".format(entry.get_name(), entry.get_extension()))
                self.entries.append(entry)

        self.entries[-1].set_is_last(1)

    def write_vfs(self):
        """Create the VFS file, writing the known VFS entries."""

        with open(self.get_filepath(), "wb") as fd_out:
            # Set the address to the starting address for the VFS area on the C256
            address = 0x360000

            for entry in self.entries:
                entry.write(fd_out, address)
                address = entry.get_next()

    def set_filepath(self, path):
        """Sets the path of the VFS file."""
        self.filepath = path

    def get_filepath(self):
        """Gets the path of the VFS file."""
        return self.filepath

    def set_dirpath(self, path):
        """Sets the directory path the VFS file should copy."""
        self.dirpath = path

    def get_dirpath(self):
        """Gets the directory path the VFS file should copy."""
        return self.dirpath

if len(sys.argv) == 3:
    vfs = VFSFile()
    vfs.set_filepath(sys.argv[1])
    vfs.set_dirpath(sys.argv[2])
    vfs.load_entries()
    vfs.write_vfs()

else:
    print("Usage: python mkvfs.py {vfs file} {source directory}")