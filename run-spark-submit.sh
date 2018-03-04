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

log_message INFO "before loading configuration"
configuration_print_map

log_message INFO " loading configuration"
configuration_load_from_file config/job.properties

log_message INFO "after loading configuration"
configuration_print_map

job_break_if_errors 11 "configuration checks"

#log_message INFO "test info"

#job_report_error "ceci est une erreur"
#job_report_error "et une autre erreur"
#job_report_error

#job_print_errors

job_break_if_errors 12 "parameter checks"

#
###
### End of Main Job
###

# -- exit status
jobStatus=0
exit



