variable "bucket_name" {
  type        = string
  description = "Name of S3 bucket"
  validation {
    condition     = var.bucket_name != null && ! can(regex("^(-)", var.bucket_name)) && ! can(regex("(-)$", var.bucket_name)) && can(regex("^[a-z0-9-]{3,63}$", var.bucket_name))
    error_message = "Argument 'bucket_name' must contain only lower-case letters and numeric characters or hyphens, must not begin or end with a hyphen, must not contain periods and can't be empty.  Length of value should be between 3 and 63 characters long."
  }
}

variable "policy" {
  type        = string
  default     = null
  description = "A valid bucket policy JSON document. Note that if the policy document is not specific enough (but still valid), Terraform may view the policy as constantly changing in a terraform plan. In this case, please make sure you use the verbose/specific version of the policy"
}

variable "logging" {
  type = object({
    bucket_name = string
    prefix      = string
  })
  description = "Bucket access logging configuration."
}

variable "force_destroy" {
  description = "Force destroy S3 buckets"
  type        = bool
}

/*
 Encryption
*/
variable "sse_algorithm" {
  type        = string
  default     = "AES256"
  description = "The server-side encryption algorithm to use. Valid values are `AES256` and `aws:kms`"
  validation {
    condition     = var.sse_algorithm != null && contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "Argument 'sse_algorithm' must be either 'AES256' or 'aws:kms'."
  }
}

/*
  CloudFront configuration
*/
variable "index_document" {
  description = "The path that you want CloudFront to query on the origin server when an end user requests the root URL (e.g. index.html)."
  type        = string
  default     = "index.html"
}

variable "route53_zone_name" {
  description = "DNS zone name"
  type        = string
  validation {
    condition     = var.route53_zone_name != null && can(regex("^[A-Za-z0-9-.]{1,64}.(cloud.toyota.com|toyota.com|4poc.net)$", var.route53_zone_name))
    error_message = "Argument 'route53_zone_name' must be existing zone in route53, must contain alphanumeric characters, hyphens, dots and can't be empty."
  }
}

/*
  SSL configuration
*/

variable "fqdn" {
  description = "Fully Qualified Domain Name for application"
  type        = string
  default     = null
  validation {
    condition     = var.fqdn != null && can(regex("^[A-Za-z0-9-.]{1,64}.[A-Za-z0-9-.]{1,64}.(cloud.toyota.com|toyota.com|4poc.net)$", var.fqdn))
    error_message = "Argument 'fqdn' must be existing zone in route53, must contain alphanumeric characters, hyphens, dots and can't be empty."
  }
}

/*
 Tags configuration
*/
variable "application_id" {
  type        = string
  description = "Application ID as per CMDB"
}

variable "application_name" {
  type        = string
  description = "Name of Application as per CMDB"
}

variable "environment" {
  type        = string
  description = "Environment abbreviation of resource."
  validation {
    condition     = contains(["poc", "dev", "qa", "sit", "prf", "uat", "prd", "dr"], var.environment)
    error_message = "Argument 'environment' must be either 'poc', 'dev', 'qa', 'sit', 'prf', 'uat', 'prd' or 'dr'."
  }
}

variable "created_by_email" {
  type        = string
  description = "Toyota email of the person who creates resource."
}


# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables must be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

/*
  S3 bucket configuration
*/
variable "cors_rule_inputs" {
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default     = null
  description = "Specifies the allowed headers, methods, origins and exposed headers when using CORS on this bucket"
}

variable "s3_logs_lifecycle_rules" {
  description = "A list of lifecycle rules"
  type = list(object({
    prefix  = string
    enabled = bool
    tags    = map(string)

    enable_glacier_transition        = bool
    enable_deeparchive_transition    = bool
    enable_standard_ia_transition    = bool
    enable_current_object_expiration = bool

    abort_incomplete_multipart_upload_days         = number
    noncurrent_version_glacier_transition_days     = number
    noncurrent_version_deeparchive_transition_days = number
    noncurrent_version_expiration_days             = number

    standard_transition_days    = number
    glacier_transition_days     = number
    deeparchive_transition_days = number
    expiration_days             = number
  }))
  default = [{
    enabled = true
    prefix  = ""
    tags    = {}

    enable_glacier_transition        = false
    enable_deeparchive_transition    = false
    enable_standard_ia_transition    = false
    enable_current_object_expiration = true

    abort_incomplete_multipart_upload_days         = 90
    noncurrent_version_glacier_transition_days     = 30
    noncurrent_version_deeparchive_transition_days = 60
    noncurrent_version_expiration_days             = 90

    standard_transition_days    = 30
    glacier_transition_days     = 45
    deeparchive_transition_days = 90
    expiration_days             = 60
  }]
}

/*
  CloudFront configuration
*/
variable "web_acl_id" {
  description = "If you're using AWS WAF to filter CloudFront requests, the Id of the AWS WAF web ACL that is associated with the distribution."
  type        = string
  default     = null
}

variable "default_ttl" {
  description = "The default amount of time, in seconds, that an object is in a CloudFront cache before CloudFront forwards another request in the absence of an 'Cache-Control max-age' or 'Expires' header."
  type        = number
  default     = 60
}

variable "max_ttl" {
  description = "The maximum amount of time, in seconds, that an object is in a CloudFront cache before CloudFront forwards another request to your origin to determine whether the object has been updated. Only effective in the presence of 'Cache-Control max-age', 'Cache-Control s-maxage', and 'Expires' headers."
  type        = number
  default     = 90
}

variable "min_ttl" {
  description = "The minimum amount of time that you want objects to stay in CloudFront caches before CloudFront queries your origin to see whether the object has been updated."
  type        = number
  default     = 30
}

variable "forward_cookies" {
  description = "Specifies whether you want CloudFront to forward cookies to the origin that is associated with this cache behavior. You can specify all, none or whitelist. If whitelist, you must define var.whitelisted_cookie_names."
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "all", "whitelist"], var.forward_cookies)
    error_message = "Argument 'forward_cookies' must be either 'none', 'all', 'whitelist'."
  }
}

variable "forward_headers" {
  description = "The headers you want CloudFront to forward to the origin."
  type        = list(string)
  default     = []
}

variable "whitelisted_cookie_names" {
  description = "If you have specified whitelist in var.forward_cookies, the whitelisted cookies that you want CloudFront to forward to your origin."
  type        = list(string)
  default     = []
}

/*
  Logs configuration
*/

variable "access_logs_expiration_time_in_days" {
  description = "How many days to keep access logs around for before deleting them."
  type        = number
  default     = 60
}

variable "access_log_prefix" {
  description = "The folder in the access logs bucket where logs should be written."
  type        = string
  default     = null
}

variable "access_logs_bucket_suffix" {
  description = "The suffix for the access logs bucket where logs should be written."
  type        = string
  default     = "cloudfront-logs"
}

variable "force_destroy_access_logs_bucket" {
  description = "If set to true, this will force the delete of the access logs S3 bucket when you run terraform destroy, even if there is still content in it. This is only meant for testing and should not be used in production."
  type        = bool
  default     = false
}
