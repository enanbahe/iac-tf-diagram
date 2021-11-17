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
    bucket         = local.s3_bucket_name
    key            = local.s3_backend_key
    region         = local.s3_backend_region
    dynamodb_table = local.dynamodb_table_name
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

terraform {
  # source = "../../../../../../..//integration/api/lambda-authorizer"
  source = "git::git@github.com:Toyota-Motor-North-America/ace-aws-infra-modules//integration/api/lambda-authorizer?ref=lambda-authorizer-v0.3.0-beta"
}

locals {
	# REQUIRED
	# Please use the namespace as the app name prefix that was used to create these accounts; generally, this is the application abbreviation from CMDB.
	# Best practice is to use all lower-case, no spaces, and no special characters;

	# Global variables
	namespace_base      = "${local.application_id}-${local.environment}" # ace is the application abbreviation and environment is used to prefix resources within the same account.
	# aws_account_id      = "831531666590"
	aws_region_cd       = "usw2" # short-name for aws region.
	aws_region          = "us-west-2" # aws region where resources will be deployed.
  s3_bucket_name			= "ace-blueprint-usw2-test-terraform-state" # S3 bucket where Terraform state will be stored. For this example is also used to store the lambda authorizer source code.
	s3_bucket_key_base  = "infrastructure/modules/integration/api/lambda-authorizer/examples/terragrunt/dydb-policy-store/id-token" # Base Path for S3 to store Terraform state and lambda authorizer source code.
	s3_backend_region 	= "us-west-2" # Region where the S3 bucket is located.
  s3_backend_key      = "${local.s3_bucket_key_base}/terraform.tfstate" # Path for S3 to store Terraform state.
  dynamodb_table_name = "terraform-locks" # -------------------------- Fixed value for DynamoDB table for storing the status of the Terraform executions for ACE Examples

	# Input variables
  namespace     = "${replace(local.namespace_base, "_", "-")}-dydb-id-token" # Normally a long namespace is not required but there are many examples within the same account.
  s3_bucket_key = "${local.s3_bucket_key_base}/source-code/lambda-authz.zip" # Path for S3 to store lambda authorizer source code.

	# Standard Tags
	application_id   = "ace"
	application_name = "ace-infrastructure-blueprints"
	environment      = "poc"
	created_by_email = "enrique.bassallo@toyota.com"
}

inputs = {
  aws_region  = local.aws_region
  namespace   = local.namespace
  environment = local.environment
  dynamodb_config = {
    billing_mode   = "PROVISIONED" # Controls how you are charged for read and write throughput and how you manage capacity. Possible values: PROVISIONED | PAY_PER_REQUEST
    read_capacity  = 1 # The number of read units for this table. If the billing_mode is PROVISIONED, this field is required
    write_capacity = 1 # The number of write units for this table. If the billing_mode is PROVISIONED, this field is required
  }
  source_code_dest = {
    s3_bucket = local.s3_bucket_name # S3 Bucket in the target account where the Lambda Auuthorizer code will be copied
    s3_key    = local.s3_bucket_key # S3 Bucket Key in the target account where the Lambda Auuthorizer code will be copied
  }
  # token_type         = "id_token" # Use id_token if you will include app roles as claims in the JWT token, otherwise use access_token type
  roles_claim_name = "roles" # Use empty string when JWT tokens do not include app roles as claims, otherwise specifiy the name of the attribute in the token
  api_gateway_id     = "si9uibvzci" # API Gateway was created separately from this example
  app_role_map_store = "dynamodb" # IAM Policies to map app roles will be stored in DynamoDB which is for low latency validations (less than 200ms)
  app_role_map = {
    ACE_ADMIN = [{ # ACE_ADMIN must be a registered app role in Azure AD for this application
      effect        = "Allow"
      http_method   = ["*"] # All methods (GET, PUT, POST, etc.) will be allowed for this app role
      resource_path = ["dydb-based/*"] # All resources under dydb-based path in the API Gateway will be allowed for this app role
    }]
    ACE_RW = [{ # ACE_RW must be a registered app role in Azure AD for this application
      effect        = "Deny"
      http_method   = ["*"] # All methods (GET, PUT, POST, etc.) will be denied for this app role
      resource_path = ["dydb-based/admin", "dydb-based/admin/*"] # All resources under dydb-based/admin path in the API Gateway will be denied for this app role
    },{
      effect        = "Allow"
      http_method   = ["*"] # All methods (GET, PUT, POST, etc.) will be allowed for this app role
      resource_path = ["dydb-based/caas", "dydb-based/caas/*"] # All resources under dydb-based/caas path in the API Gateway will be allowed for this app role
    }]
    ACE_RO = [{ # ACE_RO must be a registered app role in Azure AD for this application
      effect        = "Deny"
      http_method   = ["*"] # All methods (GET, PUT, POST, etc.) will be denied for this app role
      resource_path = ["dydb-based/admin", "dydb-based/admin/*"] # All resources under dydb-based/admin path in the API Gateway will be denied for this app role
    },{
      effect        = "Allow"
      http_method   = ["GET"] # Only GET methods will be allowed for this app role
      resource_path = ["dydb-based/caas", "dydb-based/caas/*"] # All resources under dydb-based/caas path in the API Gateway will be allowed for this app role
    }]
  }
  tenant_id            = "9107b728-2166-4e5d-8d13-d1ffdf0351ef" # Azure AD Tenant ID
  oidc_endpoint        = "https://login.microsoftonline.com/9107b728-2166-4e5d-8d13-d1ffdf0351ef/v2.0/.well-known/openid-configuration" # Endpoint to retrieve public keys for Tenant ID
  cache_lifetime       = 3600000 # Time in milliseconds to cache public keys in DynamoDB table
  authorizer_cache_ttl = 60 # Time in seconds to cache authorizations in API Gateway
  debug_mode           = true # True to get more details in the execution of the Lambda Authorizer. False is recommendable for prod account

  # Standard Tags
  application_id   = local.application_id
  application_name = local.application_name
  environment      = local.environment
  created_by_email = local.created_by_email
}
