#!/bin/bash
# This really ought to be written in a real language. Bash issues with
# arrays are the lolzyist. So are bash issues for everything else.
#
# This script is meant to be a drop-in alias for rm, that will, instead
# of unlinking a file, rename is to .<filename>.<timestamp>.trash in
# it's current directory, and create a symlink to the file in ~/.trash.
# The folder and file extension are configurable, as are whether the
# file is renamed, symlinked, or simply moved into the trash folder.
#
# Example:
# trash.sh -rf ~/stuff/stuff-i-dont-want
# trash.sh -rf ~/stuff/stuff-i-dont-want/*
# trash.sh -rf --no-preserve-root /

copyright(){
cat << EOF
Copyright (c) 2012 William J. Bowman <wjb@williamjbowman.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
EOF
}

usage()
{
cat << EOF
Usage: ${0} [OPTION]... FILE...
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
  ${0} -- -foo

  ${0} ./-foo

Note that if you use trash to remove a file, it will totally be possible
to recover all of its contents. The file will simply be renamed to
.<filename>.<timestamp>.<ext> (default ext is trash). A symlink can also
be found in the trash folder (default is ~/.trash).
EOF
}

error(){
  echo "$0: ERROR: ${1}">&2
  exit ${2}
}

verbose(){
  if [ $VERBOSE ]; then
    echo "${1}"
  fi
}

# TODO: DAMNIT I NEED SOME VIM MACROS/TEMPLATES.
version(){ 
cat << EOF
trash 1.0

EOF

copyright

cat << EOF

Written by William J. Bowman <wjb@williamjbowman.com>
EOF
}

# Parse arguments and input, side-effecting global variables used to
# options. Returns a list of files to trash.
parse_arguments(){
  FORCE=
  VERBOSE=
  RETURN=
  PARENTDEVICE=
  RECURSIVE=
  INTERACTIVE=
  ONEFILESYSTEM=
  NOPRESERVE=
  PRESERVE=0
  EXT="trash"
  DIR="${HOME}/.trash"
  NOTRASHDIR=
  ONLYTRASHDIR=

  local TEMP
  TEMP=`getopt -o fiIrRvhe:t:no --long \
force,recursive,verbose,help,extension:,trashdir:,notrashdir,onlytrashdir,one-file-system,no-preserve-root,preserve-root,interactive::,version\
  -n "${0}" -- "${@}"`

  if [ $? != 0 ] ; then error "Parsing arguments failed" 2 ; fi

  eval set -- "$TEMP"

  while true ; do
    case "$1" in
      -f|--force) verbose "-f set" ; FORCE=0 ; shift ;;
      -i) verbose "-i set" ; INTERACTIVE=1 ; shift ;;
      -I) verbose "-I set" ; INTERACTIVE=2 ; shift ;;
      -R|-r|--recursive) verbose "-r set"; RECURSIVE=0 ; shift ;;
      -v|--verbose) VERBOSE=0 ; verbose "-v set" ; shift ;;
      -h|--help) usage ; exit 0 ;;
      -e|--extension) verbose "-e set to ${2}" ; EXT="${2}" ; shift 2 ;;
      -t|--trashdir) verbose "-t set to ${2}" ; DIR="${2}" ; shift 2 ;;
      -n|--notrashdir) verbose "-n set" ; NOTRASHDIR=0 ; shift ;;
      -o|--onlytrashdir) verbose "-o set" ; ONLYTRASHDIR=0 ; shift ;;
      --one-file-system) verbose "--one-file-system set" ;
        ONEFILESYSTEM=0 ; shift ;;
      --no-preserve-root) verbose "--no-preserve-root set" ;
        NOPRESERVE=0 ; shift ;;
      --preserve-root) verbose "--preserve-root set" ; PRESERVEROOT=0 ;
        shift ;; 
      --interactive) verbose "--interactive set" 
          case "${2}" in
            always) INTERACTIVE=1 ;;
            never) INTERACTIVE= ;;
            once) INTERACTIVE=2 ;;
            "") INTERACTIVE=1 ;;
          esac 
          shift 2 ;;
      --version) version ; exit 0 ;;
      --) shift ; break ;;
      *) echo "Invalid argument: ${1}" ; exit 3 ;;
    esac
  done
  RETURN=
  i=0
  for file do RETURN[$i]="${file}"; let i+=1; done
  return 0
}

# Given a file, check if the file exists, and if that means we should
# signal an error. If so, signal an error, otherwise don't.
test_exists(){
  if [ ! -e "${1}" ] && [ ! -h "${1}" ]; then
    if [ ! $FORCE ]; then
      # TODO: Come up with error nums
      error "File ${1} does not exists." 1 
    fi
    verbose "File does not exists, but -f set."
    return 1
  fi
  return 0
}

test_root(){
  local NAME=$(basename -- "${1}")
  if [ "/" = "${NAME}" ]; then
    if [ ! $NOPRESERVE ]; then
      error "Preserve set, aborting to preserve /" 2
    fi
    verbose "No preserve set, trashing /"
  fi
  return 0
}

