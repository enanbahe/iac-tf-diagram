# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create a dynamodb table to support the Lambda Authorizer in the validation of JWT Tokens
# The dynamodb table can contain 2 types of items (partition keys):
#   - jwtKID to store a public key as cache which is used to validate JWT tokens.
#   - policy to store JSON format IAM Policy to authorize the consumption of an API endpoint.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "aws_dynamodb_table" "dydb_authz" {
  name = local.table_name
  billing_mode   = var.dynamodb_config["billing_mode"]
  read_capacity  = var.dynamodb_config["read_capacity"]
  write_capacity = var.dynamodb_config["write_capacity"]  
  hash_key       = local.hash_key_name # Possible values: jwtKID | policy
  range_key      = local.range_key_name # For jwtKID item type will be the key.kid and for policy item type will be the app-role-name

  attribute {
    name = local.hash_key_name
    type = local.hash_key_type
  }

  attribute {
    name = local.range_key_name
    type = local.range_key_type
  }

  tags = module.standard_tags.standard-tags
}

data "aws_iam_policy_document" "dydb_app_role_map_iam_policy" {
  for_each = local.dydb_app_role_map

  dynamic "statement" {
    for_each = each.value
    content {
      # sid = lookup(statement.value, "sid", null)
      effect = lookup(statement.value, "effect", "Deny")
      actions = [
        "execute-api:Invoke",
        "execute-api:InvalidateCache"                  
      ]
      resources = lookup(statement.value, "resources", ["*"])
    }
  }
}

resource "aws_dynamodb_table_item" "dydb_app_role_map" {
  for_each = local.dydb_app_role_map

  table_name = aws_dynamodb_table.dydb_authz.name
  hash_key   = local.hash_key_name
  range_key  = local.range_key_name

  item = <<ITEM
{
  "${local.hash_key_name}": {"${local.hash_key_type}": "${local.app_role_hash_key_value}"},
  "${local.range_key_name}": {"${local.range_key_type}": "${each.key}"},
  "${local.app_role_policy_attr_name}": {"${local.app_role_policy_attr_type}": "${base64encode(data.aws_iam_policy_document.dydb_app_role_map_iam_policy[each.key].json)}"} 
}
ITEM
}
