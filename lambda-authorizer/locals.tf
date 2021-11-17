# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Define local variables
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Current Account
data "aws_caller_identity" "current" {}

locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
  # Lambda function
  function_name = "${var.namespace}-fn-lambda-authz"
  function_source_code = {
    s3_bucket = "ace-usw2-blueprint-artifact"
    s3_key = "infrastructure/integration/api/lambda-authorizer/signed/ace-aws-blueprint-lambda-authorizer-${var.lambda_version}.zip"
  }
  memory_size_map = {
    S = 128
    M = 256
    L = 512
    XL = 1024
  }
  signing_profile_version_arns = [
    "arn:aws:signer:us-west-2:873364552094:/signing-profiles/ace_lambda_signing_profile/AL3lFpzTfW"
  ]
  code_signing_config_policy = "Enforce"
  code_signing_config_description = "Lambda Authorizer Blueprint code signing config."
  function_config = {
    description = "Lambda authorizer for API Gateway ID ${var.api_gateway_id}"
    runtime = "nodejs14.x"
    handler = "dist/authorizer.handler"
    memory_size = var.lambda_memory_size != null ? var.lambda_memory_size : local.memory_size_map[var.lambda_memory_t_shirt]
    reserved_concurrent_executions = -1
    timeout = 3
  }
  env_vars = <<EOF
{
  "iam_app_roles": ${jsonencode(local.iam_app_roles)},
  "dydb_app_roles": ${jsonencode(local.dydb_app_roles)},
  "app_role_map_store": "${var.app_role_map_store}",
  "dydb_auth_table_name": "${local.table_name}",
  "hash_key_name": "${local.hash_key_name}",
  "hash_key_type": "${local.hash_key_type}",
  "range_key_name": "${local.range_key_name}",
  "range_key_type": "${local.range_key_type}",
  "auth_hash_key_value": "${local.auth_hash_key_value}",
  "app_role_hash_key_value": "${local.app_role_hash_key_value}",
  "app_role_policy_attr_name": "${local.app_role_policy_attr_name}",
  "app_role_policy_attr_type": "${local.app_role_policy_attr_type}",
  "roles_claim_name": "${var.roles_claim_name}",
  "token_http_header": "${var.token_http_header}",
  "tenant_id": "${var.tenant_id}",
  "oidc_endpoint": "${var.oidc_endpoint}",
  "cache_lifetime": ${var.cache_lifetime},
  "api_gw_execute_base_arn": "${local.api_gw_execute_base_arn}"
}
EOF
  env_vars_base64 = base64encode(local.env_vars)

  # IAM Role for Lambda
  role_name = "lambda-authz"

  # IAM Role for API Gateway to invoke lambda authorizer
  api_gw_role_name = "api-gw-invocation"
  api_gw_authorizer_name = "${var.namespace}-api-gw-authorizer"

  # DynamoDB Table
  table_name = "${var.namespace}-dydb-lambda-authz"
  hash_key_name = "item_type" # partition key
  hash_key_type = "S"
  range_key_name = "item_id" # sort key
  range_key_type = "S"
  auth_hash_key_value = "jwtKID"
  app_role_hash_key_value = "policy"
  app_role_policy_attr_name = "data"
  app_role_policy_attr_type = "B"

  # API Gateway - Execute Base ARN
  api_gw_base_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.api_gateway_id}"
  api_gw_execute_base_arn = "${local.api_gw_base_arn}/${var.environment}"

  # App role map from Azure AD
  app_role_prefix = "${var.namespace}-app"
  app_role_map_flatten = {for role_name, statements in var.app_role_map : role_name =>
    [for statement in statements : {
      effect = statement.effect
      resources = [for resource in setproduct(statement.http_method, statement.resource_path) :
        "${local.api_gw_execute_base_arn}/${resource[0]}/${resource[1]}"
      ]
    }]
  }
  iam_app_role_map = lower(var.app_role_map_store) == "iam" ? local.app_role_map_flatten : {}
  # dydb_app_role_map = lower(var.app_role_map_store) == "dynamodb" ? var.app_role_map : {}
  dydb_app_role_map = lower(var.app_role_map_store) == "dynamodb" ? local.app_role_map_flatten : {}
}
