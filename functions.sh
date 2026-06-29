#!/usr/bin/env bash

# Prepares the environment to execute this script.
function prepareToExecute() {
  # Loads python3 virtual environment.
  if [ -d .venv ]; then
    source .venv/bin/activate
  fi

  # Defines environment variables.
  TERRAFORM_CMD="$(which terraform)"
  DOCKER_CMD="$(which docker)"
  PYTHON_CMD="$(which python3)"
  JQ_CMD="$(which jq)"
  AWSLOCAL_CLI_CMD="$(which awslocal)"
  LOCALSTACK_CLI_CMD=$(which localstack)

  ANSI_GREEN="\033[1;32m"
  ANSI_RED="\033[1;31m"
  ANSI_YELLOW="\033[93m"
  ANSI_CYAN="\x1b[1;36m"
  ANSI_WHITE="\033[0m"
  ANSI_BOLD="\033[97m"
}

# Shows the banner logo/labels.
function showBanner() {
  # Check if the banner file exists.
  if [ -n banner.txt ]; then
    echo -e "$(cat banner.txt)"
    echo
  fi

  # Shows labels.
  if [[ "$0" == *"validate"* ]]; then
    echo "Checking the provisioned resources..."
    echo
  elif [[ "$0" == *"deploy"* ]]; then
    echo "Provisioning the resources..."
    echo
  elif [[ "$0" == *"start"* ]]; then
    echo "Starting localstack..."
    echo
  elif [[ "$0" == *"stop"* ]]; then
    echo "Stopping localstack..."
    echo
  elif [[ "$0" == *"install"* ]]; then
    echo "Setting up localstack..."
    echo
  fi
}

prepareToExecute