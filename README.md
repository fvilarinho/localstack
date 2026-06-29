```
█      ███   ███   ███  █      ████ █████  ███   ███  █   █
█     █   █ █     █   █ █     █       █   █   █ █     █  █
█     █   █ █     █████ █      ███    █   █████ █     ███
█     █   █ █     █   █ █         █   █   █   █ █     █  █
█████  ███   ███  █   █ █████ ████    █   █   █  ███  █   █

========================== DEMO ===========================
```

A local AWS development environment using LocalStack and demonstrating an event-driven architecture where S3 object 
operations automatically trigger a Lambda function that records activity in DynamoDB.

## Architecture

```
S3 Bucket (my-bucket)
    │
    │  ObjectCreated / ObjectRemoved events
    ▼
Lambda Function (my-lambda)          ← Python 3.12
    │
    │  PutItem / DeleteItem
    ▼
DynamoDB Table (my-dynamodb-table)
```

When a file is uploaded to the S3 bucket, the Lambda function records its filename (key), timestamp, source IP, and 
Etag (MD5 hash) in DynamoDB. When a file is deleted, the corresponding record is removed from DynamoDB.

## Prerequisites

The following software are required:

| Name                                                                                                   | Purpose                                                 | Install   |
|--------------------------------------------------------------------------------------------------------|---------------------------------------------------------|-----------|
| [Python 3](https://www.python.org/downloads/)                                                          | Programming language used by Lambda function and CLIs   | Manual    |
| [Python venv](https://docs.python.org/3/library/venv.html)                                             | Python Virtual Environment                              | Automatic |
| [Python pip](https://docs.python.org/3/installing/index.html)                                          | Python Package Installer                                | Automatic |
| [boto3](https://aws.amazon.com/pt/sdk-for-python/)                                                     | Official AWS SDK for Python used in the Lambda function | Automatic | 
| [Docker](https://www.docker.com/)                                                                      | Runs the LocalStack container                           | Manual    |    
| [Terraform](https://developer.hashicorp.com/terraform)                                                 | Provisions AWS resources locally                        | Manual    |
| [jq](https://jqlang.org/)                                                                              | JSON parsing in validation scripts                      | Manual    |
| [awscli-local](https://github.com/localstack/awscli-local)                                             | AWS CLI wired to LocalStack                             | Automatic |
| [localstack cli](https://docs.localstack.cloud/aws/developer-tools/running-localstack/localstack-cli/) | LocalStack CLI used to export the resources state       | Automatic |

For the manual dependencies, please follow the installation instructions for your operating system. 

## Getting Started

### 1. Configure environment

First, you'll need to create a LocalStack trial account in [LocalStack](https://localstack.cloud/). After that,  create 
a `.env`  file or export the following variables before starting. If you wish, use the `.env.template` as a starting 
point:

```bash
LOCALSTACK_IMAGE=localstack/localstack-pro
LOCALSTACK_AUTH_TOKEN=<your-token>
DEBUG=0
ENFORCE_IAM=1
```

### 2. One-command setup

```bash
make
```

This runs three steps in sequence:

| Step      | What it does                                                                        |
|-----------|-------------------------------------------------------------------------------------|
| `install` | Check/Install dependencies and boot LocalStack container                            |
| `dist`    | Provision the resourcs (`terraform init → plan → apply`, `localstack state export`) |
| `check`   | Verifies all provisioned resources are live                                         |

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
├── validate.sh             # Post-deploy resource validation
├── requirements.txt        # Python dependencies
├── iac/                    # Infrastructure as Code 
│   ├── main.tf             # AWS provider wired to LocalStack endpoints
│   ├── variables.tf        # Region, credentials, endpoint defaults
│   ├── s3.tf               # S3 bucket, objects, and bucket notification
│   ├── lambda.tf           # Lambda function packaging and definition
│   ├── dynamodb.tf         # DynamoDB table definition
│   └── iam.tf              # IAM role, policies, and S3 invoke permission
└── src/
    ├── lambda/
    │   └── mylambda.py     # Lambda handler (Python 3.12)
    ├── s3/                 # Files to be uploaded to the bucket on deploy
    └── tests/
        └── resources.json  # Resource name config used by validate.sh
```

## Lambda Function

`src/lambda/mylambda.py` processes S3 event notifications:

- **ObjectCreated** → writes `{ filename, timestamp, etag, source_ip }` to DynamoDB
- **ObjectRemoved** → deletes the record by `filename`

The DynamoDB endpoint is passed in via the `ENDPOINT_URL` environment variable, set automatically by Terraform during 
deployment.

## LocalStack Container

The container is defined in `docker-compose.yml` and listens on:

- `localhost:4566` — main LocalStack gateway
- `localhost:4510–4559` — service-specific ports

All Terraform resources target `localhost.localstack.cloud:4566` by default (configurable via the `endpoint` variable 
in `variables.tf`).

## Contact
- Website: https://vilanet.sh
- e-Mail: [me@vila.net.br](mailto:me@vila.net.br)
- LinkedIn: [https://www.linkedin.com/in/fvilarinho](https://www.linkedin.com/in/fvilarinho)