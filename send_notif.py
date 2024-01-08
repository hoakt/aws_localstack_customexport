import requests
import os
import json
import boto3
import urllib.parse

aws_endpoint = os.environ.get('S3_ENDPOINT')
slack_webhook = os.environ.get('SLACK_URL')
s3_client = boto3.client('s3', endpoint_url=aws_endpoint)

def handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    try:
        res = requests.post(
            url=slack_webhook
            , headers={'Content-type': 'application/json'}
            , json={"text":":white_check_mark: Object key {} has been uploaded to bucket {} successfully !".format(key, bucket)}
        )
        return {
                'statusCode': res.status_code,
                'body': json.dumps('File key {} has been uploaded successfully'.format(key))
            }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Cannot send notification: {e}')
        }