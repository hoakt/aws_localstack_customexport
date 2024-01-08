import boto3
import pathlib
import sqlalchemy
import json
import pandas as pd
import os

db_user = os.environ.get("DB_USER")
db_password = os.environ.get("DB_PASSWORD")
db_host = os.environ.get("DB_HOST")
db_port = os.environ.get("DB_PORT")
aws_endpoint = os.environ.get('S3_ENDPOINT')

s3_client = boto3.client('s3', endpoint_url=aws_endpoint)

def create_engine(tenant:str):
    return sqlalchemy.create_engine(
                    'postgresql+psycopg2://{0}:{1}@{2}:{3}/{4}'.format(
                        db_user, db_password,
                        db_host, db_port,
                        tenant),
                    pool_size=100,
                    max_overflow=200,
                    client_encoding='utf8')

def sql_to_csv(sql, tenant, output_file_path):
    try:
        engine = create_engine(tenant)
        result = pd.read_sql(sql, engine)
        result.to_csv(f"{output_file_path}", index=False)
    except Exception as e:
        raise e

def upload_to_s3(source_path,tenant,csv_file_name):
    bucket = os.environ.get("S3_CSV_BUCKET")
    dest_path = tenant + '/'+ csv_file_name
    s3_client.upload_file(source_path, bucket, dest_path)

def handler(event, context):
    bucket = os.environ.get("S3_SQL_BUCKET")
    s3_prefix = event['tenant']
    print(f"bucket: {bucket}, prefix: {s3_prefix}")
    tmp_csv_folder = f"/tmp/{event['tenant']}/"
    pathlib.Path(tmp_csv_folder).mkdir(parents=True, exist_ok=True)

    list_sqls = s3_client.list_objects(Bucket=bucket, Prefix=s3_prefix)
    print(list_sqls)
    for cont in list_sqls['Contents']:
        obj = s3_client.get_object(Bucket=bucket, Key=cont['Key'])
        sql = obj["Body"].read().decode("utf-8")
        output_file_path = tmp_csv_folder + event['csv_file_name'] or 'output.csv'
        try:
            sql_to_csv(sql, event['tenant'], output_file_path)
            upload_to_s3(output_file_path, event['tenant'], event['csv_file_name'] )
            os.remove(output_file_path)
            return {
                'statusCode': 200,
                'body': json.dumps('exported csv successfully')
            }
        except Exception as e:
            print(e)
            return {
                'statusCode': 500,
                'body': json.dumps("Failed to upload {0} to S3 with error: {1}".format(output_file_path, e))
            }
