```
█      ███   ███   ███  █      ████ █████  ███   ███  █   █
█     █   █ █     █   █ █     █       █   █   █ █     █  █
█     █   █ █     █████ █      ███    █   █████ █     ███
█     █   █ █     █   █ █         █   █   █   █ █     █  █
█████  ███   ███  █   █ █████ ████    █   █   █  ███  █   █

========================== DEMO ===========================
```
A local AWS development environment using LocalStack and demonstrating an event-driven architecture where S3 object
operations automatically trigger a Lambda function that records activity in DynamoDB, and an API Gateway endpoint
that exposes the recorded data via a REST API.

## Architecture

```
S3 Bucket (my-bucket)
    │
    │  ObjectCreated / ObjectRemoved events
    ▼
Lambda Function (my-lambda)
    │
    │  PutItem / DeleteItem
    ▼
DynamoDB Table (my-dynamodb-table)
    ▲
    │  Scan
    │
Lambda Function (my-dynamodb-table)
    ▲
    │  GET /get_items
    │
API Gateway (my-api) [stage: v1]
```

When a file is uploaded to the S3 bucket, `my-lambda` records its filename (key), timestamp, source IP, and
Etag (MD5 hash) in DynamoDB. When a file is deleted, the corresponding record is removed. The `my-dynamodb-table`
Lambda is invoked by API Gateway (`GET /v1/get_items`) and returns all current items from the DynamoDB table.

## Prerequisites

The following software are required:

