provider "aws" {
  region = "us-east-1"
  profile = "otsol-aws"
}

############################################################################
## Backend in S3 bucket to store Terraform State
## Please ensure to add 'bucket', 'region' and 'key' in backend.tfvars
############################################################################
terraform {
  required_version = ">= 0.11.13"
  backend "s3" {
    bucket = "vm-terraform-state"
    region = "us-east-1"
    key = "migration/iac/env-provision/terraform.tfstate"    
  }
}

############################################################################
## Parameters for VM Migration from Codero
############################################################################
locals {
  project = "vm"
  name = "migration"
  environment = "prod"
  tags = {
      customer = "mobileidea"
      provider = "otsol"
      project = "vm-migration"      
      environment = "prod"
  }
  #######################
  ## Below parameters cannot be grouped as a map because raise errors in versions prior 0.12
  #######################
  # vpc = {
  #   cidr = "10.10.0.0/16"
  #   database_subnets = []
  #   private_subnets = []
  #   public_subnets = ["10.10.0.0/20", "10.10.16.0/20"]
  #   azs = ["us-east-1a", "us-east-1b"]
  #   enable_dns_hostnames = true
  #   enable_dns_support = true
  #   enable_nat_gateway = false
  #   enable_s3_endpoint = true
  #   enable_dynamodb_endpoint = true
  #   enable_vpn_gateway = false
  # }
  # server_sg = {
  #   rdp_cidr_blocks = ["76.187.214.42/32", "181.66.206.124/32"]
  #   http_cidr_blocks = ["0.0.0.0/0"]
  #   https_cidr_blocks = ["0.0.0.0/0"]
  #   self_access = true
  #   all_egress = true
  # }
  # server_role = {
  #   service_url = "ec2.amazonaws.com"
  #   managed_policy_names = [
  #     "AmazonS3FullAccess",
  #     "CloudWatchLogsFullAccess"
  #   ]
  #   policy_arns = []
  # }
  # server = {
  #   key_name = "vm-migration-prod-key-pair"
  #   ami_id = "ami-00c97724903a0ef72" # Windows Server 2019 with SQL Express 2017 (May 2020)
  #   instance_type = "t3.micro" # t3a.large # r5.large
  #   # iam_profile = "vm-prod-role-vams-server"
  #   ebs_optimized = true
  #   associate_public_ip_address = true
  #   iam_profile = "${module.server_role.role_name}"
  #   disable_api_termination = true
  #   boot_volume = {
  #     volume_size = 50 # The size of the volume in gibibytes (GiB). Minimum 50 GB for selected AMI.
  #     delete_on_termination = false # True to destroy the volume on instance termination.
  #     encrypted = false # True to enable volume encryption.
  #     # kms_key_id = "" # Amazon Resource Name (ARN) of the KMS Key to use when encrypting the volume.
  #   }
  #   app_volume = {
  #     device_name = "/dev/sde"
  #     volume_type = "gp2" # The type of volume. Can be "standard", "gp2", "io1", "sc1", or "st1".
  #     volume_size = 20 # The size of the volume in gibibytes (GiB). Minimum 500 GiB for sc1 or st1.
  #     iops = 0 # The amount of provisioned IOPS. This is only valid for volume_type of "io1", and must be specified if using that type.
  #     # delete_on_termination = false # True to destroy the volume on instance termination.
  #     encrypted = false # True to enable volume encryption.
  #     # kms_key_id = "" # Amazon Resource Name (ARN) of the KMS Key to use when encrypting the volume.
  #     # snapshot_id = "" # A snapshot ID to base the EBS volume off of.
  #   }
  #   data_volume = {
  #     device_name = "/dev/sdd"
  #     volume_type = "sc1" # The type of volume. Can be "standard", "gp2", "io1", "sc1", or "st1".
  #     volume_size = 600 # The size of the volume in gibibytes (GiB). Minimum 500 GiB for sc1 or st1. 
  #     iops = 0 # The amount of provisioned IOPS. This is only valid for volume_type of "io1", and must be specified if using that type.
  #     # delete_on_termination = false # True to destroy the volume on instance termination.
  #     encrypted = false # True to enable volume encryption.
  #     # kms_key_id = "" # Amazon Resource Name (ARN) of the KMS Key to use when encrypting the volume.
  #     # snapshot_id = "" # A snapshot ID to base the EBS volume off of.
  #   }
  # }
}
############################################################################
## Module to create a VPC (Network)
############################################################################
module "vpc" {
  source = "git::https://git-codecommit.us-east-1.amazonaws.com/v1/repos/tf-aws-modules.git//vpc"
  create_vpc = true
  project = "${local.project}"
  name = "${local.name}"
  environment = "${local.environment}"
  cidr = "10.10.0.0/16"
  database_subnets = []
  private_subnets = []
  public_subnets = ["10.10.0.0/20", "10.10.16.0/20"]
  azs = ["us-east-1a", "us-east-1b"]
  enable_dns_hostnames = true
  enable_dns_support = true
  enable_nat_gateway = false
  enable_s3_endpoint = true
  enable_dynamodb_endpoint = true
  enable_vpn_gateway = false
  # cidr = "${local.vpc["cidr"]}"
  # database_subnets = "${local.vpc["database_subnets"]}"
  # private_subnets = "${local.vpc["private_subnets"]}"
  # public_subnets = "${local.vpc["public_subnets"]}"
  # azs = "${local.vpc["azs"]}"
  # enable_dns_hostnames = "${local.vpc["enable_dns_hostnames"]}"
  # enable_dns_support = "${local.vpc["enable_dns_support"]}"
  # enable_nat_gateway = "${local.vpc["enable_nat_gateway"]}"
  # enable_s3_endpoint = "${local.vpc["enable_s3_endpoint"]}"
  # enable_dynamodb_endpoint = "${local.vpc["enable_dynamodb_endpoint"]}"
  # enable_vpn_gateway = "${local.vpc["enable_vpn_gateway"]}"

