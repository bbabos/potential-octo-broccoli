terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket         = "120569599589-terraform-state-bucket-eu-west-1"
    dynamodb_table = "120569599589-terraform-state-lock-eu-west-1"
    key            = "eks/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.85.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }
  }
}
