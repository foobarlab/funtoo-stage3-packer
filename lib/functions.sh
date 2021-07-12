#!/bin/bash -e

require_commands() {
  local command;
  for command in $@; do
    command -v $command >/dev/null 2>&1 || { echo "Command '${command}' required but it's not installed.  Aborting." >&2; exit 1; }
  done
}

version_lte() {
    [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

version_lt() {
    [ "$1" = "$2" ] && return 1 || version_lte $1 $2
}