test_one_filesystem(){
  local DEVICE=$(stat -c %D -- "${1}")
  if [ "" = "${PARENTDEVICE}" ]; then
    PARENTDEVICE="${1}"
    DEVICE=
    return 0
  fi
  if [ "${DEVICE}" != "${PARENTDEVICE}" ]; then
    if [ $ONEFILESYSTEM ]; then
      verbose "One filesystem specified, skipping ${1}"
      return 1
    fi
    verbose "One filesystem not specified, trashing this one too."
  fi
  return 0
}

# Prompts the user if they wish to delete the file, if INTERACTIVE is
# not 0
prompt(){
  if [ $INTERACTIVE ] && [ ! $FORCE ]; then
    if [ "$INTERACTIVE" -eq 2 ]; then
      INTERACTIVE=
    fi
    if [ "" = "${2}" ]
    then
      local TYPE=`stat -c %F -- "${1}"`
      local STR="$0: trash $TYPE ${1}? (y/N) "
    else
      STR="${2}"
    fi
    echo "${STR}"
    local ANS
    read ANS
    case "${ANS}" in 
      y|Y)
        verbose "Received ${ANS}; trashing file"
        return 0
        ;;
      *)
        return 1
        ;;
    esac
  fi
}

# Given a file, return it's absolute path.
get_absolute_path(){
  pushd $(dirname -- "${1}")>/dev/null
  local ABS_PATH=`pwd`
  popd>/dev/null
  RETURN="${ABS_PATH}"
  return 0
}

# Given a file, return a new name in the form:
# <filename>.<timestamp>.<ext>
create_file_name(){
  local BASE=$(basename -- "${1}")
  local TIME=$(date +%s)
  RETURN="${BASE}.${TIME}.${EXT}"
  return 0
}

# Given a file, returns the full path to it's home in the trash
get_trash_path(){
  get_absolute_path "${1}"
  RETURN="${DIR}/${RETURN}"
  return 0
}

# Given a file, create it's full path in DIR.
create_trash_path(){
  verbose "Creating path for ${1} in ${DIR}"
  get_trash_path "${1}"
  mkdir -p "${RETURN}" && verbose "Path created: ${RETURN}"
  RETURN=
  return 0
}

# Given a file, create it's symlink in DIR.
symlink_file(){
  verbose "Creating symlink for ${1} in ${DIR}"
  get_absolute_path "${1}"
  local ABS_PATH="${RETURN}"
  create_file_name "${1}"
  ln -s -- "${ABS_PATH}/${RETURN}" "${DIR}/${ABS_PATH}/${RETURN}" && 
    verbose "Link created at: ${DIR}/${ABS_PATH}/${RETURN}"
  RETURN=
  return 0
}

# Given a file, rename it in it's current directory.
rename_file(){
  verbose "Renaming ${1}"
  get_absolute_path "${1}"
  local ABS_PATH="${RETURN}"
  create_file_name "${1}"
  local NAME=$(basename -- "${1}")
  mv -- "${ABS_PATH}/${NAME}" "${ABS_PATH}/.${RETURN}" && 
    verbose "${1} renamed to .${RETURN}"
  RETURN=
  return 0
}

trash_directory(){
  if [ ! $RECURSIVE ]; then
    verbose "-r not set, so not trashing directory ${1}"
    echo "${0}: cannot remove '${1}': Is a directory"
    return 1
  fi
  verbose "-r set, trashing directory ${1}"
  trash_files "${1}"/*
  trash_file "${1}" 0
  return 0
}

move_file(){
  verbpse "Moving file to trash, as --onlytrash is set."
  get_trash_path
  mv -- "${1}" "${RETURN}"
}

# Given a file, rename and symlink it, according to the specified
# options.
trash_file(){
  verbose "Trashing ${1}"
  test_exists "${1}"
  if [ "$?" != "0" ]; then
    return 0
  fi
  prompt "${1}"
  if [ "$?" != "0" ]; then
    return 0
  fi
  test_root "${1}"
  # XXX: Second parameter is a hack so I can reuse this function for
  # trashing directories. Without, trying to do so would cause infinite
  # recursion.
  if [ -d "${1}" ] && [ ! $2 ]
  then
    test_one_filesystem "${1}"
    trash_directory "${1}"
  else
    if [ ! $NOTRASHDIR ]; then 
      create_trash_path "${1}"
    fi

    if [ $ONLYTRASH ]
    then
      move_file "${1}"
    else
      rename_file "${1}"
      symlink_file "${1}"
    fi
    verbose "${1} trashed!"
  fi
  return 0
}

# Given a list of files, rename and symlink them according to the
# specified options.
trash_files(){
  if [ "${#@}" -gt 3 ]
  then
    prompt "${0}: remove all arguments?"
  else
    if [ $RECURSIVE ]; then
      prompt "${0}: remove all arguments recursively?"
    fi
  fi 

  for file in "${@}"; do
    trash_file "${file}"
  done
}

# MAIN
parse_arguments "${@}"
trash_files "${RETURN[@]}"
