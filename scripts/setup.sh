#!/bin/bash

# shellcheck disable=SC1091

################# standard init #################

export SLEEP_SECONDS=8

check_shell(){
  [ -n "$BASH_VERSION" ] && return
  echo -e "${ORANGE}WARNING: These scripts are ONLY tested in a bash shell${NC}"
  sleep "${SLEEP_SECONDS:-8}"
}

check_git_root(){
  if [ -d .git ] && [ -d scripts ]; then
    GIT_ROOT=$(pwd)
    export GIT_ROOT
    echo "GIT_ROOT:   ${GIT_ROOT}"
  else
    echo "Please run this script from the root of the git repo"
    exit 1
  fi
}

get_script_path(){
  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  echo "SCRIPT_DIR: ${SCRIPT_DIR}"
}

check_shell
check_git_root
get_script_path

# shellcheck source=/dev/null
. "${SCRIPT_DIR}/functions.sh"

validate_cli(){
  echo ""
  echo "Validating command requirements..."
  bin_check oc
  bin_check jq
  echo ""
}

help(){
  loginfo "Whisper workshop facilitator setup (Web Terminal, banner, project)"
  loginfo "Usage: $(basename "$0") -s <step-number>"
  loginfo "Options:"
  loginfo " -h, --help   usage"
  loginfo " -s, --step   step number (required)"
  loginfo "        0       - Web Terminal operator, console banner, tooling template"
  loginfo "        1       - Data Science project whisper-workshop"
  return 0
}

while getopts ":h:s:" flag; do
  case $flag in
    h) help ;;
    s) s=$OPTARG ;;
    \?) echo "Invalid option: -$OPTARG" >&1; exit 1 ;;
  esac
done

step_0(){
  logbanner "Install Web Terminal and workshop tooling"

  retry oc apply -f "${GIT_ROOT}"/configs/00/web-terminal-subscription.yaml

  INSTALL_PLAN=""
  while [ -z "$INSTALL_PLAN" ]; do
    INSTALL_PLAN=$(oc get installplan -n openshift-operators -o json 2>/dev/null | jq -r '.items[] | select(.spec.clusterServiceVersionNames[]? | contains("web-terminal")) | .metadata.name' | head -1)
    [ -z "$INSTALL_PLAN" ] && sleep 5
  done
  log "$INSTALL_PLAN"

  retry oc patch installplan "$INSTALL_PLAN" \
    --namespace openshift-operators \
    --type merge \
    --patch '{"spec":{"approved":true}}'

  retry oc apply -f "${GIT_ROOT}"/configs/00/banner.yaml
  retry oc apply -f "${GIT_ROOT}"/configs/00/web-terminal-tooling.yaml

  validate_cli || echo "!!!NOTICE: you are missing cli tools needed!!!"
}

step_1(){
  logbanner "Prepare whisper-workshop project"

  retry oc apply -f "${GIT_ROOT}/configs/samples/project/namespace.yaml"

  loginfo "Project whisper-workshop is ready (OpenShift AI dashboard label set)."
  loginfo "Participants deploy Whisper into this project in Topics 4–6."
}

setup(){
  if [ -z "$s" ]; then
      logerror "Step number is required"
      help
      exit 1
  fi

  case "$s" in
    0)
      loginfo "Running step 0"
      step_0
      ;;
    1)
      loginfo "Running step 1"
      step_1
      ;;
    *)
      logerror "Unknown step: $s"
      help
      exit 1
      ;;
  esac
}

is_sourced || setup
