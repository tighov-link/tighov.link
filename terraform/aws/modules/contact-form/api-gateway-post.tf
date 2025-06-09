resource "aws_api_gateway_rest_api" "contact_form_api" {
  name        = "contact-form-api"
  description = "API Gateway for contact form"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "contact_form_api_resource" {
  parent_id   = aws_api_gateway_rest_api.contact_form_api.root_resource_id
  path_part   = "contact-form"
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
}

resource "aws_api_gateway_method" "contact_form_method" {
  authorization = "NONE"
  http_method   = "POST"
  rest_api_id   = aws_api_gateway_rest_api.contact_form_api.id
  resource_id   = aws_api_gateway_resource.contact_form_api_resource.id
}

resource "aws_api_gateway_integration" "contact_form_lambda_integration" {
  http_method = aws_api_gateway_method.contact_form_method.http_method
  resource_id = aws_api_gateway_resource.contact_form_api_resource.id
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.contact_form_lambda_function.invoke_arn

  depends_on = [aws_lambda_function.contact_form_lambda_function]
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  stage_name  = "prod"

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.contact_form_api_resource.id,
      aws_api_gateway_method.contact_form_method.id,
      aws_api_gateway_integration.contact_form_lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.contact_form_lambda_integration,
  ]
}

resource "aws_lambda_permission" "apigw_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact_form_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.contact_form_api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_method_response" "post_response" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  resource_id = aws_api_gateway_resource.contact_form_api_resource.id
  http_method = aws_api_gateway_method.contact_form_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  resource_id = aws_api_gateway_resource.contact_form_api_resource.id
  http_method = aws_api_gateway_method.contact_form_method.http_method
  status_code = aws_api_gateway_method_response.post_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'https://www.${var.domain_name}'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,access-control-allow-origin'"
  }

  depends_on = [aws_api_gateway_integration.contact_form_lambda_integration]
}


output "invoke_url" {
  value       = aws_api_gateway_deployment.api_deployment.invoke_url
  description = "The invoke URL for the contact form API"
}

