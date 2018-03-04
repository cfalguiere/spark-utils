#!/bin/bash
###
### build the command line and run a Spark program
###

#marche pas sur macOS criptDir=$( dirname $( readlink -f  $0 ))
scriptDir=$( dirname $0 )
#echo "DEBUG - scriptDir is '$scriptDir'"
source ${scriptDir}/utils/functions-base.sh

source ${scriptDir}/utils/functions-spark-common.sh


###
### Main job
###

log_message INFO "test info"

job_report_error "ceci est une erreur"
job_report_error "et une autre erreur"
job_report_error

job_print_errors
log_message DEBUG "There are $( job_get_nb_errors ) errors"

echo "ici"

job_break_if_errors 12 "parameter checks"

echo "la"

###
### End of Main Job
###

# -- exit status
jobStatus=0
exit



