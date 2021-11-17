terraform {
  required_version = ">= 0.13.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.6.0"
    }
  }
}

provider "aws" {
  # The AWS region in which SSL certificate will be created
  region = "us-east-1"
  alias  = "ssl_cert"
}

module "ssl_certificate" {
  source = "git@github.com:Toyota-Motor-North-America/ace-aws-infra-modules.git//security/encryption/ssl-certificate?ref=security-encryption-v2.1.0"

  providers = {
    aws = aws.ssl_cert
  }

  route53_zone_name = var.route53_zone_name
  fqdn              = var.fqdn

  application_id   = var.application_id
  application_name = var.application_name
  environment      = var.environment
  created_by_email = var.created_by_email
}

module "s3" {
  source = "git@github.com:Toyota-Motor-North-America/ace-aws-infra-modules.git//storage/s3/bucket?ref=storage-s3-v1.3.2"

  depends_on = [module.s3_logs]

  bucket_name      = var.bucket_name
  logging          = var.logging
  policy           = var.policy
  cors_rule_inputs = var.cors_rule_inputs
  force_destroy    = var.force_destroy

  application_id   = var.application_id
  application_name = var.application_name
  environment      = var.environment
  created_by_email = var.created_by_email
}

module "s3_logs" {
  source = "git@github.com:Toyota-Motor-North-America/ace-aws-infra-modules.git//storage/s3/bucket?ref=storage-s3-v1.3.2"

  bucket_name     = var.logging.bucket_name
  acl             = "log-delivery-write"
  lifecycle_rules = var.s3_logs_lifecycle_rules
  logging         = null
  force_destroy   = var.force_destroy

  application_id   = var.application_id
  application_name = var.application_name
  environment      = var.environment
  created_by_email = var.created_by_email
}

module "cloudfront" {
  source = "git@github.com:Toyota-Motor-North-America/ace-aws-infra-modules.git//networking/cdn/cloudfront-s3?ref=networking-cdn-v1.4.1"

  depends_on = [module.s3]

  bucket_name                         = var.bucket_name
  acm_certificate_arn                 = module.ssl_certificate.aws_acm_certificate_arn
  route53_zone_name                   = var.route53_zone_name
  domain_names                        = [var.fqdn]
  index_document                      = var.index_document
  default_ttl                         = var.default_ttl
  max_ttl                             = var.max_ttl
  min_ttl                             = var.min_ttl
  web_acl_id                          = var.web_acl_id
  forward_cookies                     = var.forward_cookies
  forward_headers                     = var.forward_headers
  whitelisted_cookie_names            = var.whitelisted_cookie_names
  access_log_prefix                   = var.access_log_prefix
  access_logs_bucket_suffix           = var.access_logs_bucket_suffix
  access_logs_expiration_time_in_days = var.access_logs_expiration_time_in_days
  force_destroy_access_logs_bucket    = var.force_destroy_access_logs_bucket
  # Mandatory tags
  application_id   = var.application_id
  application_name = var.application_name
  environment      = var.environment
  created_by_email = var.created_by_email
}
