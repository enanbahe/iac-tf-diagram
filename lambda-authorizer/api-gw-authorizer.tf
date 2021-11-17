# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create an Authorizer to the API Gateway
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "aws_api_gateway_authorizer" "api_gw_authorizer" {
  name = local.api_gw_authorizer_name
  rest_api_id = var.api_gateway_id
  authorizer_uri = aws_lambda_function.lambda_authz.invoke_arn
  type = "TOKEN"
  identity_source = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = var.authorizer_cache_ttl
  # authorizer_credentials = aws_iam_role.invocation_role.arn
}

resource "aws_lambda_permission" "api_gw_lambda_permission" {
  # statement_id  = "AllowMyDemoAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_authz.function_name
  principal     = "apigateway.amazonaws.com"

  # Allows API Gateway REST API to invoke Lambda Authorizer.
  source_arn = "${local.api_gw_base_arn}/authorizers/${aws_api_gateway_authorizer.api_gw_authorizer.id}"
}
