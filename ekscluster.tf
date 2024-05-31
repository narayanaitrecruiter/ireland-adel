

# data "aws_ami" "eks_worker" {
#   filter {
#     name   = "name"
#     values = ["amazon-eks-node-1.21-v*"]
#   }

#   most_recent = true
#   owners      = ["111111111111"] # Amazon EKS AMI account ID
# }

# Create IAM role for EKS
resource "aws_iam_role" "eks" {
  name = "eks"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create EKS Cluster
resource "aws_eks_cluster" "qa_eks" {
  name     = "qa-eks"
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    subnet_ids = [aws_subnet.public_subnets[0].id] # Replace with your subnet IDs
  }
  
  tags = {
    Environment = "qa"
    Name        = "qa-eks"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_policy
  ]
}

# Create IAM role for Node Group
resource "aws_iam_role" "node" {
  name = "node"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Create EKS Node Group
resource "aws_eks_node_group" "qa_node_group" {
  cluster_name    = aws_eks_cluster.qa_eks.name
  node_group_name = "qa-node-group"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = [aws_subnet.public_subnets[0].id] # Replace with your subnet IDs

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 15
  }

  instance_types = ["m5.large"]

  depends_on = [
    aws_iam_role_policy_attachment.node_policy
  ]
}