  tags = "${local.tags}"
}

############################################################################
## Module to create a Security Group to work as a Firewall for the Server.
############################################################################
module "server_sg" {
  source = "git::https://git-codecommit.us-east-1.amazonaws.com/v1/repos/tf-aws-modules.git//security-group"
  vpc_id = "${module.vpc.vpc_id}"
  project = "${local.project}"
  name = "${local.name}"
  environment = "${local.environment}"
  description = "Security Group for Server which must allow access for RDP, HTTP and HTTPS protocols."
  rdp_cidr_blocks = ["76.187.214.42/32", "181.66.206.124/32", "64.150.181.231/32"]
  http_cidr_blocks = ["0.0.0.0/0"]
  https_cidr_blocks = ["0.0.0.0/0"]
  self_access = true
  all_egress = true
  # rdp_cidr_blocks = ["${local.server_sg["rdp_cidr_blocks"]}"]
  # http_cidr_blocks = ["${local.server_sg["http_cidr_blocks"]}"]
  # https_cidr_blocks = "[${local.server_sg["https_cidr_blocks"]}]"
  # self_access = "${local.server_sg["self_access"]}"
  # all_egress = "${local.server_sg["all_egress"]}"

  tags = "${local.tags}"
}

############################################################################
## Module to create an IAM Role to allow access to other AWS resources from server.
############################################################################
module "server_role" {
  source = "git::https://git-codecommit.us-east-1.amazonaws.com/v1/repos/tf-aws-modules.git//service-role"
  project = "${local.project}"
  name = "${local.name}"
  environment = "${local.environment}"
  description = "IAM Role for Server to allow access to other resources in AWS."
  service_url = "ec2.amazonaws.com"
  managed_policy_names = [
    "AmazonS3FullAccess",
    "CloudWatchLogsFullAccess"
  ]
  policy_arns = []
  # service_url = "${local.server_role["service_url"]}"
  # managed_policy_names = "${local.server_role["managed_policy_names"]}"
  # policy_arns = "${local.server_role["policy_arns"]}"

  tags = "${local.tags}"
}

############################################################################
## Module to deploy an EC2 instance as a new Server for Via Movil apps.
############################################################################
module "server" {
  source = "git::https://git-codecommit.us-east-1.amazonaws.com/v1/repos/tf-aws-modules.git//ec2-windows"
  project = "${local.project}"
  name = "${local.name}"
  environment = "${local.environment}"
  subnet_id = "${element(module.vpc.public_subnets, 1)}"
  security_group_ids = "${list(module.server_sg.security_group_id)}"
  iam_profile = "${module.server_role.role_name}"

  key_name = "vm-migration-prod-key-pair"
  ami_id = "ami-00c97724903a0ef72" # Windows Server 2019 with SQL Express 2017 (May 2020)
  instance_type = "t3a.large" # t3.micro # t3.large # r5.large
  ebs_optimized = true
  associate_public_ip_address = true
  disable_api_termination = true
  credit_specification = {
    cpu_credits = "standard"
  }
  boot_volume = {
    volume_size = 50 # The size of the volume in gibibytes (GiB). Minimum 50 GB for selected AMI.
    delete_on_termination = false # True to destroy the volume on instance termination.
    encrypted = false # True to enable volume encryption.
    # kms_key_id = "" # Amazon Resource Name (ARN) of the KMS Key to use when encrypting the volume.
  }
  app_volume = {
    create_volume = false
    device_name = "/dev/sde"
    volume_type = "gp2" # The type of volume. Can be "standard", "gp2", "io1", "sc1", or "st1".
    volume_size = 20 # The size of the volume in gibibytes (GiB). Minimum 500 GiB for sc1 or st1.
    iops = 0 # The amount of provisioned IOPS. This is only valid for volume_type of "io1", and must be specified if using that type.
    # delete_on_termination = false # True to destroy the volume on instance termination.
    encrypted = false # True to enable volume encryption.
    # kms_key_id = "" # Amazon Resource Name (ARN) of the KMS Key to use when encrypting the volume.
    # snapshot_id = "" # A snapshot ID to base the EBS volume off of.
  }
  data_volume = {
    create_volume = true
    device_name = "/dev/sdd"
    volume_type = "sc1" # The type of volume. Can be "standard", "gp2", "io1", "sc1", or "st1".
    volume_size = 500 # The size of the volume in gibibytes (GiB). Minimum 500 GiB for sc1 or st1. 
    iops = 0 # The amount of provisioned IOPS. This is only valid for volume_type of "io1", and must be specified if using that type.
    # delete_on_termination = false # True to destroy the volume on instance termination.
    encrypted = false # True to enable volume encryption.
    # kms_key_id = "" # Amazon Resource Name (ARN) of the KMS Key to use when encrypting the volume.
    # snapshot_id = "" # A snapshot ID to base the EBS volume off of.
  }

  # key_name = "${local.server["key_name"]}"
  # ami_id = "${local.server["ami_id"]}"
  # instance_type = "${local.server["instance_type"]}"
  # ebs_optimized = "${local.server["ebs_optimized"]}"
  # associate_public_ip_address = "${local.server["associate_public_ip_address"]}"
  # disable_api_termination = "${local.server["disable_api_termination"]}"
  # boot_volume = "${local.server["boot_volume"]}"
  # app_volume = "${local.server["app_volume"]}"
  # data_volume = "${local.server["data_volume"]}"

  tags = "${local.tags}"
}
