#!/usr/bin/env bash
#
# Shorthands and various functions for regular bash usage

# VARIABLES and ALIASES ########################################################

alias ..='cd ..' # don't do cd ..; cd..; ... this messes with OLDPWD value
alias ...='cd ../..'

alias ll='ls -Ghlrt'
alias lla='ls -GAhlrt'
alias said_yes='(( $? == 0 ))'  # for use with yes_no func. don't use alone
alias said_no='(( $? != 0 ))'   # same as above
alias pushd='pushd 1>/dev/null' # remember, redirections are removed before cmd
alias popd='popd 1>/dev/null'   #   is executed - placement doesn't matter

# FUNCTIONS ####################################################################

################################################################################
# Get Yes/No response
# Globals:
#   None
# Arguments:
#   PROMPT) message to display before obtaining yes/no response. note that this 
#           argument may instead be fed into the function via stdin
# Outputs:
#   None
# Returns:
#   0 if answered positively, 1 if answered negatively
################################################################################
yes_no() {
  if [[ -n "$1" ]]; then
    echo -en "\n$1" # prompt can be fed through arg...
  else
    echo -en "\n$(cat -)" # ...or through stdin
  fi
	
  local -l ANS=
  until [[ -n "${ANS}" ]]; do
    read ANS </dev/tty # read from terminal
    case "${ANS}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      *)
        echo -en '\nInvalid input. Please respond with (Y|N): '
        ANS=
        ;;
    esac
  done
}
