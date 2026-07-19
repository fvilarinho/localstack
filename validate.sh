#!/usr/bin/env bash

# Prepares the environment to execute this script.
function prepareToExecute() {
  source functions.sh || exit 1

  showBanner

  TESTS_DIR="src/tests"
  RESOURCES_FILE="$TESTS_DIR/resources.json"
  UNITS_FILE="$TESTS_DIR/units.json"
}

# Checks the dependencies of this script.
function checkDependencies() {
  if [ -z "$JQ_CMD" ]; then
    echo -e "${ANSI_RED}jq not detected! Please check your environment or install it first!${ANSI_RESET}"
    echo

    exit 1
  fi

  if [ -z "$AWSLOCAL_CLI_CMD" ]; then
    echo -e "${ANSI_RED}awslocal not detected! Please check your environment or install it first!${ANSI_RESET}"
    echo

    exit 1
  fi
}

# Validates IAM resources.
function validateIAM() {
  echo -n "- Validating IAM: "

  ROLE=$($JQ_CMD -r ".resources.iam.role" "$RESOURCES_FILE")
  EXISTS=$($AWSLOCAL_CLI_CMD iam list-roles | $JQ_CMD -r ".Roles[] | select(.RoleName == \"$ROLE\")")

  if [ -z "$EXISTS" ]; then
    echo -e "${ANSI_RED}'$ROLE' role not found!${ANSI_RESET}"

    exit 1
  fi

  POLICY=$($JQ_CMD -r ".resources.iam.policy.name" "$RESOURCES_FILE")
  ACTIONS=$($JQ_CMD -r ".resources.iam.policy.actions" "$RESOURCES_FILE" | $JQ_CMD -r 'join(" ")')
  EXISTS=$($AWSLOCAL_CLI_CMD iam list-role-policies --role-name "$ROLE" | grep "$POLICY")

  if [ -n "$EXISTS" ]; then
    POLICY_CONTENT=$($AWSLOCAL_CLI_CMD iam get-role-policy --role-name "$ROLE" --policy-name "$POLICY")

    for ACTION in $ACTIONS
    do
      EXISTS=$(echo "$POLICY_CONTENT" | grep "$ACTION")

      if [ -z "$EXISTS" ]; then
        echo -e "${ANSI_RED}'$ACTION' action not found in '$POLICY' policy!${ANSI_RESET}"

        exit 1
      fi
    done

    echo -e "${ANSI_GREEN}OK${ANSI_RESET}"
  else
    echo -e "${ANSI_RED}'$POLICY' policy not found!${ANSI_RESET}"

    exit 1
  fi
}

# Validates S3 resources.
function validateS3() {
  echo -n "- Validating S3: "

  BUCKET=$($JQ_CMD -r ".resources.s3.bucket" "$RESOURCES_FILE")
  EXISTS=$($AWSLOCAL_CLI_CMD s3 ls | grep "$BUCKET")

  if [ -n "$EXISTS" ]; then
    FUNCTION=$($JQ_CMD -r ".resources.s3.notification.lambda.function" "$RESOURCES_FILE")
    EVENTS=$($JQ_CMD -r ".resources.s3.notification.events" "$RESOURCES_FILE" | $JQ_CMD -r 'join(" ")')
    NOTIFICATION_CONTENT=$($AWSLOCAL_CLI_CMD s3api get-bucket-notification-configuration --bucket "$BUCKET")
    EXISTS=$(echo "$NOTIFICATION_CONTENT" | grep "$FUNCTION")

    if [ -n "$EXISTS" ]; then
      for EVENT in $EVENTS
      do
        EXISTS=$(echo "$NOTIFICATION_CONTENT" | grep "$EVENT")

        if [ -z "$EXISTS" ]; then
          echo -e "${ANSI_RED}'$EVENT' event not found in '$BUCKET' bucket notification!${ANSI_RESET}"

          exit 1
        fi
      done

      echo -e "${ANSI_GREEN}OK${ANSI_RESET}"
    else
      echo -e "${ANSI_RED}notification not found in '$BUCKET' bucket!${ANSI_RESET}"

      exit 1
    fi
  else
    echo -e "${ANSI_RED}'$BUCKET' bucket not found!${ANSI_RESET}"

    exit 1
  fi
}

