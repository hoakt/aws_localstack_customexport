import requests
import os
import json

slack_webhook=os.environ.get('SLACK_URL')

def handler(event, context):
    message = "None"
    if "Records" in event:
        if event["Records"][0]["Sns"]:
            message = event["Records"][0]["Sns"]["Message"]
    try:
        res = requests.post(
            url=slack_webhook
            , headers={'Content-type': 'application/json'}
            , json={"text":":boom:ALERT:boom:\n export data got error: {0} \n Check cloudwatch for the log".format(message)}
        )
        return {
                'statusCode': res.status_code,
                'body': json.dumps('send alarm successfully')
            }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Cannot send notification: {e}')
        }