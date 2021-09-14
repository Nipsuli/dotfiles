#!/bin/bash
#
# Collection of functions to be used to setup and confugure personal/work
# computer,
set -e

#######################################
# Ensure EMAIL variable is set. Exits if not availble
# Globals:
#   EMAIL
# Arguments:
#   None
#######################################
nipsulidotfiles::check_email_var() {
  if [ -z "${EMAIL}" ]; then
    echo "No EMAIL environment variable available, bailing"
    exit 1
  fi
}

#######################################
# Appends text to file if it does not exist in the file yet
# Globals:
#   None
# Arguments:
#   path to file
#   text to append
#######################################
nipsulidotfiles::append_to_file() {
  if [ -z "${1}" ] || [ -z "${2}" ]; then
    echo "Invalid usage, needs 2 argumets: filepath and line to appends"
    exit 1
  fi
  local file="$1"
  local line="$2"
  grep -qF -- "$line" "$file" || echo "$line" | sudo tee -a "$file"
}


#######################################
# Helper to append lines to _all_ the different shell files with single
# command currently bash and zsh, due Macs transition from bash to zsh as
# the default shell.
#
# In case the line needs a shell specific part there is %SHELL_NAME% macro
# that is replaced with the shell name
# Globals:
#   None
# Arguments:
#   text to append
#######################################
nipsulidotfiles::append_to_shell_files() {
  if [ -z "${1}" ]; then
    echo "Invalid usage, needs an argument: line to append to shell files"
    exit 1
  fi
  touch ~/.bash_profile
  touch ~/.zshrc
  local shell_name="bash"
  local formated_str=${1/\%SHELL_NAME\%/${shell_name}}
  nipsulidotfiles::append_to_file ~/.bash_profile "$formated_str"
  local shell_name="zsh"
  local formated_str=${1/\%SHELL_NAME\%/${shell_name}}
  nipsulidotfiles::append_to_file ~/.zshrc "$formated_str"
}

# END OF HELPERS
main() {
  echo "This is helper module, nothing to execute here"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
  nipsulidotfiles::append_to_shell_files 'echo "foo bar %SHELL_NAME% bax"'
fi