# Terraform configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

# Provider
provider "aws" {
  profile = var.profile
  region  = var.region
}

# Variables
variable "profile" {}
variable "region" {}
locals {
  function_name = "greeting"
}

# Archive
data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "layer"
  output_path = "archive/layer.zip"
}
data "archive_file" "function_zip" {
  type        = "zip"
  source_file = "src/lambda_function.py"
  output_path = "archive/function.zip"
}

# Layer
resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name       = "${local.function_name}-layer"
  filename         = data.archive_file.layer_zip.output_path
  source_code_hash = data.archive_file.layer_zip.output_base64sha256
}

# Function
resource "aws_lambda_function" "lambda_function" {
  function_name = local.function_name
  filename      = data.archive_file.function_zip.output_path
  # function entrypoint
  handler          = "lambda_function.lambda_handler"
  role             = aws_iam_role.iam_for_lambda.arn
  source_code_hash = data.archive_file.function_zip.output_base64sha256
  runtime          = "python3.9"

  layers = [aws_lambda_layer_version.lambda_layer.arn]
}

# Function URLs
resource "aws_lambda_function_url" "lambda_function_url" {
  function_name      = aws_lambda_function.lambda_function.function_name
  # [AWS_IAM] または [NONE]
  authorization_type = "NONE"
}

# Cloudwatch
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "events.amazonaws.com"
}

# IAM
data "aws_iam_policy_document" "assume_policy_for_lamda" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "LambdaRole-${local.function_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_policy_for_lamda.json
}

resource "aws_iam_role_policy_attachment" "policy_attachment_for_lambda" {
  role       = aws_iam_role.iam_for_lambda.name
  # CloudWatch Logsへの書き込み
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}



