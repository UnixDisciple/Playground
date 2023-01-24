#!/usr/bin/env bash
#
# Convenience functions for working with python

# REQUIRES #####################################################################

. utility.sh

# VARIABLES and ALIASES ########################################################

alias python='python3'

# FUNCTIONS ####################################################################

################################################################################
# Make a python virtual environment
# Globals:
#   OPTIND) sets to 1, does not reset
# Arguments:
#   None
# Options:
#   -d DIR) directory in which to establish virtual environment
#   -f ) do not prompt user for confirmation before proceeding
# Outputs:
#   None
# Returns:
#   0 on successful creation of venv, non-zero otherwise
################################################################################
py::create_venv() {
  local -i FORCE=0
  local DIR="${PWD}"

  OPTIND=1 # reset in case getopts has been called elsewhere in current shell
  while getopts 'fd:' ARG; do
    case "${ARG}" in
      d)
        DIR="${OPTARG}"
        [[ ! -d "${DIR}" ]] \
          && { echo "Invalid directory: ${DIR}"
	       return 1; }
        ;;
      f) FORCE="${OPTIND}" ;;
      ?) return 1 ;;
    esac
  done

  if ! (( ${FORCE} )); then
    yes_no <<HERE
Create new virtual environment in ${DIR}?
Note that this will overwrite an existing virtual enviornment.
(y|n): 
HERE

    # below is a bit tricky.
    # in english: if the user says no to the original query, or they say yes to
    # the original query but no to the second query, then do nothing and exit.
    # the second query only comes up if they say yes to the first and .venv
    # already exists in DIR. strongly cautions against accidental overwrite
    if said_no \
         || { [[ -d "${DIR}/.venv" ]] \
                && ! yes_no "You sure? .venv exists in ${DIR} (Y|N): "; }; then
      echo -e "\nSkipping virtual environment creation"
      return 1 # although not an error, used to indicate that venv not made
    fi
  fi

  # create venv
  pushd "${DIR}"
  rm -rf .venv
  python -m venv .venv \
    || { echo "Failed to make virtual environment"
         popd; return 1; }
  echo -e "\nVirtual environment created successfully in ${DIR}"
  popd
}

################################################################################
# Python virtual environment manip
# Globals:
#   OPTIND) sets to 1, does not reset
# Options:
#   -d DIR) directory in which to establish/find virtual environment
#   -r REQ) requirements file which will be used to install packages in venv.
#           must be absolute path!
#   -h ) display usage
#   -f ) do not prompt user for confirmation before proceeding with any mode
#   -a ) for modes that support it, activate the venv after completing the task
#        associated with mode
# Arguments:
#   MODE) action to take with regard to venv. modes include: make, delete,
#         install, freeze, and activate. case insensitive. 
# Outputs:
#   None
# Returns:
#   0 on success, non-zero on failure
################################################################################
py::venv() {
  usage() {
    cat <<HERE
usage: py::venv [-h] [-f] [-a] [-d DIR] [-r REQ] MODE
 -h     display usage
 -f     do not prompt user for confirmation before proceeding with any mode
 -a     for modes that support it, activate the venv after completing the mode task
 -d DIR directory in which to establish/find virtual environment
 -r REQ requirements file which will be used to install packages in venv. must
        be absolute path

 MODE   make|delete|install|freeze|activate

HERE
  }
    
  local -i FORCE=0 ACTIVATE=0
  local REQ= DIR="$(pwd)"

  # get options
  OPTIND=1 # reset in case OPTIND has been called elsewhere in current shell
  while getopts 'afhd:r:' ARG; do
    case "${ARG}" in
      d)
        DIR="${OPTARG}"
        [[ ! -d "${DIR}" ]] \
          && { echo "Invalid directory: ${DIR}"
               return 1; }
        ;;
      r)
        REQ="${OPTARG}"
        [[ ! -f "${REQ}" ]] \
          && { echo "Invalid requirements file: ${REQ}"
               return 1; }
        ;;
      a) ACTIVATE="${OPTIND}" ;;
      f) FORCE="${OPTIND}" ;;
      h) { usage; return 0;} ;;
      ?) { usage; return 1;} ;;
    esac
  done

  # get mode
  [[ -z "${!OPTIND}" ]] && { usage; return 1; }
  local -lr MODE="${!OPTIND}"

  # main exec
  pushd "${DIR}"
  local -i VENV_SET="$({ ! [[ -d .venv ]]; echo $?; })"

  case "${MODE}" in
    make|mk)
      ! (( ${FORCE} )) && unset FORCE
      py::create_venv ${FORCE:+ -f}
			
      (( $? == 0 )) && if [[ -n "${REQ}" ]]; then
        py::venv -r "${REQ}" -d "${DIR}" install
      fi # need if stmt because we still want 0 ec if REQ isnt passed
      ;;

    *) # all remaining modes need to test for the presence of .venv
      ! (( ${VENV_SET} )) \
        && { echo "No virtual environment to ${MODE} in ${DIR}";
	     popd; return 1; }
      ;;& # fall through

    # normal case execution flow for remaining clauses
    install)
      [[ -z "${REQ}" ]] \
        && { echo "Must provide requirements file";
             popd; return 1; }
      py::venv activate \
        && python -m pip install -r "${REQ}" \
          && deactivate
      ;;
		
    del|delete)
      (( ${FORCE} )) \
        || yes_no "Delete .venv in ${DIR}? (Y|N): " \
        && rm -rf "${DIR}/.venv"
       ;;
		
    freeze|brrr)
      py::venv activate \
        && python -m pip freeze \
          && deactivate
      ;;

    act|activate) . .venv/bin/activate ;;
    *) { usage; popd; return 1; } ;;
  esac \
     && (( ${ACTIVATE} )) && py::venv activate # only attempt activate if good case

  popd
}
