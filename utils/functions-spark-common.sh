#!/bin/bash

# -- Do not remove
[[ ${function_spark_common_loaded:-false} == true ]] && return 0

###
### Documentation
###
# -- spark utility functions

# -- Global variables - always use camelCase
# -- ---------------------
# -- __requiredConfigurationKeys : list of required configuration properties in config file or command line

# -- dependencies
# -- ---------------------
# -- utils/functions-base.sh
# -- verbosityLevel
# -- configurationMap

# -- Properties
# -- ---------------------
# -- --job.dry-run : does not submit
# -- see example in utils/job.properties

###
### End of documentation
###


source ${scriptDir}/utils/functions-base.sh

log_message INFO "sourcing function-spark-common ..."

###
### Spark utils functions
###

declare -A sparkLeadingArgsMap              # --k v  (for master, deploy-mode, num-executors)
declare -A sparkConfMap                           # --conf k=v (for spark.driver.cores ...)
declare -A sparkDriverDExtraMap              # --conf spark.driver.JavaExtraOptions=" -Dk=v " (for log4  options)
declare -A sparkDriverXXExtraMap            # --conf spark.driver.JavaExtraOptions=" -XX:+k  " (for GC options)
declare -A sparkExecutorDExtraMap          # --conf spark.executor.JavaExtraOptions=" -Dk=v " (for log4  options)
declare -A sparkExecutorXXExtraMap        # --conf spark.executor.JavaExtraOptions=" -XX:+k " (for GC  options)
declare -A sparkTrailingArgsMap                # --k v  (for class and package)

declare -a  __requiredConfigurationKeys=( "class" "package" )

