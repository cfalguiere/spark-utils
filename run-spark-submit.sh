#!/bin/bash
###
### build the command line and run a Spark program
###

scriptDir=$( dirname $( readlink -f  $0 ))
#echo "DEBUG - scriptDir is '$scriptDir'"
source ${scriptDir}/utils/functions-base.sh

source ${scriptDir}/utils/functions-spark-common.sh


###
### Main job
###

# -- loading configuration  from file
configFilePath=config/job.properties
configuration_load_from_file $configFilePath

log_message INFO "loaded configuration"
configuration_print_map

# -- overriding configuration from cli
configuration_load_from_cli

log_message INFO "resulting configuration"
configuration_print_map

# -- asserting required configuration are present
declare -a requiredConfigurationKeys=( "name" ) # Example
configuration_assert_provided "$requiredConfigurationKeys"
job_break_if_errors 21 "command line arguments"

###
### End of Main Job
###

# -- exit status
jobStatus=0
exit



