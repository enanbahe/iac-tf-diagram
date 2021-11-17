# API Infrastructure Blueprint: lambda-authorizer module

This module allows to create a Lambda Authorizer to be associated with API Gateway for validating JWT tokens and authorize the use of API endpoints.

## Pre-requisites

- Application needs to be onboarded in the Toyota DevOps Platform (TDP).
- To use the deployTerraform pipeline in TDP you will need to register an AWS access key with permissions to deploy resources in the target account.
- IAM users are restricted to be created in your AWS account, but you can request it through 1TS ticket to https://tmna.service-now.com/1ts?id=1ts_cat_item&sys_id=bfa60e15db475050df739d4b8a96191d


## How do you use this module?
Check out the [examples folder](./examples) with some examples using Terragrunt or Terraform.

We recommend to use Terragrunt if you will consume this blueprint separately of others, otherwise you can combine it along with others resources in a Terraform module.

Please be careful with the values used in the examples as they are referencing to Advanced Cloud Engineering (ACE) resources for demonstrations only, so that you should change them accordingly based on your application/environment requirements.

Keep in mind that you will not be able to consume this blueprint from your local machine, you will need to use the deployTerraform pipeline in TDP.
