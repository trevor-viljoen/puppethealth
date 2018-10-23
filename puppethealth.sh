#!/bin/bash
#==============================================================================
#                   Copyright (c) 2018 zer0labs.net
#                         All rights reserved.
#==============================================================================
#
#  Name:        puppethealth.sh
#  Type:        shell script
#  Authors:     Trevor Viljoen <trevor.viljoen@gmail.com>
#
#  Purpose:     To check the status of the puppet agent, discovering stale
#               lock files and process ids.
#
#==============================================================================
PATH=$PATH:/opt/puppetlabs/puppet/bin

current_time=$(date +'%s')
statedir=$(puppet config print statedir)
last_run="$(cat ${statedir}/last_run_summary.yaml | grep last_run | cut -d: -f2 | tr -d ' ')"
last_run_date="$(date -d @${last_run})"
run_differential=$((${current_time} - ${last_run}))
hours=2
threshold=$((${hours} * 60 * 60)) #threshold in seconds

logit() {
    logger -t $(basename $0) -i -p $1 $2
}

# if puppet has not run in the alloted time
if [[ "${run_differential}" -ge "${threshold}" ]]
then
  if [ -f ${statedir}/agent_catalog_run.lock ]; then
    pid="$(cat ${statedir}/agent_catalog_run.lock)"
    ptime="$(ps -p ${pid} -o etime= | tr -d ' ')"
    message="[WARN] Puppet process has been running for ${ptime}. Killing pid: ${pid}."
    logit "auth.warn" "${message}"
    kill -9 $pid
  else
    if [ $(ps -ef | grep puppet | grep onetime) ]; then
      message="[ERROR] Possible hung puppet agent requires further investigation. Puppet last checked in: ${last_run_date}."
      logit "auth.err" "${message}"
    else
      message="[ERROR] Missing lock file requires further investigation. Puppet last checked in: ${last_run_date}."
      logit "auth.err" "${message}"
    fi
  fi
else
  message="[INFO] Puppet ran ${run_differential} seconds ago, at ${last_run_date}."
  logit "auth.info" "${message}"
fi
