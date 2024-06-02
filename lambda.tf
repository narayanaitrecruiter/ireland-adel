

# Create IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create Lambda function
resource "aws_lambda_function" "qa_function" {
  filename      = "./lambda_function_payload.zip" # Replace with your actual zip file
  function_name = "qa_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("lambda_function_payload.zip") # Replace with your actual zip file

  runtime = "python3.8"

  environment {
    variables = {
      foo = "bar"
    }
  }
  
  tags = {
    Environment = "xyz"
    Name        = "qa-lambda"
  }
}

# Create API Gateway
resource "aws_api_gateway_rest_api" "qa_gw" {
  name        = "qa-gw"
  description = "API Gateway for QA Lambda function"
}

resource "aws_api_gateway_resource" "qa_resource" {
  rest_api_id = aws_api_gateway_rest_api.qa_gw.id
  parent_id   = aws_api_gateway_rest_api.qa_gw.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "qa_method" {
  rest_api_id   = aws_api_gateway_rest_api.qa_gw.id
  resource_id   = aws_api_gateway_resource.qa_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "qa_integration" {
  rest_api_id = aws_api_gateway_rest_api.qa_gw.id
  resource_id = aws_api_gateway_resource.qa_resource.id
  http_method = aws_api_gateway_method.qa_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.qa_function.invoke_arn
}

resource "aws_lambda_permission" "qa_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.qa_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.qa_gw.execution_arn}/*/*"
}

# Create CloudWatch log group
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/${aws_lambda_function.qa_function.function_name}"
  retention_in_days = 7
  tags = {
        Environment = "QA"
        Project     = "Lambda logs"
    }
}
