module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  cluster_name = local.cluster_name

  cluster_version                = "1.32"
  cluster_endpoint_public_access = false
  cluster_addons = {
    eks-pod-identity-agent = {
      addon_version     = "v1.3.4-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    coredns = {
      addon_version     = "v1.11.4-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
      configuration_values = jsonencode({
        tolerations = [
          {
            key    = "karpenter.sh/controller"
            value  = "enabled"
            effect = "NoSchedule"
          }
        ]
      })
    }
    kube-proxy = {
      addon_version     = "v1.32.0-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      addon_version     = "v1.19.2-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      addon_version     = "v1.39.0-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    metrics-server = {
      addon_version     = "v0.7.2-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
  }

  vpc_id     = data.aws_vpc.main.id
  subnet_ids = data.aws_subnets.eks.ids

  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 50
          volume_type           = "gp3"
          encrypted             = true
          delete_on_termination = true
        }
      }
    }
    iam_role_additional_policies = {
      AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }
  }
  eks_managed_node_groups = {
    core-services = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]
      labels = {
        workload = "core-services"
      }
    },
    karpenter = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]
      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "enabled"
      }
      taints = {
        # The pods that do not tolerate this taint should run on nodes
        # Created by Karpenter
        karpenter = {
          key    = "karpenter.sh/controller"
          value  = "enabled"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  enable_irsa = true
  access_entries = {
    admin = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::${var.account_id}:role/aws-reserved/sso.amazonaws.com/${var.region}/${var.sso_admin_role_name}"
      policy_associations = {
        read_write = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    # readonly = {
    #   kubernetes_groups = []
    #   principal_arn     = "some-readonly-role-arn"
    #   policy_associations = {
    #     read_only = {
    #       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
    #       access_scope = {
    #         type       = "namespace"
    #         namespaces = ["some-namespace"]
    #       }
    #     }
    #   }
    # }
  }

  cluster_security_group_name = "${local.cluster_name}-eks"
  cluster_security_group_additional_rules = {
    vpn = {
      description = "Rule allowing access from VPN"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [local.vpn_cidr_block]
    }
  }
  node_security_group_name = "${local.cluster_name}-node"
  node_security_group_additional_rules = {
    ingress_vpc_high_ports = {
      description = "Allow access to high ports from within the VPC"
      protocol    = "tcp"
      from_port   = 1024
      to_port     = 65535
      type        = "ingress"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
    }
  }

  tags = local.tags
}
