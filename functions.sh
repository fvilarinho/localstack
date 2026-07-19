#!/usr/bin/env bash

# Prepares the environment to execute this script.
function prepareToExecute() {
  # Loads python3 virtual environment.
  if [ -d .venv ]; then
    source .venv/bin/activate
  fi

  if [ -f .env ]; then
    source .env
  fi

  # Defines environment variables.
  export TERRAFORM_CMD="$(which terraform)"
  export DOCKER_CMD="$(which docker)"
  export PYTHON_CMD="$(which python3)"
  export JQ_CMD="$(which jq)"
  export AWSLOCAL_CLI_CMD="$(which awslocal)"
  export LOCALSTACK_CLI_CMD=$(which localstack)

  export ANSI_GREEN="\033[1;32m"
  export ANSI_RED="\033[1;31m"
  export ANSI_YELLOW="\033[93m"
  export ANSI_CYAN="\033[1;36m"
  export ANSI_RESET="\033[0m"
  export ANSI_BOLD="\033[1m"
}

# Shows the banner logo/labels.
function showBanner() {
  # Check if the banner file exists.
  if [ -f banner.txt ]; then
    echo -e "$(cat banner.txt)"
    echo
  fi

  # Shows labels.
  if [[ "$0" == *"validate"* ]]; then
    echo "Validating the provisioned resources..."
    echo
  elif [[ "$0" == *"deploy"* ]]; then
    echo "Provisioning the resources..."
    echo
  elif [[ "$0" == *"start"* ]]; then
    echo "Starting..."
    echo
  elif [[ "$0" == *"stop"* ]]; then
    echo "Stopping..."
    echo
  elif [[ "$0" == *"install"* ]]; then
    echo "Setting up..."
    echo
  fi
}

prepareToExecute