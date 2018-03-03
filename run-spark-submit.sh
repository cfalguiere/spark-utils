#!/bin/bash
###
### build the command line and run a Spark program
###

#marche pas sur macOS criptDir=$( dirname $( readlink -f  $0 ))
scriptDir=$( dirname $0 )
echo "DEBUG - scriptDir is '$scriptDir'"
source ${scriptDir}/utils/functions-base.sh

source ${scriptDir}/utils/functions-spark-common.sh


###
### Main job
###

function A {
dgbsfgshdfn
}

A

###
### End of Main Job
###

# -- exit status
JOB_STATUS=0
exit $JOB_STATUS



