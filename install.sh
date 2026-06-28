#!/usr/bin/env bash

# Prepares the environment to execute this script.
function prepareToExecute() {
  source functions.sh

  showBanner
}

# Checks the dependencies of this script.
function checkDependencies() {
  if [ -z "$PYTHON_CMD" ]; then
    echo -e "${ANSI_BOLD}python3${ANSI_WHITE} not detected! Please check your environment or install it first!"

    exit 1
  fi
}

# Checks/Installs the required software.
function install() {
  OK=1

  echo -n -e "Checking ${ANSI_BOLD}python3${ANSI_WHITE} virtual environment: "

  if [ ! -d .venv ]; then
    echo

    $PYTHON_CMD -m venv .venv || exit 1
  else
    echo -e "${ANSI_GREEN}OK${ANSI_WHITE}"
  fi

  source .venv/bin/activate || exit 1

  echo
  echo -e "Checking ${ANSI_BOLD}python3${ANSI_WHITE} requirements: "

  PIP_CMD=$(which pip)

  $PIP_CMD install -r requirements.txt || exit 1
  $PIP_CMD install --upgrade pip || exit 1

  echo
  echo -n -e "Checking ${ANSI_BOLD}awslocal cli${ANSI_WHITE} installation: "

  AWSLOCAL_CLI_CMD=$(which awslocal)

  if [ -z "$AWSLOCAL_CLI_CMD" ]; then
    echo

    $PIP_CMD install awscli-local || exit 1

    source .venv/bin/activate || exit 1
  else
    echo -e "${ANSI_GREEN}OK${ANSI_WHITE}"
  fi

  echo
  echo -n -e "Checking ${ANSI_BOLD}localstack cli${ANSI_WHITE} installation: "

  LOCALSTACK_CLI_CMD=$(which localstack)

  if [ -z "$LOCALSTACK_CLI_CMD" ]; then
    echo

    $PIP_CMD install localstack || exit 1

    source .venv/bin/activate || exit 1
  else
    echo -e "${ANSI_GREEN}OK${ANSI_WHITE}"
  fi

  echo
  echo -n -e "Checking ${ANSI_BOLD}terraform${ANSI_WHITE} installation: "

  if [ -n "$TERRAFORM_CMD" ]; then
    echo -e "${ANSI_GREEN}OK${ANSI_WHITE}"
  else
    OK=0

    echo -e "${ANSI_RED}NOT FOUND${ANSI_WHITE}"
  fi

  echo
  echo -n -e "Checking ${ANSI_BOLD}docker${ANSI_WHITE} installation: "

  if [ -n "$DOCKER_CMD" ]; then
    echo -e "${ANSI_GREEN}OK${ANSI_WHITE}"
  else
    OK=0

    echo -e "${ANSI_RED}NOT FOUND${ANSI_WHITE}"
  fi

  echo
  echo -n -e "Checking ${ANSI_BOLD}jq${ANSI_WHITE} installation: "

  if [ -n "$JQ_CMD" ]; then
    echo -e "${ANSI_GREEN}OK${ANSI_WHITE}"
  else
    OK=0

    echo -e "${ANSI_RED}NOT FOUND${ANSI_WHITE}"
  fi

  echo

  if [ $OK == 1 ]; then
    echo -e "${ANSI_CYAN}Everything looks good! Now you can start localstack!${ANSI_WHITE}"
  else
    echo -e "${ANSI_YELLOW}Please check the missing requirements before start localstack!${ANSI_WHITE}"

    exit 1
  fi
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies
  install
}

main
