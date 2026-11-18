# 1. Create the VPC (Your Private Network)
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "enterprise-vpc"
  }
}

# 2. Create the Internet Gateway (The cable to the outside world)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "enterprise-igw"
  }
}

# 3. Create a Public Subnet (Where your Load Balancer will live)
resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}b"

  tags = {
    Name = "enterprise-public-subnet-a"
  }
}

# 4. Route Table (Tells traffic how to find the Internet Gateway)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# 5. Link the Subnet to the Route Table
resource "aws_route_table_association" "public_assoc_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}