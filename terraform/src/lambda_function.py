import os
import json
import boto3

dynamodb = boto3.resource('dynamodb')

table = dynamodb.Table('Files')


def lambda_handler(event, context):
    """
    Lambda Function for Sending Data event

    Args:
        event ([type]): Json event
        context ([type]): [description]
    """
    data_response = serialize_event_data(event)
    response = table.put_item(
    Item = data_response
    )
    

def serialize_event_data(json_data):
    """
    Extract data from s3 event

    Args:
        json_data ([type]): Event JSON Data
    """
    bucket = json_data["Records"][0]["s3"]["bucket"]["name"]
    timestamp = json_data["Records"][0]["eventTime"]
    s3_key = json_data["Records"][0]["s3"]["object"]["key"]
    s3_data_size = json_data["Records"][0]["s3"]["object"]["size"]
    ip_address = json_data["Records"][0]["requestParameters"][
        "sourceIPAddress"]
    event_type = json_data["Records"][0]["eventName"]
    owner_id = json_data["Records"][0]["s3"]["bucket"]["ownerIdentity"][
        "principalId"]
    
    return_json_data = {
        "event_timestamp": timestamp,
        "bucket_name": bucket,
        "FileName": s3_key,
        "object_size": s3_data_size,
        "source_ip": ip_address,
        "event_type": event_type,
        "owner_identity": owner_id
    }

    return return_json_data

