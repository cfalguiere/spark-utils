#!/bin/bash

#marche pas sur macOS criptDir=$( dirname $( readlink -f  $0 ))
scriptDir=$( dirname $0 )
echo "DEBUG - scriptDir is '$scriptDir'"
source ${scriptDir}/utils/functions-base.sh

source ${scriptDir}/utils/functions-spark-common.sh


###
### Main job
###


JOB_STATUS=0
exit $JOB_STATUS



