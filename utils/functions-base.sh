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
# -- jobPID : PID of this script
# -- verbosityLevel : actual verbosity parameter
# -- __jobErrosList : list of check and validation errors

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
jobPID=$$

# -- traps

function error_exit {
  # -- show the error command location
  log_message ERROR "$@"
  exit
}

function clean_exit {
  # -- show the error location
  log_message INFO "cleanup on exit"
  log_message INFO "Exiting with status $jobStatus"
  exit $jobStatus
}

trap "error_exit Line:$LINENO ${FUNCNAME:-UNK} ${BASH_COMMAND}" SIGHUP SIGABRT SIGINT SIGQUIT SIGTERM ERR
trap "clean_exit" EXIT

log_message INFO "sourcing function-base ..."

###
### common functions
###

declare __jobErrorsList=()

function job_report_error {
  # -- add an error to jobErrorsList
  # -- arg1 : error message
  [[ $# -ne 1 ]] && log_message WARN "Usage: job_report_error <message>"
  __jobErrorsList+=( "${1:-UNKNOWN ERROR}" )
}

function job_print_errors {
  # -- print out the list of errors
  [[ $# -ne 0 ]] && log_message WARN "Usage: job_print_errors"
  local i=1
  for e in "${__jobErrorsList[@]}"
  do
    log_message ERROR "[$i]: $e"
    let i+=1
  done
}

function job_break_if_errors {
  # -- exit when there are errors in __jobErrorsList
  # -- arg1 : status
  # -- arg2 : message
  [[ $# -ne 2 ]] && log_message WARN "Usage: job_break_if_errors <status> <message>"
  [[ ${#__jobErrorsList[@]} -gt 0 ]] && {
      log_message ERROR "There were ${#__jobErrorsList[@]} errors at step ${2:-UNDEFINED}"
      job_print_errors
      log_message DEBUG "status = $1"
      jobStatus=${1:-1}
      log_message DEBUG "jobStatus = $jobStatus"
      error_exit "Too many errors after step ${2:-UNDEFINED_STEP}"
  }
}

function job_get_nb_errors {
  echo ${#__jobErrorsList[@]}
}

###
### -- end of functions' definition
###

# -- Do not remove
log_message INFO "sourcing function-base Done"
function_base_loaded=true