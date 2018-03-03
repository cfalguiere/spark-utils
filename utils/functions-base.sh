#!/bin/bash

# -- Do not remove
[[ ${function_base_loaded:-false} == true ]] && return 0

###
### Common initializations
###

echo "INFO - Starting program $0"
[[ $* -gt 0 ]] && echo "INFO - with parameters '$@'"
echo "INFO - pid is '$$'"

set -Eeuo pipefail

JOB_STATUS=-1

trap "error_exit ${FUNCNAME:-UNK} $LINENO ${BASH_COMMAND}" SIGHUP SIGABRT SIGINT SIGQUIT SIGTERM ERR
trap "clean_exit" EXIT

echo "INFO - sourcing function-base ..."

###
### common functions
###

function error_exit {
  # -- show the error command location
  echo "ERROR - Line $2 ($1) : $3"
}

function clean_exit {
  # -- show the error location
  echo "INFO - cleanup on exit"
  echo "INFO - Exiting with status $JOB_STATUS"
}

###
### -- end of functions' definition
###

# -- Do not remove
echo "INFO - sourcing function-base Done"
function_base_loaded=true