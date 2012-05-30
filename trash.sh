#!/bin/bash
# TODO: figure out copyright
# TODO: add verbose function
# TODO: Check that all strings are $IFS safe.
# Copyright (C) 2012 William J. Bowman <wjb@williamjbowman.com>

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
                        DIR. By default, DIR is ~/.trash. A full path to
                        the file from / will be created, and the symlink
                        made inside that path.
  -n, --notrashdir      Do not symlink the file to the trash directory.
  -o, --onlytrashdir    Instead of renaming the file, move it to the
                        trash directory completley. 


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

# TODO: Add copyright function. 
# TODO: Figure out copyright.
# TODO: DAMNIT I NEED SOME VIM MACROS/TEMPLATES.
version(){ 
cat << EOF
trash 1.0

Copyright (C) 2012 William J. Bowman.

Written by William J. Bowman <wjb@williamjbowman.com>
EOF
}

# Parse arguments and input, side-effecting global variables used to
# options. Returns a list of files to trash.
parse_arguments(){
  # TODO: Stub
  echo "stub"
}

# Given a file, return it's absolute path.
# TODO: Test
get_absolute_path(){
  pushd $(dirname "$1")
  ABS_PATH="`pwd`"
  popd
  RETURN="$ABS_PATH"
  return 0
}

# Given a file, return a new name in the form:
# .<filename>.<timestamp>.<ext>
# TODO: Test
create_file_name(){
  BASE=$(basename "$1")
  TIME=$(date +%s)
  RETURN="${BASE}${TIME}${EXT}"
  BASE=""
  TIME=""
  return 0
}

# Given a file, create it's full path in DIR.
# TODO: Test
create_trash_path(){
  verbose("Creating path for $1 in $DIR")
  get_absolute_path("$1")
  mkdir -p "$DIR/$RETURN" && verbose("Path created: $DIR/$RETURN")
  RETURN=""
  return 0
}

# Given a file, create it's symlink in DIR.
# TODO: Test
symlink_file(){
  verbose("Creating symlink for $1 in $DIR")
  get_absolute_path("$1")
  ABS_PATH="$RETURN"
  pushd "$DIR/$ABS_PATH"
  create_file_name()
  ln -s "$ABS_PATH/$RETURN" "$RETURN" && 
    verbose("Link created at: $DIR/$ABS_PATH/$RETURN")
  popd
  RETURN=""
  ABS_PATH=""
  return 0
}

# Given a file, rename it in it's current directory.
# TODO: Test
rename_file(){
  verbose("Renaming $1")
  get_absolute_path("$1")
  pushd "$RETURN"
  create_file_name()
  rename $(basename "$1") "$RETURN" && verbose("$1 renamed to $RETURN")
  popd
  RETURN=""
  return 0
}

# Given a file, rename and symlink it, according to the specified
# options.
# TODO: Test
# TODO: Make option aware.
trash_file(){
  verbose("Trashing $1")
  rename_file("$1") && create_trash_path("$1") &&  symlink_file("$1") &&
    verbose("$1 trashed!")
  return 0
}

# Given a list of files, rename and symlink them according to the
# specified options.
# TODO: Test
# TODO: make option aware.
trash_files(){
  for file in "${1[@]}"; do
    trash_file("${file}")
}

# MAIN
$FILES = parse_arguments()
trash_files($FILES)
