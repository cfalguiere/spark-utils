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
# -- configurationMap : configuration properties
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
  [[ ${!level} -le $verbosityLevel ]] && printf "%s - %-5s - %s\n" "$(date '+%Y-%m-%d %H:%M:%S' )" $1 " ${2- }"
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
  exit $jobStatus
}

function clean_exit {
  # -- show the error location
  log_message INFO "cleanup on exit"
  [[ $jobStatus -eq 0 ]] && local  statusString="OK"
  local msg=$(  awk -v code=0 'BEGIN { FS = ";" } ; $1 == code { print $2 }' utils/status-catalog.csv )
  echo  "${statusString:-KO} - Exiting with status $jobStatus - ${msg:-UNDEFINED}"
  exit $jobStatus
}

trap "error_exit Line:$LINENO ${FUNCNAME:-UNK} ${BASH_COMMAND}" SIGHUP SIGABRT SIGINT SIGQUIT SIGTERM ERR
trap "clean_exit" EXIT

log_message INFO "sourcing function-base ..."


###
### common functions
###


###
### error management
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
  # -- arg1 : exit status
  # -- arg2 : step name
  [[ $# -ne 2 ]] && log_message WARN "Usage: job_break_if_errors <status> <message>"
  log_message DEBUG "job_break_if_errors for $2 - nb  errors is ${#__jobErrorsList[@]} "
  [[ ${#__jobErrorsList[@]} -gt 0 ]] && {
      log_message ERROR "There were ${#__jobErrorsList[@]} errors at step ${2:-UNDEFINED}:"
      job_print_errors
      log_message DEBUG "status = $1"
      jobStatus=${1:-1}
      log_message DEBUG "jobStatus = $jobStatus"
      error_exit "Too many errors after step ${2:-UNDEFINED_STEP}"
  }
  return 0
}

function job_get_nb_errors {
  # -- print out the number of errors
  echo ${#__jobErrorsList[@]}
}

###
### configuration
###

#declare -A configurationMap=()
declare -A configurationMap=(  )

function configuration_load_from_file {
  # -- load the configuration file
  # -- arg1 : file path
  [[ $# -ne 1 ]] && log_message WARN "Usage: configuration_load_from_file <file_path>"
  local configurationPath=${1:- }
  log_message DEBUG "configurationPath = $configurationPath"
  # -- checks whether the file exists, is readable and not empty
  [[ -z $configurationPath ]] && job_report_error "configuration file name is empty"
  [[ ${#__jobErrorsList[@]} -gt 0 ]] && return
  [[ -f $configurationPath ]] || job_report_error "configuration file was not found at $configurationPath"
  [[ ${#__jobErrorsList[@]} -gt 0 ]] && return
  [[ -r $configurationPath ]] || job_report_error "configuration file cannot be read at $configurationPath"
  [[ ${#__jobErrorsList[@]} -gt 0 ]] && return
  [[ -s $configurationPath ]] || job_report_error "configuration file  at $configurationPath is empty"
  [[ ${#__jobErrorsList[@]} -gt 0 ]] && return

  log_message DEBUG  "Loading Configuration map from $configurationPath ..."
  set +u
  while IFS='=' read -r key value
  do
    log_message DEBUG "key = $key, value = $value"
    configurationMap[${key}]="${value:-}"
  done < "$configurationPath"
  configurationMap['configurationFile']="$configurationPath"
  set -u
  log_message INFO "Loading Configuration map from $configurationPath DONE"
}

function configuration_print_map {
  local nbValues=${#configurationMap[@]}
  [[  $nbValues -eq 0 ]] && log_message INFO "configurationMap is empty" || {
    log_message INFO "Configuration map has $nbValues entries:"
    log_message INFO "$( declare -p  configurationMap )"
  }
  log_message DEBUG "end of table"
  return 0
}

###
### -- end of functions' definition
###

# -- Do not remove
log_message INFO "sourcing function-base DONE"
function_base_loaded=true
