# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create a Lambda function to validate and authorize JWT tokens
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Copy source code of Lambda Authorizer to a S3 destination
resource "null_resource" "copy_signed_artifact" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOF
echo "AWS_PROFILE=$AWS_PROFILE"
echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
aws s3 cp s3://${local.function_source_code["s3_bucket"]}/${local.function_source_code["s3_key"]} s3://${var.source_code_dest["s3_bucket"]}/${var.source_code_dest["s3_key"]} --acl "bucket-owner-full-control"
echo "s3://${var.source_code_dest["s3_bucket"]}/${var.source_code_dest["s3_key"]}"
EOF
    environment = {
        # automatically includes AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
    }
  }

  # Change in artifact version will trigger the provisioner
  triggers = {
    timestamp = local.timestamp
  }
}

resource "aws_lambda_code_signing_config" "lambda_csc" {
  allowed_publishers {
    # signing_profile_version_arns = local.signing_profile_version_arns
    # IMPORTANT - value have to be assigned directly to the attribute to avoid issues in Jenkins 
    signing_profile_version_arns = [
      "arn:aws:signer:us-west-2:873364552094:/signing-profiles/ace_lambda_signing_profile/AL3lFpzTfW"
    ]
  }

  policies {
    # untrusted_artifact_on_deployment = local.code_signing_config_policy
    # IMPORTANT - value have to be assigned directly to the attribute to avoid issues in Jenkins 
    untrusted_artifact_on_deployment = "Enforce"
  }

  description = local.code_signing_config_description
}

data "aws_s3_bucket_object" "lambda_artifact" {
  depends_on = [null_resource.copy_signed_artifact]
  bucket = var.source_code_dest["s3_bucket"]
  key    = var.source_code_dest["s3_key"]
}

resource "aws_lambda_function" "lambda_authz" {
  function_name = local.function_name
  description = local.function_config["description"]
  role = module.lambda_authz_exec_role.role_arn

  s3_bucket = data.aws_s3_bucket_object.lambda_artifact.bucket
  s3_key = data.aws_s3_bucket_object.lambda_artifact.key
  s3_object_version = data.aws_s3_bucket_object.lambda_artifact.version_id

  runtime = local.function_config["runtime"]
  handler = local.function_config["handler"]
  memory_size = local.function_config["memory_size"]
  reserved_concurrent_executions = local.function_config["reserved_concurrent_executions"]
  timeout = local.function_config["timeout"]
  code_signing_config_arn = aws_lambda_code_signing_config.lambda_csc.arn

  environment {
    variables = {
      FN_CONFIG = local.env_vars_base64
      DEBUG_MODE = var.debug_mode
    }
  }

  tags = module.standard_tags.standard-tags
}
