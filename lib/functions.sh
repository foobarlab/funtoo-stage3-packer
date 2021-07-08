#!/bin/bash -e

require_commands() {
  local command;
  for command in $@; do
    command -v $command >/dev/null 2>&1 || { echo "Command '${command}' required but it's not installed.  Aborting." >&2; exit 1; }
  done
}
