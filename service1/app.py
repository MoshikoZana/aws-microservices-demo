import json
import boto3
import os
from flask import Flask, request, jsonify
from datetime import datetime

app = Flask(__name__)

REGION = os.getenv("AWS_REGION", "us-east-2")
SSM_PARAM_NAME = os.getenv("SSM_PARAM_NAME")
SQS_QUEUE_URL = os.getenv("SQS_QUEUE_URL")

if not SSM_PARAM_NAME or not SQS_QUEUE_URL:
    raise Exception("Missing required env variables: SSM_PARAM_NAME or SQS_QUEUE_URL")

ssm = boto3.client('ssm', region_name=REGION)
sqs = boto3.client('sqs', region_name=REGION)

def get_token_from_ssm():
    try:
        response = ssm.get_parameter(Name=SSM_PARAM_NAME, WithDecryption=True)
        return response['Parameter']['Value']
    except ssm.exceptions.ParameterNotFound:
        raise Exception("SSM token not found")
    except Exception as e:
        raise Exception(f"SSM error: {str(e)}")

def is_valid_timestamp(ts):
    try:
        datetime.fromtimestamp(int(ts))
        return True
    except:
        return False

@app.route('/health')
def health():
    return "OK", 200

@app.route("/", methods=["POST"])
def receive_payload():
    body = request.get_json()
    token = body.get("token")
    data = body.get("data", {})
    timestream = data.get("email_timestream")

    try:
        expected_token = get_token_from_ssm()
    except Exception as e:
        return jsonify({"error": str(e)}), 500

    if token != expected_token:
        return jsonify({"error": "Invalid token"}), 403

    if not is_valid_timestamp(timestream):
        return jsonify({"error": "Invalid or missing timestamp"}), 400

    sqs.send_message(QueueUrl=SQS_QUEUE_URL, MessageBody=json.dumps(data))

    return jsonify({"status": "Message has been accepted"}), 200

if __name__ == "__main__":
    app.run(port=8080, host="0.0.0.0")
