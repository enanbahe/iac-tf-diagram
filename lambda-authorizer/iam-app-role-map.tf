# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create an IAM Role to be assumed by Lambda Authorizer to access to other AWS resources
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module "iam_app_role_map" {
  for_each = local.iam_app_role_map
  source = "git::git@github.com:Toyota-Motor-North-America/ace-aws-infra-modules//security/access/iam-service-role?ref=security-access-v1.0.2"

  namespace = local.app_role_prefix
  role_name = each.key
  description = "Map to app role ${each.key} registered in Identity Provider (e.g. Azure AD)"
  principals = ["lambda.amazonaws.com"]
  full_access = []
  policy_arns = []
  statements = [for app_role in each.value : {
      effect = app_role.effect
      actions = [
        "execute-api:Invoke",
        "execute-api:InvalidateCache"
      ]
      resources = app_role.resources
    }
  ]

  # tags = module.standard_tags.standard-tags
  application_id   = var.application_id
  application_name = var.application_name
  environment      = var.environment
  created_by_email = var.created_by_email
}
