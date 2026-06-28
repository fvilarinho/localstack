#!/usr/bin/env bash

# Checks the dependencies of this script.
function checkDependencies() {
  if [ -z "$TERRAFORM_CMD" ]; then
    echo -e "${ANSI_BOLD}terraform${ANSI_WHITE} not detected! Please check your environment or install it first!"

    exit 1
  fi

  if [ -z "$LOCALSTACK_CLI_CMD" ]; then
    echo -e "${ANSI_BOLD}localstack cli${ANSI_WHITE} not detected! Please check your environment or install it first!"

    exit 1
  fi
}

# Prepares the environment to execute this script.
function prepareToExecute() {
  source functions.sh || exit 1

  showBanner

  cd iac || exit 1

  TMP_DIR=../temp
}

# Clean-up temporary files.
function cleanUp() {
  rm -rf $TMP_DIR
}

# Starts the deployment.
function deploy() {
  $TERRAFORM_CMD init -migrate-state -upgrade || exit 1

  echo

  $TERRAFORM_CMD plan -out=$TMP_DIR/plan || exit 1

  echo

  $TERRAFORM_CMD apply $TMP_DIR/plan || exit 1

  echo

  $LOCALSTACK_CLI_CMD state export resources.state || exit 1
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies
  deploy | tee ../output.log
  cleanUp
}

main
