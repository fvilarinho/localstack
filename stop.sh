#!/usr/bin/env bash

# Checks the dependencies of this script.
function checkDependencies() {
  if [ -z "$DOCKER_CMD" ]; then
    echo -e "${ANSI_RED}docker not detected! Please check your environment or install it first!${ANSI_RESET}"
    echo

    exit 1
  fi
}

# Prepares the environment to execute this script.
function prepareToExecute() {
  source functions.sh || exit 1

  showBanner
}

# Clean-up the generated/temporary files.
function cleanUp() {
	rm -rf temp
	rm -f iac/.terraform.lock*
	rm -f iac/*.*state*
	rm -f output.log
}

# Stops localstack.
function stop() {
  $DOCKER_CMD compose down
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies
  stop
  cleanUp
}

main
