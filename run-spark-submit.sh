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

log_message ERROR "test error"
log_message WARN "test warn"
log_message INFO "test info"
log_message DEBUG "test debug"
#log_message TRACE "test trace"

###
### End of Main Job
###

# -- exit status
jobStatus=0
exit $jobStatus



