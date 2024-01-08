variable "db_user" {
  default = "khanhhoa.tran"
}

variable "db_password" {
  default = "uORHKBh0BAKntdyw"
}

variable "db_host" {
  default = "syd-frps.vincere.io"
}

variable "db_port" {
  default = "25432"
}

variable "s3_sql_bucket" {
  default = "export-sql"
}

variable "s3_csv_bucket" {
  default = "output-csv"
}

variable "slack-webhook-url" {
  type = string
  default = "https://hooks.slack.com/services/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"
}

variable "local-stack-endpoint" {
  type = string
  default = "http://localhost:4566"
}