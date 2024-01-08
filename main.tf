resource "aws_s3_bucket" "sql-bucket" {
  bucket = var.s3_sql_bucket
}

resource "aws_s3_bucket" "csv_bucket" {
  bucket = var.s3_csv_bucket
}

resource "aws_iam_role" "lambda_role" {
	  name = "lambda-role"
	  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
	
}

resource "aws_iam_role_policy" "lambda_basic_policy" {
	  name = "lambda_basic_policy"
	  role = aws_iam_role.lambda_role.id
	  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "s3:*"
      ],
      "Resource": "arn:aws:s3:::*"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "export_data_function" {
  function_name = "lambda_export_data"
  filename         = "lambda_export_data.zip"
  source_code_hash = filebase64sha256("lambda_export_data.zip")
  handler          = "lambda_export_data.handler"
  runtime          = "python3.9" 
  role             = aws_iam_role.lambda_role.arn
  timeout          = 10
  environment {
    variables = {
      SLACK_URL=var.slack-webhook-url
      S3_SQL_BUCKET=var.s3_sql_bucket
      S3_CSV_BUCKET=var.s3_csv_bucket
      DB_USER=var.db_user
      DB_PASSWORD=var.db_password
      DB_HOST=var.db_host
      DB_PORT=var.db_port
      S3_ENDPOINT="http://s3.localhost.localstack.cloud:4566"
    }
  }
}

resource "aws_lambda_function_event_invoke_config" "retry_export_data" {
  function_name                = aws_lambda_function.export_data_function.function_name
  maximum_event_age_in_seconds = 90
  maximum_retry_attempts       = 2
}

resource "aws_lambda_function" "noti_function" {
  function_name    = "send_notif"
  filename         = "send_notif.zip"
  source_code_hash = filebase64sha256("send_notif.zip")
  handler          = "send_notif.handler"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_role.arn
  timeout          = 10
  environment {
    variables = {
      SLACK_URL=var.slack-webhook-url
      S3_ENDPOINT="http://s3.localhost.localstack.cloud:4566"
    }
  }
}

resource "aws_lambda_function" "alarm_function" {
  function_name    = "send_alarm"
  filename         = "send_alarm.zip"
  source_code_hash = filebase64sha256("send_alarm.zip")
  handler          = "send_alarm.handler"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_role.arn
  timeout          = 10
  environment {
    variables = {
      SLACK_URL=var.slack-webhook-url
    }
  }
}


# trigger lambda to export data every 5 mins
resource "aws_cloudwatch_event_rule" "lambda_trigger_rule" {
  name = "lambda-trigger-upload"
  description = "Fires every five minutes"
  schedule_expression = "rate(10 minutes)"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_export" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.export_data_function.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.lambda_trigger_rule.arn
}

resource "aws_cloudwatch_event_target" "lambda_export_data_target" {
  rule = aws_cloudwatch_event_rule.lambda_trigger_rule.name
  target_id = "export-csv-and-upload"
  arn = aws_lambda_function.export_data_function.arn
  input = <<JSON
{
  "tenant": "hoatran-vdata.vincere.io",
  "csv_file_name": "candidate.csv"
}
JSON
}

# trigger notification
resource "aws_lambda_permission" "allow_s3_trigger_notif" {
  statement_id = "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.noti_function.function_name
  principal = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.csv_bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.csv_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.noti_function.arn
    events              = ["s3:ObjectCreated:*"]  # Trigger on object creation
  }
}

# trigger alarm
resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm_metric" {
  alarm_name          = "LambdaErrorAlarm"  # Replace with desired name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60" # stats of error within 60s
  statistic           = "Sum"
  threshold           = "1"  # Trigger if any errors occur

  dimensions = {
    FunctionName = "${aws_lambda_function.export_data_function.function_name}"
  }
  alarm_description = "Alarm when Lambda function encounters errors"
  alarm_actions     = ["${aws_sns_topic.lambda_alarm_topic.arn}"]  # call sns notif
}

resource "aws_sns_topic" "lambda_alarm_topic" {
  name = "lambda-export-alarm"
}

resource "aws_sns_topic_subscription" "lambda_alarm_function_subscription" {
  topic_arn = aws_sns_topic.lambda_alarm_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alarm_function.arn
  depends_on = [
    aws_sns_topic.lambda_alarm_topic
  ]
}

resource "aws_lambda_permission" "allow_sns_call_lambda_notif" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alarm_function.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.lambda_alarm_topic.arn
}
