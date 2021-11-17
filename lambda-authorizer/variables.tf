# ----------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator when calling this
# terraform module.
# ----------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS Region where the lambda authorizer will be deployed."
  type        = string
  default     = "us-west-2"
}

variable "namespace" {
  description = "Prefix to be used in all the resources of this blueprint. Try to follow a naming convention like {app-name}-{environment} (e.g. 'ace-dev', 'esl-prod', etc.)"
  type        = string
  default     = "example-poc"
}

variable "environment" {
  type        = string
  description = "Environment abbreviation of resource."
  default     = "poc"
  validation {
    condition     = contains(["poc", "dev", "qa", "sit", "prf", "uat", "prd", "dr"], var.environment)
    error_message = "Argument 'environment' must be either 'poc', 'dev', 'qa', 'sit', 'prf', 'uat', 'prd' or 'dr'."
  }
}

variable "dynamodb_config" {
  description = "Configuration values for the dynamodb table to be created for Lambda Authorizer"
  type = any
  default = {
    billing_mode = "PROVISIONED" # Controls how you are charged for read and write throughput and how you manage capacity. Possible values: PROVISIONED | PAY_PER_REQUEST
    read_capacity = 1 # The number of read units for this table. If the billing_mode is PROVISIONED, this field is required
    write_capacity = 1 # The number of write units for this table. If the billing_mode is PROVISIONED, this field is required
  }
}

variable "source_code_dest" {
  description = "S3 bucket destination to copy source code of Lambda Authorizer. S3 bucket must be in the same region where Lambda Authorizer will be deployed"
  type = any
  # example = {
  #   s3_bucket = "ace-blueprint-usw2-test-terraform-state"
  #   s3_key = "infrastructure/modules/integration/api/lambda-authorizer/test/dydb/source-code/lambda-authz.zip"
  # }
}

variable "api_gateway_id" {
  description = "ID of the API Gateway that the Lambda will authorize to consume API endpoints"
  type        = string
}

variable "app_role_map_store" {
  description = "Define where the app role map will be stored ['iam' | 'dynamodb']. By default it is 'dynamodb'. IAM option is more secure but slower than DynamoDB. IAM option adds aprox 1 second to time response while DynamoDB option just 100ms."
  type        = string
  default     = "dynamodb"
  validation {
    condition     = contains(["iam", "dynamodb"], var.app_role_map_store)
    error_message = "Argument 'app_role_map_store' must be either 'iam' or 'dynamodb'. By default it is 'dynamodb'."
  }
}

variable "app_role_map" {
  description = "Map for app roles registered in Azure AD to access to your API endpoints. Every role name must be the map key and a list of permissions must be the map value. Every permission defines the effect [Allow | Deny], http_method (accepts *) and resource_path (accepts * at any resource level e.g. */*/*)"
  type        = map(any)
  # example = {
  #   ACE_ADMIN = [{
  #     effect = "Allow"
  #     http_method = "*"
  #     resource_path = "*"
  #   }]
  #   ACE_RO = [{
  #     effect = "Deny"
  #     http_method = "*"
  #     resource_path = "admin/*"
  #   },{
  #     effect = "Allow"
  #     http_method = "GET"
  #     resource_path = "*"
  #   }]
  #   ACE_RW = [{
  #     effect = "Deny"
  #     http_method = "*"
  #     resource_path = "admin/*"
  #   },{
  #     effect = "Allow"
  #     http_method = "*"
  #     resource_path = "*"
  #   }]
  # }
}

variable "lambda_version" {
  description = "Version available for Lambda Authorizer app code. By default it is '0.3.2'."
  type        = string
  default     = "0.3.2"
}

variable "lambda_memory_size" {
  description = "Define memory size allocated to the Lambda Authorizer. Any value in this variable will override a value in lambda_memory_t_shirt variable. To change this value, we recommend a proper Profiling for your function."
  type        = number
  default     = null
}

variable "lambda_memory_t_shirt" {
  description = "Define memory size allocated to the Lambda Authorizer. Ignored if lambda_memory_size is different tan 'null'. By default it is 'L' (512mb). Possible values: 'S' (128mb), 'M' (256mb), 'L' (512mb), 'XL' (1024mb). To change this value, we recommend a proper Profiling for your function."
  type        = string
  default     = "L"
  validation {
    condition     = contains(["S", "M", "L", "XL"], var.lambda_memory_t_shirt)
    error_message = "Argument 'lambda_memory_t_shirt' must be either 'S', 'M', 'L' or 'XL'. By default it is 'L'."
  }
}

# variable "token_type" {
#   description = "Token type to be evaluated. Possible values: 'id_token' | 'access_token'. By default it is 'id_token'"
#   type        = string
#   default     = "id_token"
#   validation {
#     condition     = contains(["id_token", "access_token"], var.token_type)
#     error_message = "Argument 'token_type' must be either 'id_token' or 'access_token'. By default it is 'id_token'."
#   }
# }

variable "roles_claim_name" {
  description = "Claim name in JWT token to refer to the Azure AD app roles."
  type        = string
  default     = "roles"
}

variable "token_http_header" {
  description = "HTTP Header Name where the token will be sent to the request."
  type        = string
  default     = "authorizationToken"
}

variable "authorizer_cache_ttl" {
  description = "The TTL of cached authorizer results in seconds. Defaults to 60"
  type        = number
  default     = 60
}

variable "tenant_id" {
  description = "Auth Tenant ID."
  type        = string
  default     = "9107b728-2166-4e5d-8d13-d1ffdf0351ef"
  # prod = "8c642d1d-d709-47b0-ab10-080af10798fb"
}

variable "oidc_endpoint" {
  description = "Auth Open ID Configuration Endpoint."
  type        = string
  default     = "https://login.microsoftonline.com/9107b728-2166-4e5d-8d13-d1ffdf0351ef/v2.0/.well-known/openid-configuration"
  # prod = "https://login.microsoftonline.com/8c642d1d-d709-47b0-ab10-080af10798fb/v2.0/.well-known/openid-configuration"
}

variable "cache_lifetime" {
  description = "Period of time (in milliseconds) to cache data in DynamoDB Table."
  type        = number
  default     = 3600000
}

variable "debug_mode" {
  description = "To store logs in CloudWatch for debugging purposes."
  type        = bool
  default     = true
}


variable "application_id" {
  type        = string
  description = "Application ID as per CMDB"
}

variable "application_name" {
  type        = string
  description = "Name of Application as per CMDB"
}

variable "created_by_email" {
  type        = string
  description = "Toyota email of the person who creates resource."
}
