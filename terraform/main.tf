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

resource "aws_lambda_function" "s3_lambda" {
  function_name    = "s3_lambda_function"
  role             =   aws_iam_role.function_role.arn
  handler          = "src/lambda_function.lambda_handler"
  runtime          = "python3.6"
  timeout          = "900"
  filename         = "src.zip"
  source_code_hash = filebase64sha256("src.zip")
}

# Create a bucket
resource "aws_s3_bucket" "test-bucket" {
  bucket = "test-bucket"
}

resource "aws_s3_bucket_acl" "test-bucket-acl" {
  bucket = aws_s3_bucket.test-bucket.id
  acl    = "public-read" # or can be "private"
}

resource "aws_s3_bucket_notification" "s3_lambda_trigger" {
  bucket = aws_s3_bucket.test-bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_lambda.arn
    events              = ["s3:ObjectCreated:*"]
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
        Resource = "${aws_dynamodb_table.files.arn}"
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

resource "aws_cloudwatch_log_group" "function_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.s3_lambda.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_role" "function_role" {
  name               = "function-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : "sts:AssumeRole",
        Effect : "Allow",
        Principal : {
          "Service" : "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "function_logging_policy" {
  name   = "function-logging-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect : "Allow",
        Resource : "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
  role = aws_iam_role.function_role.id
  policy_arn = aws_iam_policy.function_logging_policy.arn
}