function spark_common_setup {
  # -- setup  tables from configurationMap
  # -- requires :  verbosityLevel,  configurationMap, sparkArgsMap, sparkConfMap, sparkDriverExtraMap, sparkExecutorExtraMap

  # -- prerequisites
  configuration_assert_provided "$__requiredConfigurationKeys"
  job_break_if_errors 31 "spark command line setup"

  # -- leading args
  log_message DEBUG "spark_common_setup:  setting up sparkLeadingArgsMap"
  [[ $verbosityLevel -ge 4 ]] &&  sparkLeadingArgsMap['verbose']=""
  local jobName="${configurationMap['name']:-}"
  [[ ! -z "$jobName" ]] &&  sparkLeadingArgsMap['name']="$jobName"
  sparkLeadingArgsMap['master']="${configurationMap['master']:-yarn}"
  sparkLeadingArgsMap['deploy-mode']="${configurationMap['deploy-mode']:-cluster}"

  # -- trailing args
  log_message DEBUG "spark_common_setup:  setting up sparkTrailingArgsMap"
  sparkTrailingArgsMap['class']="${configurationMap['class']}"

  # -- spark. driver. and executor.
  log_message DEBUG "spark_common_setup:  setting up sparkConfMap"
  local category=""
  for  k in  "${!configurationMap[@]}"
  do
      category=""
      [[ $k =~ spark..* ]] && category="sparkConf"
      [[ $k =~ driver.jeo.D.* ]] &&  category="sparkDriverD"
      [[ $k =~ driver.jeo.XX.* ]] && category="sparkDriverXX"
      [[ $k =~ executor.jeo.D.* ]] && category="sparkExecutorD"
      [[ $k =~ executor.jeo.XX.* ]] && category="sparkExecutorXX"
      [[ $k =~ job.* ]] && category="job"

      log_message INFO "spark_common_setup:  $k -> category = $category"

      case $category in
          sparkConf)
               log_message DEBUG "spark_common_setup: $k is matching spark."
               sparkConfMap[$k]="${configurationMap[$k]}"
          ;;
          sparkDriverD)
               log_message DEBUG "spark_common_setup: $k is matching  driver.jeo.D"
               sparkDriverDExtraMap[${k##driver.jeo.D.}]="${configurationMap[$k]}"
          ;;
          sparkDriverXX)
               log_message DEBUG "spark_common_setup: $k is matching  driver.jeo.XX"
               sparkDriverXXExtraMap[${k##driver.jeo.XX.}]="${configurationMap[$k]}"
          ;;
          sparkExecutorD)
               log_message DEBUG "spark_common_setup: $k is matching  executor.jeo.D"
               sparkExecutorDExtraMap[${k##executor.jeo.D.}]="${configurationMap[$k]}"
          ;;
          sparkExecutorXX)
               log_message DEBUG "spark_common_setup: $k is matching  executor.jeo.XX"
               sparkExecutorXXExtraMap[${k##executor.jeo.XX.}]="${configurationMap[$k]}"
          ;;
          job)
               log_message DEBUG "spark_common_setup: $k is matching  job."
               # ignore job. options for spark command line
          ;;
          *)
               log_message DEBUG "spark_common_setup: $k could be another spark option"
               [[ -z ${sparkLeadingArgsMap+set} ]] && sparkLeadingArgsMap[${k}]="${configurationMap[$k]:-}"
          ;;
      esac

  done

  log_message DEBUG "spark_common_setup: $( declare -p sparkLeadingArgsMap)"
  log_message DEBUG "spark_common_setup: $( declare -p sparkConfMap)"
  log_message DEBUG "spark_common_setup: $( declare -p sparkDriverDExtraMap)"
  log_message DEBUG "spark_common_setup: $( declare -p sparkDriverXXExtraMap)"
  log_message DEBUG "spark_common_setup: $( declare -p sparkExecutorDExtraMap)"
  log_message DEBUG "spark_common_setup: $( declare -p sparkExecutorXXExtraMap)"
  log_message DEBUG "spark_common_setup: $( declare -p  sparkTrailingArgsMap)"
}

#
### TODO select log4 file depending on log level
#

function  spark_common_print_options {
  # -- print content of tables sparkArgsMap, sparkConfMap, sparkDriverExtraMap, sparkExecutorExtraMap
  # -- requires :  verbosityLevel,  sparkArgsMap, sparkConfMap, sparkDriverExtraMap, sparkExecutorExtraMap
  log_message INFO "Elements of the spark-submit command line:"

  # -- leading args
  log_message INFO "From sparkLeadingArgsMap"
  for  k in  "${!sparkLeadingArgsMap[@]}"
  do
      log_message DEBUG "spark_common_print_options: found key $k"
      log_message INFO "  --$k  ${sparkLeadingArgsMap[$k]:-}"
  done

  # -- --conf spark*
  log_message INFO "From sparkConfMap"
  for  k in  "${!sparkConfMap[@]}"
  do
      log_message DEBUG "spark_common_print_options: found key $k"
      log_message INFO "  --conf $k=${sparkConfMap[$k]:-}"
  done

  # -- --conf spark.driver.extraJavaOptions
  log_message INFO "--conf spark.driver.extraJavaOptions="
  log_message INFO "From sparkDriverDExtraMap"
  for  k in  "${!sparkDriverDExtraMap[@]}"
  do
      log_message DEBUG "spark_common_print_options: found key $k"
      log_message INFO "  -D$k=${sparkDriverDExtraMap[$k]:-}"
  done
  log_message INFO "From sparkDriverXXExtraMap"
  for  k in  "${!sparkDriverXXExtraMap[@]}"
  do
      log_message DEBUG "spark_common_print_options: found key $k"
      log_message INFO "  -XX:+$k"
  done

  # -- --conf spark.executor.extraJavaOptions
  log_message INFO "--conf spark.executor.extraJavaOptions="
  log_message INFO "From sparkExecutorDExtraMap"
  for  k in  "${!sparkExecutorDExtraMap[@]}"
  do
      log_message DEBUG "spark_common_print_options: found key $k"
      log_message INFO "  -D$k=${sparkExecutorDExtraMap[$k]:-}"
  done
  log_message INFO "From sparkExecutorXXExtraMap"
  for  k in  "${!sparkExecutorXXExtraMap[@]}"
  do
      log_message DEBUG "spark_common_print_options: found key $k"
      log_message INFO "  -XX:+$k"
  done

  # -- trailing args
  log_message INFO "From sparkTrailingArgsMap"
  for  k in  "${!sparkTrailingArgsMap[@]}"
  do
      log_message DEBUG "spark_common_print_options: found key $k"
      log_message INFO "  --$k  ${sparkTrailingArgsMap[$k]:-}"
  done

  log_message INFO "${configurationMap['job.package']}"
  log_message INFO "End of Elements of the spark-submit command line:"

}


function  spark_common_submit {
  # -- buid and run the spark-submit command
  # -- args : args to spark app
  # -- requires :  verbosityLevel,  configurationMap, sparkArgsMap, sparkConfMap, sparkDriverExtraMap, sparkExecutorExtraMap

  # -- leading args
  local  leadingArgsString=" "
  for  k in  "${!sparkLeadingArgsMap[@]}"
  do
      log_message DEBUG "spark_common_submit: found key $k"
      leadingArgsString+=" --$k  ${sparkLeadingArgsMap[$k]:-}"
  done
  log_message DEBUG "spark_common_submit: leadingArgsString -> $leadingArgsString"

  # -- --conf spark*
  local  confString=" "
  for  k in  "${!sparkConfMap[@]}"
  do
      log_message DEBUG "spark_common_submit: found key $k"
      confString+=" --conf $k=${sparkConfMap[$k]:-}"
  done
  log_message DEBUG "spark_common_submit: confString -> $confString"

  # -- --conf spark.driver.extraJavaOptions
  local  driverJEOString=" "
  for  k in  "${!sparkDriverDExtraMap[@]}"
  do
      log_message DEBUG "spark_common_submit: found key $k"
      driverJEOString+="  -D$k=${sparkDriverDExtraMap[$k]:-}"
  done
  for  k in  "${!sparkDriverXXExtraMap[@]}"
  do
      log_message DEBUG "spark_common_submit: found key $k"
      driverJEOString+="  -XX:+$k"
  done
  log_message DEBUG "spark_common_submit: driverJEOString -> $driverJEOString"

  # -- --conf spark.executor.extraJavaOptions
  local  executorJEOString=" "
  for  k in  "${!sparkExecutorDExtraMap[@]}"
  do
      log_message DEBUG "spark_common_submit: found key $k"
      executorJEOString+="  -D$k=${sparkExecutorDExtraMap[$k]:-}"
  done
  for  k in  "${!sparkExecutorXXExtraMap[@]}"
  do
      log_message DEBUG "spark_common_submit: found key $k"
      executorJEOString+="  -XX:+$k"
  done
  log_message DEBUG "spark_common_submit: driverJEOString -> $executorJEOString"

  # -- trailing args
  local  trailingArgsString=" "
  for  k in  "${!sparkTrailingArgsMap[@]}"
  do
      log_message DEBUG "spark_common_submit: found key $k"
      trailingArgsString+=" --$k  ${sparkTrailingArgsMap[$k]:-}"
  done
  log_message DEBUG "spark_common_submit: trailingArgsString -> $trailingArgsString"

  local package="${configurationMap['job.package']}"
  log_message DEBUG "spark_common_submit: package -> $package"

  # -- run spark-submit
  local dryRun="${configurationMap['job.dry-run']+dry}"
  [[ ${dryRun:-} == "dry" ]]  &&  log_message INFO "dry-run" || {
    set -x
    spark-submit $leadingArgsString $confString --conf spark.driver.extraJavaOptions="$driverJEOString" --conf spark.executor.extraJavaOptions="$executorJEOString"   $trailingArgsString $package $@
    jobStatus=$?
    [[ $verbosityLevel -ge 5 ]] && set -xv || set +x
  }
  return 0
}


###
### end of functions' definition
###

# -- Do not remove
log_message INFO "sourcing function-spark-common Done"
function_spark_common_source_loaded=true
