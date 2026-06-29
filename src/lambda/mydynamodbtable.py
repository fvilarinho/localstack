import json, os, boto3

dynamodb = boto3.resource("dynamodb", endpoint_url=os.getenv("ENDPOINT_URL"))
table    = dynamodb.Table("my-dynamodb-table")

def handler(event, context):
    try:
        result = table.scan()
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(result["Items"])
        }
    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Internal server error"})
        }
