
# Output the VPC ID
output "vpc_id" {
  value = aws_vpc.non_prod_vpc.id
}

# Output the Public Subnet IDs
output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

