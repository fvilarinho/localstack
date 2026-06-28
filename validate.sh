#!/usr/bin/env bash

# Prepares the environment to execute this script.
function prepareToExecute() {
  source functions.sh || exit 1

  showBanner

  TESTS_DIR=src/tests
}

# Checks the dependencies of this script.
function checkDependencies() {
  if [ -z "$JQ_CMD" ]; then
    echo -e "${ANSI_BOLD}jq${ANSI_WHITE} not detected! Please check your environment or install it first!"

    exit 1
  fi

  if [ -z "$AWSLOCAL_CLI_CMD" ]; then
    echo -e "${ANSI_BOLD}awslocal cli${ANSI_WHITE} not detected! Please check your environment or install it first!"

    exit 1
  fi
}

# Validates S3 (bucket creation and notification).
function validateS3() {
  echo -n "- Validating S3 bucket: "

  BUCKET=$($JQ_CMD -r ".resources.s3.bucket" $TESTS_DIR/resources.json)
  EXISTS=$($AWSLOCAL_CLI_CMD s3 ls | grep "$BUCKET")

  if [ -n "$EXISTS" ]; then
    NOTIFICATION=$($JQ_CMD -r ".resources.s3.notification" $TESTS_DIR/resources.json)
    EXISTS=$($AWSLOCAL_CLI_CMD s3api get-bucket-notification-configuration --bucket "$BUCKET" | grep "$NOTIFICATION")

    if [ -n "$EXISTS" ]; then
      echo -e "${ANSI_GREEN}OK${ANSI_WHITE}"
    else
      echo -e "${ANSI_RED}NOTIFICATION NOT FOUND${ANSI_WHITE}"

      exit 1
    fi
  else
    echo -e "${ANSI_RED}NOT FOUND${ANSI_WHITE}"

    exit 1
  fi
}

# Validates Lambda (function creation, IAM roles, policies and permissions).
function validateLambda() {
  echo -n "- Validating Lambda function: "

  FUNCTION=$($JQ_CMD -r ".resources.lambda.function" $TESTS_DIR/resources.json)
  EXISTS=$($AWSLOCAL_CLI_CMD lambda list-functions | grep "$FUNCTION")

  if [ -n "$EXISTS" ]; then
    ROLE=$($JQ_CMD -r ".resources.lambda.role" $TESTS_DIR/resources.json)
    EXISTS=$($AWSLOCAL_CLI_CMD iam list-roles | grep "$ROLE")

    if [ -n "$EXISTS" ]; then
      EXISTS=$($AWSLOCAL_CLI_CMD lambda get-policy --function-name $FUNCTION | grep "lambda:InvokeFunction")

      if [ -n "$EXISTS" ]; then
        EXISTS=$($AWSLOCAL_CLI_CMD iam list-attached-role-policies --role-name $ROLE | grep "AWSLambdaBasicExecutionRole")

        if [ -n "$EXISTS" ]; then
          POLICY=$($JQ_CMD -r ".resources.lambda.policy" $TESTS_DIR/resources.json)
          EXISTS=$($AWSLOCAL_CLI_CMD iam list-role-policies --role-name $ROLE | grep "$POLICY")

          if [ -n "$EXISTS" ]; then
            echo -e "${ANSI_GREEN}OK${ANSI_WHITE}"
          else
            echo -e "${ANSI_RED}POLICY NOT FOUND${ANSI_WHITE}"

            exit 1
          fi
        else
          echo -e "${ANSI_RED}INVOKE PERMISSION OT FOUND${ANSI_WHITE}"

          exit 1
        fi
      else
        echo -e "${ANSI_RED}INVOKE PERMISSION NOT FOUND${ANSI_WHITE}"

        exit 1
      fi
    else
      echo -e "${ANSI_RED}ROLE NOT FOUND${ANSI_WHITE}"

      exit 1
    fi
  else
    echo -e "${ANSI_RED}NOT FOUND${ANSI_WHITE}"

    exit 1
  fi
}

# Validates DynamoDB (table creation).
function validateDynamoDB() {
  echo -n "- Validating DynamoDB table: "

  TABLE=$($JQ_CMD -r ".resources.dynamodb.table" $TESTS_DIR//resources.json)
  EXISTS=$($AWSLOCAL_CLI_CMD dynamodb list-tables | grep "$TABLE")

  if [ -n "$EXISTS" ]; then
    echo -e "${ANSI_GREEN}OK${ANSI_WHITE}"
  else
    echo -e "${ANSI_RED}NOT FOUND${ANSI_WHITE}"

    exit 1
  fi
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies
  validateS3
  validateLambda
  validateDynamoDB
}

main
