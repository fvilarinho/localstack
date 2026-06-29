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

function validateIAM() {
  echo -n "- Validating IAM: "

  ROLE=$($JQ_CMD -r ".resources.iam.role" $TESTS_DIR/resources.json)
  EXISTS=$($AWSLOCAL_CLI_CMD iam list-roles | $JQ_CMD -r ".Roles[] | select(.RoleName == \"$ROLE\")")

  if [ -z "$EXISTS" ]; then
    echo -e "${ANSI_RED}'$ROLE' ROLE NOT FOUND${ANSI_WHITE}"

    exit 1
  fi

  POLICY=$($JQ_CMD -r ".resources.iam.policy.name" $TESTS_DIR/resources.json)
  ACTIONS=$($JQ_CMD -r ".resources.iam.policy.actions" $TESTS_DIR/resources.json | $JQ_CMD -r 'join(" ")')
  EXISTS=$($AWSLOCAL_CLI_CMD iam list-role-policies --role-name "$ROLE" | grep "$POLICY")

  if [ -n "EXISTS" ]; then
    POLICY_CONTENT=$($AWSLOCAL_CLI_CMD iam get-role-policy --role-name "$ROLE" --policy-name "$POLICY")

    for ACTION in $ACTIONS
    do
      EXISTS=$(echo "$POLICY_CONTENT" | grep $ACTION)

      if [ -z "$EXISTS" ]; then
        echo -e "${ANSI_RED}'$ACTION' ACTION NOT FOUND IN THE POLICY '$POLICY'${ANSI_WHITE}"

        exit 1
      fi
    done

    echo -e "${ANSI_GREEN}OK${ANSI_WHITE}"
  else
    echo -e "${ANSI_RED}'$POLICY' POLICY NOT FOUND${ANSI_WHITE}"

    exit 1
  fi
}

# Validates S3 (bucket creation and notification).
function validateS3() {
  echo -n "- Validating S3: "

  BUCKET=$($JQ_CMD -r ".resources.s3.bucket" $TESTS_DIR/resources.json)
  EXISTS=$($AWSLOCAL_CLI_CMD s3 ls | grep "$BUCKET")

  if [ -n "$EXISTS" ]; then
    FUNCTION=$($JQ_CMD -r ".resources.s3.notification.lambda.function" $TESTS_DIR/resources.json)
    EVENTS=$($JQ_CMD -r ".resources.s3.notification.events" $TESTS_DIR/resources.json | $JQ_CMD -r 'join(" ")')
    NOTIFICATION_CONTENT=$($AWSLOCAL_CLI_CMD s3api get-bucket-notification-configuration --bucket "$BUCKET")
    EXISTS=$(echo "$NOTIFICATION_CONTENT" | grep "$FUNCTION")

    if [ -n "$EXISTS" ]; then
      for EVENT in $EVENTS
      do
        EXISTS=$(echo "$NOTIFICATION_CONTENT" | grep "$EVENT")

        if [ -z "$EXISTS" ]; then
          echo -e "${ANSI_RED}'$EVENT' EVENT NOT FOUND IN THE NOTIFICATION OF '$BUCKET' BUCKET${ANSI_WHITE}"

          exit 1
        fi
      done

      echo -e "${ANSI_GREEN}OK${ANSI_WHITE}"
    else
      echo -e "${ANSI_RED}NOTIFICATION NOT FOUND IN '$BUCKET' BUCKET${ANSI_WHITE}"
    fi
  else
    echo -e "${ANSI_RED}'$BUCKET' BUCKET NOT FOUND${ANSI_WHITE}"

    exit 1
  fi
}

