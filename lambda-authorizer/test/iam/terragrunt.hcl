# Remote backend configuration values
locals {
    aws_region = "us-west-2"
    s3_backend = "ace-blueprint-usw2-test-terraform-state"
    s3_backend_key = "infrastructure/modules/integration/api/lambda-authorizer/test/iam/terraform.tfstate"
    s3_backend_region = "us-west-2"
    s3_backend_locks = "terraform-locks"
}

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = local.s3_backend
    key            = local.s3_backend_key
    region         = local.s3_backend_region
    dynamodb_table = local.s3_backend_locks
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

terraform {
  source = "../../../../..//integration/api/lambda-authorizer"
}

inputs = {
  aws_region = "us-west-2"
  namespace = "ace-test-iam-map-store"
  environment = "test"
  dynamodb_config = {
    billing_mode = "PROVISIONED" # Controls how you are charged for read and write throughput and how you manage capacity. Possible values: PROVISIONED | PAY_PER_REQUEST
    read_capacity = 1 # The number of read units for this table. If the billing_mode is PROVISIONED, this field is required
    write_capacity = 1 # The number of write units for this table. If the billing_mode is PROVISIONED, this field is required
  }
  source_code_dest = {
    s3_bucket = "ace-blueprint-usw2-test-terraform-state"
    s3_key = "infrastructure/modules/integration/api/lambda-authorizer/test/iam/source-code/lambda-authz.zip"
  }
  # token_type = "id_token"
  roles_claim_name = "roles" # Use empty string when JWT tokens do not include app roles as claims, otherwise specifiy the name of the attribute in the token
  api_gateway_id = "si9uibvzci"
  app_role_map_store = "iam"
  app_role_map = {
    ACE_ADMIN = [{
      effect = "Allow"
      http_method = ["*"]
      resource_path = ["iam-based/*"]
    }]
    CaaS_RW = [{
      effect = "Deny"
      http_method = ["*"]
      resource_path = ["iam-based/admin", "iam-based/admin/*"]
    },{
      effect = "Allow"
      http_method = ["*"]
      resource_path = ["iam-based/caas", "iam-based/caas/*"]
    }]
    CaaS_RO = [{
      effect = "Deny"
      http_method = ["*"]
      resource_path = ["iam-based/admin", "iam-based/admin/*"]
    },{
      effect = "Allow"
      http_method = ["GET"]
      resource_path = ["iam-based/caas", "iam-based/caas/*"]
    }]
    FaaS_RW = [{
      effect = "Deny"
      http_method = ["*"]
      resource_path = ["iam-based/admin", "iam-based/admin/*"]
    },{
      effect = "Allow"
      http_method = ["*"]
      resource_path = ["iam-based/faas/*", "iam-based/faas"]
    }]
    FaaS_RO = [{
      effect = "Deny"
      http_method = ["*"]
      resource_path = ["iam-based/admin", "iam-based/admin/*"]
    },{
      effect = "Allow"
      http_method = ["GET"]
      resource_path = ["iam-based/faas/*", "iam-based/faas"]
    }]
  }

  # Tags
  tags = {
    application_id = "ace"
    application_name = "ace-infrastructure-blueprints"
    business_unit = "ace"
    environment = "example"
    created_by = "456586"
    cost_center = "955011"
  }
}
