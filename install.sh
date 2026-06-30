#!/usr/bin/env bash

# Prepares the environment to execute this script.
function prepareToExecute() {
  source functions.sh

  showBanner
}

# Checks the dependencies of this script.
function checkDependencies() {
  if [ -z "$PYTHON_CMD" ]; then
    echo -e "${ANSI_RED}python3 not detected! Please check your environment or install it first!${ANSI_RESET} "
    echo

    exit 1
  fi
}

# Checks/Installs the required software.
function install() {
  OK=1

  echo -n -e "Checking ${ANSI_BOLD}python3${ANSI_RESET} virtual environment: "

  if [ ! -d .venv ]; then
    echo -e "${ANSI_YELLOW}not detected, installing...${ANSI_RESET}"

    $PYTHON_CMD -m venv .venv || exit 1

    source .venv/bin/activate

    PIP_CMD=$(which pip)

    $PIP_CMD install -r requirements.txt || exit 1
    $PIP_CMD install --upgrade pip || exit 1
  else
    echo -e "${ANSI_GREEN}OK${ANSI_RESET}"

    source .venv/bin/activate || exit 1
  fi

  echo
  echo -n -e "Checking ${ANSI_BOLD}awslocal cli${ANSI_RESET} installation: "

  AWSLOCAL_CLI_CMD=$(which awslocal)

  if [ -z "$AWSLOCAL_CLI_CMD" ]; then
    OK=0

    echo -e "${ANSI_RED}not detected! Please check your environment or install it first!${ANSI_RESET} "
  else
    echo -e "${ANSI_GREEN}OK${ANSI_RESET}"
  fi

  echo
  echo -n -e "Checking ${ANSI_BOLD}localstack cli${ANSI_RESET} installation: "

  LOCALSTACK_CLI_CMD=$(which localstack)

  if [ -z "$LOCALSTACK_CLI_CMD" ]; then
    OK=0

    echo -e "${ANSI_RED}not detected! Please check your environment or install it first!${ANSI_RESET} "
  else
    echo -e "${ANSI_GREEN}OK${ANSI_RESET}"
    echo

    if [ -z $LOCALSTACK_AUTH_TOKEN ]; then
      echo -n -e "Checking ${ANSI_BOLD}.env${ANSI_RESET} file: "

      if [ ! -f .env ]; then
        OK=0

        echo -e "${ANSI_RED}not detected, please create it first! Don't forget to create your account in LocalStack and update your token in the file!${ANSI_RESET}"
      else
        source .env

        if [ -z $LOCALSTACK_AUTH_TOKEN ]; then
          OK=0

          echo -e "${ANSI_RED}invalid, please review it first! Don't forget to create your account in LocalStack and update your token in the file!${ANSI_RESET}"
        else
          $LOCALSTACK_CLI_CMD auth set-token "$LOCALSTACK_AUTH_TOKEN" > /dev/null

          echo -e "${ANSI_GREEN}OK${ANSI_RESET}"
        fi
      fi
    fi
  fi

  echo
  echo -n -e "Checking ${ANSI_BOLD}terraform${ANSI_RESET} installation: "

  if [ -z "$TERRAFORM_CMD" ]; then
    OK=0

    echo -e "${ANSI_RED}not detected! Please check your environment or install it first!${ANSI_RESET} "
  else
    echo -e "${ANSI_GREEN}OK${ANSI_RESET}"
  fi

  echo
  echo -n -e "Checking ${ANSI_BOLD}docker${ANSI_RESET} installation: "

  if [ -z "$DOCKER_CMD" ]; then
    OK=0

    echo -e "${ANSI_RED}not detected! Please check your environment or install it first!${ANSI_RESET} "
  else
    echo -e "${ANSI_GREEN}OK${ANSI_RESET}"
  fi

  echo
  echo -n -e "Checking ${ANSI_BOLD}jq${ANSI_RESET} installation: "

  if [ -z "$JQ_CMD" ]; then
    OK=0

    echo -e "${ANSI_RED}not detected! Please check your environment or install it first!${ANSI_RESET} "
  else
    echo -e "${ANSI_GREEN}OK${ANSI_RESET}"
  fi

  echo

  if [ $OK == 0 ]; then
    echo -e "${ANSI_YELLOW}Please check the missing requirements before start localstack!${ANSI_RESET}"
    echo
    exit 1
  else
    echo -e "${ANSI_CYAN}Everything looks good! Now you can start localstack!${ANSI_RESET}"
    echo
  fi
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies
  install
}

main
q