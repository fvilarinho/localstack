import json, os, boto3

# Instantiates DynamoDB service using the API endpoint passwd via environment variable.
dynamodb = boto3.resource("dynamodb", endpoint_url = os.getenv("ENDPOINT_URL"))
table    = dynamodb.Table("my-dynamodb-table")

# Default handler.
def handler(event, context):
    try:
        print("Received event:")
        print(json.dumps(event))

        # Iterates the event records.
        for record in event["Records"]:
            # Fetches the required attributes (event name, time, source IP address, object key/hash).
            event_name = record["eventName"]
            event_time = record["eventTime"]
            source_ip  = record["requestParameters"]["sourceIPAddress"]
            filename   = record["s3"]["object"]["key"]
            etag       = record["s3"]["object"]["eTag"]

            if event_name.startswith("ObjectCreated"):
                table.put_item(Item = {"filename": filename, "timestamp": event_time, "etag": etag, "source_ip": source_ip})
            elif event_name.startswith("ObjectRemoved"):
                table.delete_item(Key = {"filename": filename})

        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Event processed successfully!"})
        }
    except Exception as e:
        # Error catch.
        print("An error occured during event processing:")
        print(e)

        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Internal server error"})
        }