variable "aws_region" {
  description = "The AWS region to build in"
  default     = "ap-south-1"  # Mumbai Region
}

variable "vpc_cidr" {
  description = "The IP address range for the VPC"
  default     = "10.0.0.0/16"
}