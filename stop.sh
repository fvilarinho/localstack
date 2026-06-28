#!/usr/bin/env bash

# Checks the dependencies of this script.
function checkDependencies() {
  if [ -z "$DOCKER_CMD" ]; then
    echo -e "${ANSI_BOLD}docker${ANSI_WHITE} not detected! Please check your environment or install it first!"

    exit 1
  fi
}

# Prepares the environment to execute this script.
function prepareToExecute() {
  source functions.sh || exit 1

  showBanner
}

# Stops localstack,
function stop() {
  $DOCKER_CMD compose down
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies
  stop
}

main
