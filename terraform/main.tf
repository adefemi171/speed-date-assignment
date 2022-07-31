locals {
  definition_template = <<EOF
{
  "Comment": "A Hello World example of the Amazon States Language using Pass states",
  "StartAt": "SendToDDB",
  "States": {
    "SendToDDB": {
      "Type": "Task",
      "Resource": "arn:aws:states:::dynamodb:putItem",
      "Parameters": {
        "TableName": "${aws_dynamodb_table.files.name}",
        "Item": {
          "id":{
            "S": "1"
          },
          "description":{
            "S": "test"
          }
        }
      },
      "Next": "InvokeLambda"
    },
    "InvokeLambda": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.s3_lambda.arn}",
      "End": true
    }
  }
}
EOF
}

data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "s3_lambda" {
  function_name    = "s3_lambda_function"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSRoleForLambda"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.6"
  timeout          = "900"
  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
}

# Create a bucket
resource "aws_s3_bucket" "test-bucket" {
  bucket = "test-bucket"
}

resource "aws_s3_bucket_acl" "test-bucket-acl" {
  bucket = aws_s3_bucket.test-bucket.id
  acl    = "public-read" # or can be "private"
}

# Upload an object
resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.test-bucket.id
  key    = "profile"
  acl    = "public-read" # or can be "private"
  source = "test.txt"
  etag   = filemd5("test.txt")

}

resource "aws_s3_bucket_notification" "s3_lambda_trigger" {
  bucket = aws_s3_bucket.test-bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "file-prefix"
    filter_suffix       = "file-extension"
  }
}

resource "aws_lambda_permission" "s3_lambda_permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.test-bucket.id}"
}

resource "aws_iam_role" "s3_state_machine_role" {
  name = "test_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",

        ]
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
        ],
        Resource = "${aws_dynamodb_table.files.arn}" //"arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/Files"
      }
    ]
  })
}

resource "aws_sfn_state_machine" "list-state-machines" {
  name       = "list-state-machines"
  role_arn   = aws_iam_role.s3_state_machine_role.arn
  definition = local.definition_template
}

resource "aws_dynamodb_table" "files" {
  name           = "Files"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "FileName"
  attribute {
    name = "FileName"
    type = "S"
  }
}
