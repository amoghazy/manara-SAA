data "archive_file" "upload_function_zip" {
  type        = "zip"
  source_dir = "../lambda-uploadobject"
  output_path = "uploadfunction.zip"
}

data "archive_file" "getobjects_function_zip" {
  type        = "zip"
  source_dir = "../lambda-getobjects"
  output_path = "getobjectsfunction.zip"
}

# Upload function
resource "aws_lambda_function" "upload_function" {
  filename         = data.archive_file.upload_function_zip.output_path
  function_name    = "${var.project_name}-upload"
  role             = aws_iam_role.lambda_role.arn
  handler          = "uploadfunction.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.upload_function_zip.output_base64sha256
  
  environment {
    variables = {
      SOURCE_BUCKET      = aws_s3_bucket.source_bucket.bucket
      DESTINATION_BUCKET = aws_s3_bucket.destination_bucket.bucket
      TABLE_NAME         = aws_dynamodb_table.users_table.name
    }
  }
}

# Get objects function
resource "aws_lambda_function" "getobjects_function" {
  filename         = data.archive_file.getobjects_function_zip.output_path
  function_name    = "${var.project_name}-getobjects"
  role             = aws_iam_role.lambda_role.arn
  handler          = "getobjectsfunction.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.getobjects_function_zip.output_base64sha256
  
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users_table.name
    }
  }
}



# Fixed Lambda Permissions
resource "aws_lambda_permission" "api_upload_permission" {
  statement_id  = "AllowAPIGatewayInvokeUpload"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_getobjects_permission" {
  statement_id  = "AllowAPIGatewayInvokeGetobjects"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.getobjects_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
