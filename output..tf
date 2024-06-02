
# Output the VPC ID
output "vpc_id" {
  value = aws_vpc.non_prod_vpc.id
}

# Output the Public Subnet IDs
output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}
output "cluster_name" {
  value = aws_eks_cluster.qa_eks.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.qa_eks.endpoint
}

output "cluster_arn" {
  value = aws_eks_cluster.qa_eks.arn
}

output "node_group_name" {
  value = aws_eks_node_group.qa_eks_nodes.node_group_name
}

output "namespace" {
  value = kubernetes_namespace.app_ns.metadata[0].name
}


