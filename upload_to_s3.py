import json
import boto3
import os

def handler(event, context):
    bucket_name = os.environ.get('BUCKET_NAME')
    aws_endpoint = os.environ.get('S3_ENDPOINT')
    try:
        s3 = boto3.client('s3', endpoint_url=aws_endpoint)
        text ="this is test string \n this is test string".encode("utf-8")
        s3.put_object(Bucket=bucket_name, Body=text, Key='hello.txt')

        return {
            'statusCode': 200,
            'body': json.dumps('File uploaded successfully')
        }
    except Exception as e:
        print(f"Error uploading file: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error uploading file: {e}')
        }