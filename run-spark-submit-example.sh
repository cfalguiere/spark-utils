#!/bin/bash
###
### build the command line and run a Spark program
###

scriptDir=$( dirname $( readlink -f  $0 ))
#echo "DEBUG - scriptDir is '$scriptDir'"
source ${scriptDir}/utils/functions-base.sh

source ${scriptDir}/utils/functions-spark-common.sh

function usage {
   echo "Usage: $0 [-f <config-file>] [ --opt1 val1 ] [ --opt2 val2  ] >&2
   echo "Usage: $0 -h >&2
}

###
### Main arguments
###

while getopts :f:h opt "$@"; do
  case $opt in
    h)
      usage
      jobStatus=0
      exit
      ;;
    f)
      configFilePath=$OPTARG
      shift 2
      log_message DEBUG "configFilePath = $configFilePath"
      ;;
    \?)
      # -- ignore other options right now
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      jobStatus=21
      exit
      ;;
  esac
done
jobArgs=( "$@" )

###
### Main job
###

# -- loading configuration  from file
[[ ! -z ${configFilePath:-} ]] && {
  configuration_load_from_file $configFilePath
  #log_message INFO "loaded configuration"
  #configuration_print_map
}

# -- overriding configuration from cli
configuration_load_from_cli

log_message INFO "resulting configuration"
configuration_print_map

# -- asserting required configuration are present
declare -a requiredConfigurationKeys=( "name" ) # Example
configuration_assert_provided "$requiredConfigurationKeys"
job_break_if_errors 21 "job configuration"

# -- prepare and run spark-submit

spark_common_setup
spark_common_print_options
spark_common_submit "arg1" "arg2"

###
### End of Main Job
###

# -- exit status
jobStatus=0
exit



