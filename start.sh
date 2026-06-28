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

# Starts localstack.
function start() {
  $DOCKER_CMD compose up -d
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies
  start
}

main
