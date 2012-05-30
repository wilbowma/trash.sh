#!/bin/bash

usage()
{
cat << EOF
Usage: $0 [OPTION]... FILE...
Trash (not really actually unlink) the FILE(s).

  -f, --force   ignore nonexistent files and arguments, never prompt
  -i    prompt before every trash
  -I    prompt before removing more than three files, or when removing
        recursively. Less intrusive than -i, while still giving protection
        against most mistakes.
      --interactive[=WHEN]  prompt according to WHEN: never, once
                            (-I), or always (-i). Without WHEN, prompt
                            always.
      --one-file-system  when removing a hierarchy recursively, skip any
                         directory that is on a file system different
                         from that of the corresponding command line
                         argument.
      --no-preserve-root  do not treat '/' specially
      --preserve-root   do not remove '/' (default)
  -r, -R, --recursive   remove directories and their contents
                        recursively.
  -v, --verbose         explain what is being done
  -h, --help            display this help and exit
      --version         output version information and exit
  -e, --extension=[EXT] When renaming a file, using EXT as the
                        extension. By default, EXT is trash.
  -t, --trashdir=[DIR]  When renaming a file, also create a symlink in
                        DIR. By default, DIR is ~/.trash.
  -n, --notrashdir      Do not symlink the file to the trash directory.


By default, trash does not remove directories.  Use the --recursive (-r
or -R) option to remove each listed directory, too, along with all of
its contents.

To remove a file whose name starts with a '-', for example '-foo',
use one of these commands:
  $0 -- -foo

  $0 ./-foo

Note that if you use trash to remove a file, it will totally be possible
to recover all of its contents. The file will simply be renamed to
.<filename>.<timestamp>.<ext> (default ext is trash). A symlink can also
be found in the trash folder (default is ~/.trash).
EOF
}
