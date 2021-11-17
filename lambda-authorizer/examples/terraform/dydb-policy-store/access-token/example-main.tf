# Remote backend configuration values
locals {
  aws_region = "us-west-2" # aws region where resources will be deployed. 
  environment = "poc"
  namespace = "ace-${local.environment}-tf-dydb-access-token" # Normally a long namespace is not required but there are many examples within the same account. 
  s3_bucket_name = "ace-blueprint-usw2-test-terraform-state" # S3 bucket where Terraform state will be stored. For this example is also used to store the lambda authorizer source code.
  s3_bucket_key_base = "infrastructure/modules/integration/api/lambda-authorizer/examples/terraform/dydb-policy-store/access-token" # Base Path for S3 to store Terraform state and lambda authorizer source code. 
  s3_bucket_key = "${local.s3_bucket_key_base}/source-code/lambda-authz.zip" # Path for S3 to store lambda authorizer source code.
  # Standard Tags
  application_id   = "ace"
  application_name = "ace-infrastructure-blueprints"
  created_by_email = "enrique.bassallo@toyota.com"
}

provider "aws" {
  region = local.aws_region
}

terraform {
    backend "s3" {
      encrypt        = true
      bucket         = "ace-blueprint-usw2-test-terraform-state" # Local variable cannot be used
      key            = "infrastructure/modules/integration/api/lambda-authorizer/examples/terraform/dydb-policy-store/access-token/terraform.tfstate" # Local variable cannot be used
      region         = "us-west-2" # Local variable cannot be used
      dynamodb_table = "terraform-locks" # Local variable cannot be used
    }
}

module "lambda_authz" {
  # source = "../../../../../../..//integration/api/lambda-authorizer"
  source = "git::git@github.com:Toyota-Motor-North-America/ace-aws-infra-modules//integration/api/lambda-authorizer?ref=lambda-authorizer-v0.3.0-beta"
  aws_region = local.aws_region
  namespace = local.namespace
  dynamodb_config = {
    billing_mode = "PROVISIONED" # Controls how you are charged for read and write throughput and how you manage capacity. Possible values: PROVISIONED | PAY_PER_REQUEST
    read_capacity = 1 # The number of read units for this table. If the billing_mode is PROVISIONED, this field is required
    write_capacity = 1 # The number of write units for this table. If the billing_mode is PROVISIONED, this field is required
  }
  source_code_dest = {
    s3_bucket = local.s3_bucket_name # S3 Bucket in the target account where the Lambda Auuthorizer code will be copied
    s3_key = local.s3_bucket_key # S3 Bucket Key in the target account where the Lambda Auuthorizer code will be copied
  }
  # token_type = "access_token" # Use id_token if you will include app roles as claims in the JWT token, otherwise use access_token type
  roles_claim_name = "" # Use empty string when JWT tokens do not include app roles as claims, otherwise specifiy the name of the attribute in the token
  api_gateway_id = "si9uibvzci" # API Gateway was created separately from this example
  app_role_map_store = "dynamodb" # For access token type this value is irrelevant
  app_role_map = {} # For access token type this value is irrelevant
  tenant_id = "9107b728-2166-4e5d-8d13-d1ffdf0351ef" # Azure AD Tenant ID
  oidc_endpoint = "https://login.microsoftonline.com/9107b728-2166-4e5d-8d13-d1ffdf0351ef/v2.0/.well-known/openid-configuration" # Endpoint to retrieve public keys for Tenant ID
  cache_lifetime = 3600000 # Time in milliseconds to cache public keys in DynamoDB table
  authorizer_cache_ttl = 60 # Time in seconds to cache authorizations in API Gateway
  debug_mode = true # True to get more details in the execution of the Lambda Authorizer. False is recommendable for prod account

  # Standard Tags
  application_id   = local.application_id
  application_name = local.application_name
  created_by_email = local.created_by_email
  environment      = local.environment
}
