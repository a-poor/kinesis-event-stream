terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

variable "firehose_stream_name" {
  type = string
  default = "kinesis-test-stream"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "test-event-stream-bucket"
  acl    = "private"
  force_destroy = true
}

resource "aws_kinesis_firehose_delivery_stream" "kinesis_event_stream" {
  name        = var.firehose_stream_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.bucket.arn
    buffer_size = 1
    buffer_interval = 60
    compression_format = "GZIP"
  }
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_test_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",  
  "Statement":
  [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  inline_policy {
    name = "kinesis-s3-inline-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {      
          Effect = "Allow",      
          Action = [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
          ]      
          Resource = [        
            "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}",
            "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"		    
          ]    
        },
        {
          Effect = "Allow"
          Action = [
            "kinesis:DescribeStream",
            "kinesis:GetShardIterator",
            "kinesis:GetRecords",
            "kinesis:ListShards"
          ]
          Resource = "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deliverystream/${var.firehose_stream_name}"
        }
      ]
    })
  }
}