# Validates Lambda resources.
function validateLambda() {
  echo -n "- Validating Lambda: "

  FUNCTIONS=$($JQ_CMD -r ".resources.lambda[] | .function" "$RESOURCES_FILE")

  for FUNCTION in $FUNCTIONS
  do
    CONTENT=$($AWSLOCAL_CLI_CMD lambda list-functions | $JQ_CMD -r ".Functions[] | select(.FunctionName == \"$FUNCTION\")")
    EXISTS=$(echo "$CONTENT" | grep "$FUNCTION")

    if [ -z "$EXISTS" ]; then
      echo -e "${ANSI_RED}'$FUNCTION' function not found!${ANSI_RESET}"

      exit 1
    fi

    EXISTS=$($AWSLOCAL_CLI_CMD lambda get-policy --function-name "$FUNCTION" | grep "InvokeFunction")

    if [ -z "$EXISTS" ]; then
      echo -e "${ANSI_RED}'$FUNCTION' function does not have the invoke permission!${ANSI_RESET}"

      exit 1
    fi

    ROLE=$($JQ_CMD -r ".resources.lambda[] | select(.function == \"$FUNCTION\") | .role" "$RESOURCES_FILE")
    EXISTS=$(echo "$CONTENT" | grep "$ROLE" )

    if [ -z "$EXISTS" ]; then
      echo -e "${ANSI_RED}'$ROLE' role not attached in '$FUNCTION' function!${ANSI_RESET}"

      exit 1
    fi
  done

  echo -e "${ANSI_GREEN}OK${ANSI_RESET}"
}

# Validates DynamoDB resources.
function validateDynamoDB() {
  echo -n "- Validating DynamoDB: "

  TABLE=$($JQ_CMD -r ".resources.dynamodb.table" "$RESOURCES_FILE")
  EXISTS=$($AWSLOCAL_CLI_CMD dynamodb list-tables | grep "$TABLE")

  if [ -n "$EXISTS" ]; then
    echo -e "${ANSI_GREEN}OK${ANSI_RESET}"
  else
    echo -e "${ANSI_RED}'$TABLE' table not found!${ANSI_RESET}"

    exit 1
  fi
}

# Validates API Gateway resources.
function validateAPIGateway() {
  echo -n "- Validating API Gateway: "

  APIGATEWAY_NAME=$($JQ_CMD -r ".resources.apigateway.name" "$RESOURCES_FILE")
  EXISTS=$($AWSLOCAL_CLI_CMD apigateway get-rest-apis | $JQ_CMD -r ".items[] | select(.name == \"$APIGATEWAY_NAME\")")

  if [ -z "$EXISTS" ]; then
    echo -e "${ANSI_RED}'$APIGATEWAY_NAME' API Gateway not found!${ANSI_RESET}"

    exit 1
  fi

  APIGATEWAY_ID=$(echo "$EXISTS" | $JQ_CMD -r .id)
  APIGATEWAY_PATH=$($JQ_CMD -r ".resources.apigateway.path" "$RESOURCES_FILE")
  APIGATEWAY_METHOD=$($JQ_CMD -r ".resources.apigateway.method" "$RESOURCES_FILE")
  APIGATEWAY_LAMBDA_FUNCTION=$($JQ_CMD -r ".resources.apigateway.lambda.function" "$RESOURCES_FILE")
  EXISTS=$($AWSLOCAL_CLI_CMD apigateway get-resources --rest-api-id "$APIGATEWAY_ID" | $JQ_CMD -r ".items[] | select(.path == \"$APIGATEWAY_PATH\")")

  if [ -z "$EXISTS" ]; then
    echo -e "${ANSI_RED}'$APIGATEWAY_PATH' path not found IN '$APIGATEWAY_NAME' API Gateway!${ANSI_RESET}"

    exit 1
  fi

  EXISTS=$(echo "$EXISTS" | $JQ_CMD -r ".resourceMethods.$APIGATEWAY_METHOD")

  if [ -z "$EXISTS" ]; then
    echo -e "${ANSI_RED}'$APIGATEWAY_METHOD' method not found in '$APIGATEWAY_NAME' API Gateway!${ANSI_RESET}"

    exit 1
  fi

  EXISTS=$(echo "$EXISTS" | $JQ_CMD -r ".methodIntegration.uri" | grep "$APIGATEWAY_LAMBDA_FUNCTION")

  if [ -z "$EXISTS" ]; then
    echo -e "${ANSI_RED}'$APIGATEWAY_LAMBDA_FUNCTION' function not attached to '$APIGATEWAY_NAME' API Gateway!${ANSI_RESET}"

    exit 1
  fi

  echo -e "${ANSI_GREEN}OK${ANSI_RESET}"
}