# Validates Lambda (function creation, IAM roles, policies and permissions).
function validateLambda() {
  echo -n "- Validating Lambda: "

  FUNCTIONS=$($JQ_CMD -r ".resources.lambda[] | .function" $TESTS_DIR/resources.json)

  for FUNCTION in $FUNCTIONS
  do
    CONTENT=$($AWSLOCAL_CLI_CMD lambda list-functions | $JQ_CMD -r ".Functions[] | select(.FunctionName == \"$FUNCTION\")")
    EXISTS=$(echo $CONTENT | grep "$FUNCTION")

    if [ -z "$EXISTS" ]; then
      echo -e "${ANSI_RED}'$FUNCTION' FUNCTION NOT FOUND${ANSI_WHITE}"

      exit 1
    fi

    EXISTS=$($AWSLOCAL_CLI_CMD lambda get-policy --function-name "$FUNCTION" | grep "InvokeFunction")

    if [ -z "$EXISTS" ]; then
      echo -e "${ANSI_RED}'$FUNCTION' FUNCTION DOES NOT HAVE INVOKE PERMISSION${ANSI_WHITE}"

      exit 1
    fi

    ROLE=$($JQ_CMD -r ".resources.lambda[] | select(.function == \"$FUNCTION\") | .role" $TESTS_DIR/resources.json)
    EXISTS=$(echo $CONTENT | grep "$ROLE" )

    if [ -z "$EXISTS" ]; then
      echo -e "${ANSI_RED}'$ROLE' ROLE NOT FOUND IN FUNCTION '$FUNCTION'${ANSI_WHITE}"

      exit 1
    fi
  done

  echo -e "${ANSI_GREEN}OK${ANSI_WHITE}"
}

# Validates DynamoDB (table creation).
function validateDynamoDB() {
  echo -n "- Validating DynamoDB: "
#
  TABLE=$($JQ_CMD -r ".resources.dynamodb.table" $TESTS_DIR/resources.json)
  EXISTS=$($AWSLOCAL_CLI_CMD dynamodb list-tables | grep "$TABLE")

  if [ -n "$EXISTS" ]; then
    echo -e "${ANSI_GREEN}OK${ANSI_WHITE}"
  else
    echo -e "${ANSI_RED}'$TABLE' TABLE NOT FOUND${ANSI_WHITE}"

    exit 1
  fi
}

function validateAPIGateway() {
  echo -n "- Validating API Gateway: "

  APIGATEWAY=$($JQ_CMD -r ".resources.apigateway.name" $TESTS_DIR/resources.json)
  EXISTS=$($AWSLOCAL_CLI_CMD apigateway get-rest-apis | $JQ_CMD -r ".items[] | select(.name == \"$APIGATEWAY\")")

  if [ -z "$EXISTS" ]; then
    echo -e "${ANSI_RED}'$APIGATEWAY' API GATEWAY NOT FOUND${ANSI_WHITE}"

    exit 1
  fi

  APIGATEWAY_ID=$(echo "$EXISTS" | $JQ_CMD -r .id)
  APIGATEWAY_PATH=$($JQ_CMD -r ".resources.apigateway.path" $TESTS_DIR/resources.json)
  APIGATEWAY_METHOD=$($JQ_CMD -r ".resources.apigateway.method" $TESTS_DIR/resources.json)
  APIGATEWAY_LAMBDA_FUNCTION=$($JQ_CMD -r ".resources.apigateway.lambda.function" $TESTS_DIR/resources.json)
  EXISTS=$($AWSLOCAL_CLI_CMD apigateway get-resources --rest-api-id "$APIGATEWAY_ID" | $JQ_CMD -r ".items[] | select(.path == \"$APIGATEWAY_PATH\")")

  if [ -z "$EXISTS" ]; then
    echo -e "${ANSI_RED}'$APIGATEWAY_PATH' PATH NOT FOUND IN '$APIGATEWAY' API GATEWAY${ANSI_WHITE}"

    exit 1
  fi

  EXISTS=$(echo $EXISTS | $JQ_CMD -r ".resourceMethods.$APIGATEWAY_METHOD")

  if [ -z "$EXISTS" ]; then
    echo -e "${ANSI_RED}'$APIGATEWAY_METHOD' METHOD NOT FOUND IN '$APIGATEWAY' API GATEWAY${ANSI_WHITE}"

    exit 1
  fi

  EXISTS=$(echo $EXISTS | $JQ_CMD -r ".methodIntegration.uri" | grep "$APIGATEWAY_LAMBDA_FUNCTION")

  if [ -z "$EXISTS" ]; then
    echo -e "${ANSI_RED}'$APIGATEWAY_LAMBDA_FUNCTION' FUNCTION NOT FOUND IN '$APIGATEWAY' API GATEWAY${ANSI_WHITE}"

    exit 1
  fi

  echo -e "${ANSI_GREEN}OK${ANSI_WHITE}"
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies
  validateIAM
  validateS3
  validateLambda
  validateDynamoDB
  validateAPIGateway
}

main
