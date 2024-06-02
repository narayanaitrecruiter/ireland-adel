#variables for vpc.tf

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "availability_zones" {
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "vpc_name" {
  default = "non-prod"
}


variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "qa-eks"
}

variable "node_instance_type" {
  description = "EC2 instance type for the EKS nodes"
  type        = string
  default     = "m5.large"
}

variable "desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 15
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "namespace" {
  description = "Namespace to be created in the EKS cluster"
  type        = string
  default     = "app-ns"
}

variable "aurorapassword" {
  description = "Password for the Aurora database"
  type        = string
  default = "admin"
}

variable "aurorausername" {
  description = "Username for the Aurora database"
  type        = string
  default = "aurorapassword"
}

variable "postgresusername" {
  description = "Password for the Aurora database"
  type        = string
  default = "admin"
}

variable "postgrespassword" {
  description = "Username for the Aurora database"
  type        = string
  default = "postgrespassword"
}

variable "mysqlusername" {
  description = "Password for the Aurora database"
  type        = string
  default = "admin"
}

variable "mysqlpassword" {
  description = "Username for the Aurora database"
  type        = string
  default = "mysqlpassword"
}

variable "region" {
  description = "The AWS region"
  type        = string
  default     = "eu-west-1"
}