# Validate integration test.
function validateIntegrationTests() {
  mkdir -p temp/tests

  echo -n "- Validating integration test: "

  APIGATEWAY_NAME=$($JQ_CMD -r ".resources.apigateway.name" "$RESOURCES_FILE")

  EXISTS=$($AWSLOCAL_CLI_CMD apigateway get-rest-apis | $JQ_CMD -r ".items[] | select(.name == \"$APIGATEWAY_NAME\")")

  if [ -n "$EXISTS" ]; then
    APIGATEWAY_ID=$(echo "$EXISTS" | $JQ_CMD -r .id)
    APIGATEWAY_PATH=$($JQ_CMD -r ".resources.apigateway.path" "$RESOURCES_FILE")
    EXISTS=$($AWSLOCAL_CLI_CMD apigateway get-resources --rest-api-id "$APIGATEWAY_ID" | $JQ_CMD -r ".items[] | select(.path == \"$APIGATEWAY_PATH\")")

    if [ -n "$EXISTS" ]; then
      BUCKET=$($JQ_CMD -r ".resources.s3.bucket" "$RESOURCES_FILE")

      if [ -n "$BUCKET" ]; then
        TEST_NAME="integrationTest.txt"
        TEST_FILE="temp/tests/$TEST_NAME"

        echo "This is a test" > "$TEST_FILE"

        $AWSLOCAL_CLI_CMD s3 cp "$TEST_FILE" "s3://$BUCKET" > /dev/null

        sleep 2

        APIGATEWAY_PATH_ID=$(echo "$EXISTS" | $JQ_CMD -r .id)
        RESPONSE=$($AWSLOCAL_CLI_CMD apigateway test-invoke-method --rest-api-id "$APIGATEWAY_ID" --resource-id "$APIGATEWAY_PATH_ID" --http-method GET)

        if [ -n "$RESPONSE" ]; then
          STATUS_CODE=$(echo "$RESPONSE" | $JQ_CMD -r ".status")

          if [ "$STATUS_CODE" == "200" ]; then
            EXISTS=$(echo "$RESPONSE" | $JQ_CMD -r ".body" | grep "$TEST_NAME")

            if [ -n "$EXISTS" ]; then
              $AWSLOCAL_CLI_CMD s3 rm "s3://$BUCKET/$TEST_NAME" > /dev/null

              echo -e "${ANSI_GREEN}OK${ANSI_RESET}"
            else
              echo -e "${ANSI_RED}'$TEST_NAME' not found in response of '$APIGATEWAY_NAME' API Gateway!${ANSI_RESET}"

              exit 1
            fi
          else
            echo -e "${ANSI_RED}expecting '200' status code but returned '$STATUS_CODE'!${ANSI_RESET}"

            exit 1
          fi
        else
          echo -e "${ANSI_RED}failed to invoke '$APIGATEWAY_NAME' API Gateway!${ANSI_RESET}"

          exit 1
        fi
      else
        echo -e "${ANSI_RED}'$BUCKET' bucket not found!${ANSI_RESET}"
      fi
    else
      echo -e "${ANSI_RED}'$APIGATEWAY_NAME' API Gateway not found!${ANSI_RESET}"
    fi
  else
    echo -e "${ANSI_RED}'$APIGATEWAY_NAME' API Gateway not found${ANSI_RESET}"
  fi
}

# Validate unit tests.
function validateUnitTests() {
  INVOKES=$($JQ_CMD -r ".tests.lambda[] | .invokeName" "$UNITS_FILE")

  mkdir -p temp/tests

  for INVOKE in $INVOKES
  do
    CONTENT=$($JQ_CMD -r ".tests.lambda[] | select(.invokeName == \"$INVOKE\")" "$UNITS_FILE")
    FUNCTION=$(echo "$CONTENT" | $JQ_CMD -r '.function')
    PAYLOAD=$(echo "$CONTENT" | $JQ_CMD -r '.payload')
    EXPECTED_STATUS_CODE=$(echo "$CONTENT" | $JQ_CMD -r '.expectedStatusCode')
    EXPECTED_BODY=$(echo "$CONTENT" | $JQ_CMD -r '.expectedBody')

    echo -n "- Validating unit test '$INVOKE' in '$FUNCTION' Lambda function: "

    TEST_FILE="temp/tests/$INVOKE.json"

    $AWSLOCAL_CLI_CMD lambda invoke \
                             --cli-binary-format raw-in-base64-out \
                             --function-name "$FUNCTION" \
                             --payload "$PAYLOAD" "$TEST_FILE" > /dev/null


    if [ ! -f "$TEST_FILE" ]; then
      echo -e "${ANSI_RED}failed to invoke '$INVOKE' unit test in '$FUNCTION' function!${ANSI_RESET}"

      exit 1
    fi

    RETURNED_STATUS_CODE=$(cat "$TEST_FILE" | $JQ_CMD -r ".statusCode")
    RETURNED_BODY=$(cat "$TEST_FILE" | $JQ_CMD -r ".body")

    if [ "$RETURNED_STATUS_CODE" -ne "$EXPECTED_STATUS_CODE" ]; then
      echo -e "${ANSI_RED}expecting '$EXPECTED_STATUS_CODE' status code but returned '$RETURNED_STATUS_CODE'!${ANSI_RESET}"

      exit 1
    fi

    if [ "$EXPECTED_BODY" != "null" ]; then
      if [ "$RETURNED_BODY" != "$EXPECTED_BODY" ]; then
        echo -e "${ANSI_RED}expecting '$EXPECTED_BODY' but returned '$RETURNED_BODY'!${ANSI_RESET}"

        exit 1
      fi
    fi

    echo -e "${ANSI_GREEN}OK${ANSI_RESET}"
  done
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
  validateUnitTests
  validateIntegrationTests
}

main
