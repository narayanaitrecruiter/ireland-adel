resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.cluster_name}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_instance_profile" "eks_node_group_instance_profile" {
  name = "${var.cluster_name}-eks-node-group-instance-profile"
  role = aws_iam_role.eks_node_group_role.name
}



resource "aws_eks_cluster" "qa_eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "latest"

  vpc_config {
    subnet_ids = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy
  ]
}




resource "aws_eks_node_group" "qa_eks_nodes" {
  cluster_name    = aws_eks_cluster.qa_eks.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_size
    min_size     = var.min_size
  }

  instance_types = [var.node_instance_type]

  remote_access {
    ec2_ssh_key = "my-key"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy
  ]
}




provider "kubernetes" {
  host                   = aws_eks_cluster.qa_eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.qa_eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.qa_eks.token
}

data "aws_eks_cluster_auth" "qa_eks" {
  name = aws_eks_cluster.qa_eks.name
}

resource "kubernetes_namespace" "app_ns" {
  metadata {
    name = var.namespace
  }

  depends_on = [aws_eks_node_group.qa_eks_nodes]
}



resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.cluster_name}-eks-nodes-"
  vpc_id      = aws_vpc.non_prod_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-eks-nodes"
  }
}