output "hostname" {
  value = module.cloudfront.cloudfront_domain_names
}

output "bucket_fqdn" {
  value = module.s3.bucket_domain_name
}

output "bucket_for_s3_logs" {
  value = module.s3_logs.bucket_domain_name
}

output "cloudfront_id" {
  value = module.cloudfront.cloudfront_id
}
