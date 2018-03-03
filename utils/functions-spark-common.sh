#!/bin/bash

# Do not remove
[[ ${function_spark_common_loaded:-false} == true ]] && return 0

source ${scriptDir}/utils/functions-base.sh

echo "INFO - sourcing function-spark-common ..."

###
### Spark utils functions
###



# Do not remove
echo "INFO - sourcing function-spark-common Done"
function_spark_common_source_loaded=true