| Name                                                                                                   | Purpose                                                  | Install   |
|--------------------------------------------------------------------------------------------------------|----------------------------------------------------------|-----------|
| [Python 3](https://www.python.org/downloads/)                                                          | Programming language used by Lambda functions and CLIs   | Manual    |
| [Python venv](https://docs.python.org/3/library/venv.html)                                             | Python Virtual Environment                               | Automatic |
| [Python pip](https://docs.python.org/3/installing/index.html)                                          | Python Package Installer                                 | Automatic |
| [boto3](https://aws.amazon.com/pt/sdk-for-python/)                                                     | Official AWS SDK for Python used in the Lambda functions | Automatic |
| [Docker](https://www.docker.com/)                                                                      | Runs the LocalStack container                            | Manual    |
| [Terraform](https://developer.hashicorp.com/terraform)                                                 | Provisions AWS resources locally                         | Manual    |
| [jq](https://jqlang.org/)                                                                              | JSON parsing in validation scripts                       | Manual    |
| [awscli-local](https://github.com/localstack/awscli-local)                                             | AWS CLI wired to LocalStack                              | Automatic |
| [localstack cli](https://docs.localstack.cloud/aws/developer-tools/running-localstack/localstack-cli/) | LocalStack CLI used to export the resources state        | Automatic |

For the manual dependencies, please follow the installation instructions for your operating system.

## Getting Started

### 1. Configure environment

First, you'll need to create a trial account at [LocalStack](https://localstack.cloud/). After that, create a `.env` 
file or export the following variables before starting. Use `.env.template` as a starting point:

```bash
LOCALSTACK_IMAGE=localstack/localstack-pro:latest
LOCALSTACK_AUTH_TOKEN=<your-token>
LOCALSTACK_DEBUG=1
```

### 2. One-command setup

```bash
make
```

This runs three steps in sequence:

| Step      | What it does                                                                         |
|-----------|--------------------------------------------------------------------------------------|
| `install` | Check/Install dependencies and boot the LocalStack container                         |
| `dist`    | Provision the resources (`terraform init → plan → apply`, `localstack state export`) |
| `check`   | Verifies all provisioned resources are live and runs unit + integration tests        |

You can also run each step individually:

```bash
make install   # install only
make dist      # provisioning only
make check     # validation only
make clean     # stop LocalStack and remove generated/temporary files
```

## Project Structure

```
.
├── docker-compose.yml      # LocalStack container definition
├── Makefile                # Top-level workflow orchestration
├── functions.sh            # Shared shell utilities and ANSI helpers
├── install.sh              # Check/Install dependencies
├── start.sh                # Boot LocalStack container
├── stop.sh                 # Shutdown LocalStack container
├── deploy.sh               # Provision the resources
├── validate.sh             # Post-deploy resource validation and tests
├── requirements.txt        # Python dependencies (boto3, boto3-stubs)
├── iac/                    # Infrastructure as Code
│   ├── main.tf             # AWS provider wired to LocalStack endpoints
│   ├── variables.tf        # Region, credentials, endpoint defaults
│   ├── s3.tf               # S3 bucket, objects, and bucket notification
│   ├── lambda.tf           # Lambda function packaging and definitions
│   ├── dynamodb.tf         # DynamoDB table definition
│   ├── iam.tf              # IAM role, policies, and invoke permissions
│   └── apigateway.tf       # API Gateway REST API wired to Lambda
└── src/
    ├── lambda/
    │   ├── mylambda.py          # S3 event handler (Python 3.12)
    │   └── mydynamodbtable.py   # DynamoDB scan handler (Python 3.12)
    ├── s3/                      # Files to be uploaded to the bucket on deploy
    └── tests/
        ├── resources.json       # Resource name config used by validate.sh
        └── units.json           # Unit test definitions used by validate.sh
```

## Lambda Functions

### `src/lambda/mylambda.py` — S3 event handler

Processes S3 event notifications triggered by the bucket:

- **ObjectCreated** → writes `{ filename, timestamp, etag, source_ip }` to DynamoDB via `PutItem`
- **ObjectRemoved** → deletes the record by `filename` via `DeleteItem`

### `src/lambda/mydynamodbtable.py` — DynamoDB query handler

Invoked by API Gateway on `GET /v1/get_items`:

- Performs a `Scan` on the DynamoDB table and returns all items as a JSON array

Both functions receive the DynamoDB endpoint via the `ENDPOINT_URL` environment variable, set automatically by 
Terraform during deployment.

## API Gateway

A REST API (`my-api`) is provisioned with a single endpoint:

| Method | Path        | Stage | Lambda Function   |
|--------|-------------|-------|-------------------|
| GET    | /get_items  | v1    | my-dynamodb-table |

The full URL when running locally:
```
http://localhost:4566/restapis/<api-id>/v1/_user_request_/get_items
```

## IAM

A single IAM role (`lambda`) is shared by both Lambda functions and has:

- `AWSLambdaBasicExecutionRole` — basic execution and logging
- Inline policy `lambda-my-dynamodb-table` — `dynamodb:PutItem`, `dynamodb:DeleteItem`, `dynamodb:Scan` on the 
DynamoDB table
- Resource-based permission allowing S3 to invoke `my-lambda`
- Resource-based permission allowing API Gateway to invoke `my-dynamodb-table`

## Validation & Tests

`validate.sh` runs automatically as part of `make check` and performs:

| Check                  | What it verifies                                                              |
|------------------------|-------------------------------------------------------------------------------|
| IAM                    | Role and inline policy exist with the correct actions                         |
| S3                     | Bucket exists and bucket notification is configured for both event types      |
| Lambda                 | Both functions exist, have invoke permissions, and use the correct IAM role   |
| DynamoDB               | Table exists                                                                  |
| API Gateway            | REST API, path, method, and Lambda integration are configured correctly       |
| Unit tests             | Direct Lambda invocations with known payloads against expected responses      |
| Integration test       | Uploads a file via S3, queries the API Gateway, and verifies the full flow    |

Unit test cases are defined in `src/tests/units.json` and cover:

- `invalid_payload` — expects HTTP 500 from `my-lambda` on malformed input
- `put_event` — expects HTTP 200 and a DynamoDB write from `my-lambda`
- `get_items` — expects HTTP 200 and the previously written item from `my-dynamodb-table`
- `remove_event` — expects HTTP 200 and a DynamoDB delete from `my-lambda`

## Contact

- Website: https://vilanet.sh
- e-Mail: [me@vila.net.br](mailto:me@vila.net.br)
- LinkedIn: [https://www.linkedin.com/in/fvilarinho](https://www.linkedin.com/in/fvilarinho)
