import boto3
import os
import json
import time
import uuid

REGION = os.getenv("AWS_REGION", "us-east-2")
SQS_QUEUE_URL = os.getenv("SQS_QUEUE_URL")
S3_BUCKET = os.getenv("S3_BUCKET")
S3_FOLDER = os.getenv("S3_FOLDER", "emails/")

if not SQS_QUEUE_URL or not S3_BUCKET:
    raise Exception("Missing required env variables: SQS_QUEUE_URL or S3_BUCKET")

sqs = boto3.client('sqs', region_name=REGION)
s3 = boto3.client('s3', region_name=REGION)

def process_messages():
    response = sqs.receive_message(
        QueueUrl=SQS_QUEUE_URL,
        MaxNumberOfMessages=5,
        WaitTimeSeconds=10
    )

    messages = response.get('Messages', [])
    for msg in messages:
        try:
            body = msg['Body']
            print(f"Processing message: {body}")

            try:
                parsed = json.loads(body)
            except json.JSONDecodeError:
                print("Skipping invalid JSON message")
                continue

            key = f"{S3_FOLDER}{uuid.uuid4()}.json"
            s3.put_object(
                Bucket=S3_BUCKET,
                Key=key,
                Body=body,
                ContentType='application/json'
            )

            sqs.delete_message(
                QueueUrl=SQS_QUEUE_URL,
                ReceiptHandle=msg['ReceiptHandle']
            )
            print(f"Uploaded to S3 as {key}")
        except Exception as e:
            print(f"Error processing message: {str(e)}")

if __name__ == "__main__":
    while True:
        process_messages()
        time.sleep(30)
