


# Create the Redis server
resource "aws_elasticache_cluster" "redis_server" {
  cluster_id           = "redis-server"
  engine               = "redis"
  node_type           = "cache.t3.micro"
  num_cache_nodes     = 1
  parameter_group_name = "default.redis6.x"
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name

  tags = {
    Name = "Redis Server"
  }
}

# Create the Redis Subnet Group
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]
}
# Create the CloudWatch Log Group
resource "aws_cloudwatch_log_group" "redis_log_group" {
  name              = "aws/redis-server"
  retention_in_days = 7
  tags = {
        Environment = "QA"
        Project     = "qa-redis-server"
    }
}