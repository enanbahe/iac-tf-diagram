locals {
  iam_app_roles = { for role_name, role in module.iam_app_role_map : role_name => {
    role_name = role.role_name
    role_arn = role.role_arn
  }}
  dydb_app_roles = { for role_name, role in aws_dynamodb_table_item.dydb_app_role_map : role_name => {
    # table_name = role.table_name
    hash_key = jsondecode(role.item)[local.hash_key_name][local.hash_key_type]
    range_key = jsondecode(role.item)[local.range_key_name][local.range_key_type]
  }}
}

output "dydb_authz_id" {
  value = aws_dynamodb_table.dydb_authz.id
}

output "lambda_authorizer" {
  description = "Attributes of the Lambda Authorizer"
  value = {
    function_name = aws_lambda_function.lambda_authz.function_name
    function_arn = aws_lambda_function.lambda_authz.arn
  }
}

output "lambda_authorizer_iam_role" {
  description = "Attributes of the IAM Role that will be assumed by Lambda Authorizer"
  value = {
    role_name = module.lambda_authz_exec_role.role_name
    role_arn = module.lambda_authz_exec_role.role_arn
  }
}

output "iam_app_roles" {
  description = "Attributes of the IAM Roles that are mapping to Azure AD roles if app_role_map_store = iam"
  value = local.iam_app_roles
}

output "dydb_app_roles" {
  description = "Attributes of the DynamoDB items that are mapping to Azure AD roles if app_role_map_store = dynamodb"
  value = local.dydb_app_roles
}
