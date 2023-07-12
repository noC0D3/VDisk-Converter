This is a script i wrote to convert my virtualbox VDI disk images to KVM's qcow2.
Currently no other file formats are supported but some may be added in the future.

Usage:
    vDiskConv.sh /path/to/images <maxdepth> <options>
    vDiskConv.sh /path/to/images 3 -v -less

Options:
    -v  Verbose output
    -q  Quiet, dont show check dialog
    -y  Dont show confirmation dialog
    -less   Pipe check dialog into less
    -del    Delete the original disks after new ones have ben converted
