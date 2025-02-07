locals {
  cluster_name   = "some-cool-cluster"
  vpn_cidr_block = "10.10.10.0/24"
  tags = {
    "environment" = var.environment
  }
}
