#!/usr/bin/env bash

# Checks the dependencies of this script.
function checkDependencies() {
  if [ -z "$TERRAFORM_CMD" ]; then
    echo -e "${ANSI_RED}terraform not detected! Please check your environment or install it first!${ANSI_RESET}"
    echo

    exit 1
  fi

  if [ -z "$LOCALSTACK_CLI_CMD" ]; then
    echo -e "${ANSI_RED}localstack not detected! Please check your environment or install it first!${ANSI_RESET}"
    echo

    exit 1
  fi
}

# Prepares the environment to execute this script.
function prepareToExecute() {
  source functions.sh || exit 1

  showBanner

  cd iac || exit 1

  TEMP_DIR=../temp/iac

  mkdir -p $TEMP_DIR
}


# Starts the deployment.
function deploy() {
  PLAN_FILE="$TEMP_DIR/localstack.plan"

  $TERRAFORM_CMD init -migrate-state -upgrade || exit 1

  echo

  $TERRAFORM_CMD plan -out=$PLAN_FILE || exit 1

  echo

  $TERRAFORM_CMD apply $PLAN_FILE || exit 1

  echo

  $LOCALSTACK_CLI_CMD state export resources.state || exit 1
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies
  deploy
}

main | tee -a output.log
