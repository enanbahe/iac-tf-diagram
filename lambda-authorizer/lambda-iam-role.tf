# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create an IAM Role to be assumed by Lambda Authorizer to access to other AWS resources
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "lambda_authz_exec_role" {
  source = "git::git@github.com:Toyota-Motor-North-America/ace-aws-infra-modules//security/access/iam-service-role?ref=security-access-v1.0.2"

  namespace = var.namespace
  role_name = local.role_name
  description = "API Lambda Authorizer for ${var.namespace}"
  principals = ["lambda.amazonaws.com"]
  full_access = []
  policy_arns = []
  statements = [{
      effect = "Allow"
      actions = [
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:Scan",
        "dynamodb:Query",
        "dynamodb:UpdateItem"
      ]
      resources = [
        aws_dynamodb_table.dydb_authz.arn
      ]
      conditions = []
    }, {
      effect = "Allow"
      actions = [
        "dynamodb:Scan",
        "dynamodb:Query"
      ]
      resources = [
        "${aws_dynamodb_table.dydb_authz.arn}/index/*"
      ]
      conditions = []
    }, {
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resources = [
        "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.function_name}*"
      ]
      conditions = []
    }, {
      effect = "Allow"
      actions = [
        "iam:GetPolicyVersion",
        "iam:GetRole",
        "iam:GetPolicy",
        "iam:GetRolePolicy"
      ]
      resources = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.app_role_prefix}-role-*"
      ]
      conditions = []
    }, {
      effect = "Allow"
      actions = [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ]
      resources = [
        "*"
      ]
      conditions = []
    }
  ]

  # tags = module.standard_tags.standard-tags
  application_id   = var.application_id
  application_name = var.application_name
  environment      = var.environment
  created_by_email = var.created_by_email
}
