trash.sh
========

Sometimes I regret running `rm`. I love the convenience of a trash
folder given by my desktop environment. 

This script is meant to be a drop-in alias for rm, that will, instead
of unlinking a file, rename is to .<filename>.<timestamp>.trash in
it's current directory, and create a symlink to the file in ~/.trash.
The folder and file extension are configurable, as are whether the
file is renamed, symlinked, or simply moved into the trash folder.

See `trash.sh --help` for full details.

Example:
`trash.sh -rf ~/stuff/stuff-i-dont-want`
`trash.sh -rf ~/stuff/stuff-i-dont-want/*`
`trash.sh -rf --no-preserve-root /`
