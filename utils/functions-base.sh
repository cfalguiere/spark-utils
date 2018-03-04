#!/bin/bash

# -- Do not remove
[[ ${function_base_loaded:-false} == true ]] && return 0

###
### Documentation
###
# -- functions' names  always use lower_case with underscore
# -- program names always use lower-case with hyphen


# -- Environment variables - always use UPPER_CASE with underscore
# -- ---------------------
# -- VERBOSITY_LEVEL : values from 1 (quite quiet) to 5 (trace)

# -- Global variables - always use camelCase
# -- ---------------------
# -- scriptDir : folder ot the main program
# -- jobStatus : exit code
# -- verbosityLevel : actual verbosity parameter
# -- jobErrosList : list of check and validation errors

###
### End of documentation
###

###
### Common initializations
###

jobStatus=-1

set -Eeuo pipefail

# -- verbosity

verbosityLevel=${VERBOSITY_LEVEL:-2}
#echo "DEBUG - verbosityLevel is $verbosityLevel"
[[ $verbosityLevel -ge 5 ]] && set -xv

declare -a __mapevels
ERROR=1
WARN=2
INFO=3
DEBUG=4

function log_message {
  # -- log the message depending on verbosity
  # -- arg 1 : level from ERROR to DEBUG
  # -- arg 2 : message
  level=$1
  [[ ${!level:-0} =~ [1-4] ]] || echo "unknown log level $1"
  [[ ${!level} -le $verbosityLevel ]] && echo "$(date) - $1 - $2"
  return 0
}

# -- header

log_message INFO "Starting program $0"
[[ $* -gt 0 ]] && log_message INFO "with parameters '$@'"
log_message INFO "pid is '$$'"

# -- traps

function error_exit {
  # -- show the error command location
  log_message ERROR "Line $2 ($1) : $3"
}

function clean_exit {
  # -- show the error location
  log_message INFO "cleanup on exit"
  log_message INFO "Exiting with status $jobStatus"
}

trap "error_exit ${FUNCNAME:-UNK} $LINENO ${BASH_COMMAND}" SIGHUP SIGABRT SIGINT SIGQUIT SIGTERM ERR
trap "clean_exit" EXIT

log_message INFO "sourcing function-base ..."

###
### common functions
###


###
### -- end of functions' definition
###

# -- Do not remove
log_message INFO "sourcing function-base Done"
function_base_loaded=true