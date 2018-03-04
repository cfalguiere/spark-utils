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
# -- jobArgs : command line arguments
# -- jobStatus : exit code
# -- jobPID : PID of this script
# -- verbosityLevel : actual verbosity parameter
# -- configurationMap : configuration properties
# -- __jobErrorsList : list of check and validation errors

###
### End of documentation
###

###
### Common initializations
###

jobStatus=-1
jobArgs=( "$@" ) # work around -set -u but - $* and  $@ not bound while they exist by default
jobPID=$$

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

function log_header {
  log_message INFO "Starting program $0"
  [[ ${#jobArgs[@]} -gt 0 ]] && {
      log_message INFO "with parameters:"
      local i=1
      for arg in "${jobArgs[@]}"
      do
        log_message INFO "[$i]: $arg"
        let i+=1
      done
  }

  log_message INFO "pid is $jobPID"
}

log_header

# -- traps

function error_exit {
  # -- show the error command location
  [[ $verbosityLevel -ge 5 ]] && set -xv || set +x
  log_message ERROR "$@"
  exit $jobStatus
}

function cleanup {
  log_message INFO "cleanup on exit"
  # TODO
}

function clean_exit {
  cleanup

  [[ $jobStatus -eq 0 ]] && local  statusString="OK"
  local statusCatalogPath="config/status-catalog.csv"
  [[ -f $statusCatalogPath ]] && local msg=$(  awk -v code=$jobStatus 'BEGIN { FS = ";" } ; $1 == code { print $2 }' $statusCatalogPath )  || log_message WARN "Message catalog was not found ar $statusCatalogPath"

  echo  "${statusString:-KO} - Exiting with status $jobStatus - ${msg:-UNDEFINED_MESSAGE}"
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
    log_message DEBUG "configuration_load_from_file: key[0]  ${key[0]:-} "
    log_message DEBUG "configuration_load_from_file: key##+( )  ${key##+( )} "
    [[ ! ${key[0]:-} =~ '#' ]] && [[ ! -z ${key##+( )} ]]  && {
      log_message DEBUG "key = $key, value = $value"
      configurationMap[${key}]="${value:-}"
    }
  done < "$configurationPath"
  configurationMap['configurationFile']="$configurationPath"
  set -u
  log_message INFO "Loading Configuration map from $configurationPath DONE"
}


function configuration_load_from_cli {
  # -- load the configuration from command line argument
  # -- args : args of the program (jobArgs)
  log_message DEBUG "configuration_load_from_cli: received: $( declare -p  jobArgs )"
  local currentKey=""
  for arg in "${jobArgs[@]}"
  do
    log_message DEBUG "configuration_load_from_cli: found $arg"
    [[ $arg =~ ^-- ]] && {
       local key=${arg:2}
       log_message DEBUG "configuration_load_from_cli: arg $key is a key"
       #local actualKey="job.$key"
       local actualKey="$key"
       [[ -z currentKey ]] && currentKey=${actualKey} || {
           log_message DEBUG "configuration_load_from_cli: adding $currentKey with no value"
           configurationMap[$actualKey]=""
           currentKey="${actualKey}"
       }
    } || {
       log_message DEBUG "configuration_load_from_cli: arg $arg is a value"
       [[ -z $currentKey ]] && {
           job_report_error "configuration_load_from_cli: found arg $arg while no key is defined"
       } || {
          log_message DEBUG "configuration_load_from_cli: adding $currentKey with value $arg"
          configurationMap[$currentKey]="$arg"
          currentKey=""
       }
    }
  done
}

function configuration_print_map {
  # -- print out configurationMap
  local nbValues=${#configurationMap[@]}
  [[  $nbValues -eq 0 ]] && log_message INFO "configurationMap is empty" || {
    log_message INFO "Configuration map has $nbValues entries:"
    log_message INFO "$( declare -p  configurationMap )"
  }
  log_message DEBUG "end of table"
  return 0
}

function configuration_assert_provided {
  # -- check whether required parameters are provided
  # -- arg1 : list of keys
  local keys=( "$1" )
  log_message DEBUG "configuration_assert_provided: received: $( declare -p  keys )"
  for key in "${keys[@]}"
  do
       log_message DEBUG "configuration_assert_provided: looking for key $key"
       local value="${configurationMap[$key]:-}"
       log_message DEBUG "configuration_assert_provided: found ${value:-} for key $key"
       [[ -z ${value:-} ]] &&  job_report_error "configuration_assert_provided: required configuration parameter $key is missing "
  done
  return 0
}

###
### -- end of functions' definition
###

# -- Do not remove
log_message INFO "sourcing function-base DONE"
function_base_loaded=true
