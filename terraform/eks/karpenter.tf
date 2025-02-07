module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.33.1"

  cluster_name = local.cluster_name
  queue_name   = "${local.cluster_name}-karpenter"

  namespace = "karpenter"

  create_node_iam_role            = false
  node_iam_role_arn               = module.eks.eks_managed_node_groups["core-services"].iam_role_arn
  create_access_entry             = false # Since the node group role will already have an access entry
  enable_pod_identity             = true
  create_pod_identity_association = true
  enable_v1_permissions           = true

  tags = local.tags
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.2.1"

  set {
    name  = "settings.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.interruptionQueueName"
    value = module.karpenter.queue_name
  }

  set {
    name  = "replicas"
    value = "1"
  }

  set {
    name  = "nodeSelector.karpenter\\.sh/controller"
    value = "enabled"
  }

  set {
    name  = "tolerations[0].key"
    value = "karpenter.sh/controller"
  }

  set {
    name  = "tolerations[0].operator"
    value = "Exists"
  }

  set {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }
}

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: 100Gi
            volumeType: gp3
            encrypted: true
      amiFamily: AL2023
      amiSelectorTerms:
        - name: "amazon-eks-node-al2023*"
      role: ${module.eks.eks_managed_node_groups["core-services"].iam_role_arn}
      subnetSelectorTerms:
        - tags:
            Tier: ${var.subnet_tier}
      securityGroupSelectorTerms:
        - tags:
            Name: ${local.cluster_name}-node
      tags:
        karpenter.sh/discovery: karpenter
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["c", "m", "r"]
            - key: "karpenter.k8s.aws/instance-cpu"
              operator: In
              values: ["4", "8", "16"]
            - key: "karpenter.k8s.aws/instance-hypervisor"
              operator: In
              values: ["nitro"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["5"]
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ["spot", "on-demand"]
            - key: "kubernetes.io/arch"
              operator: In
              values: ["amd64", "arm64"]
      limits:
        cpu: 20
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
  YAML

  depends_on = [
    helm_release.karpenter,
    kubectl_manifest.karpenter_node_class
  ]
}
