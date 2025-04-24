
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name        = "${var.cluster_name}-vpc-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

##########################################
# Internet Gateway
##########################################
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = "${var.cluster_name}-igw-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

##########################################
# Public Subnets
##########################################
resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name                        = "${var.cluster_name}-public-subnet1-${var.env}"
      Environment                 = var.env
      "kubernetes.io/role/elb"   = "1"
    },
    var.tags
  )
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name                        = "${var.cluster_name}-public-subnet2-${var.env}"
      Environment                 = var.env
      "kubernetes.io/role/elb"   = "1"
    },
    var.tags
  )
}

##########################################
# Private Subnets for Applications
##########################################
resource "aws_subnet" "private_app_subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[0]
  availability_zone = var.availability_zones[0]

  tags = merge(
    {
      Name                                          = "${var.cluster_name}-private-subnet1-app-${var.env}"
      Environment                                   = var.env
      "kubernetes.io/cluster/${var.cluster_name}"   = "shared"
      "kubernetes.io/role/internal-elb"             = "1"
    },
    var.tags
  )
}

resource "aws_subnet" "private_app_subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[1]
  availability_zone = var.availability_zones[1]

  tags = merge(
    {
      Name                                          = "${var.cluster_name}-private-subnet2-app-${var.env}"
      Environment                                   = var.env
      "kubernetes.io/cluster/${var.cluster_name}"   = "shared"
      "kubernetes.io/role/internal-elb"             = "1"
    },
    var.tags
  )
}

##########################################
# Private Subnets for Data
##########################################
resource "aws_subnet" "private_data_subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_data_subnet_cidrs[0]
  availability_zone = var.availability_zones[0]

  tags = merge(
    {
      Name        = "${var.cluster_name}-private-subnet1-data-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

resource "aws_subnet" "private_data_subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_data_subnet_cidrs[1]
  availability_zone = var.availability_zones[1]

  tags = merge(
    {
      Name        = "${var.cluster_name}-private-subnet2-data-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

##########################################
# Elastic IPs for NAT Gateway
##########################################
resource "aws_eip" "nat1" {
  domain = "vpc"

  tags = merge(
    {
      Name        = "${var.cluster_name}-eip-az1-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

resource "aws_eip" "nat2" {
  domain = "vpc"

  tags = merge(
    {
      Name        = "${var.cluster_name}-eip-az2-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

##########################################
# NAT Gateways
##########################################
resource "aws_nat_gateway" "nat_gateway1" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.public_subnet1.id

  tags = merge(
    {
      Name        = "${var.cluster_name}-nat-gateway-az1-${var.env}"
      Environment = var.env
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat_gateway2" {
  allocation_id = aws_eip.nat2.id
  subnet_id     = aws_subnet.public_subnet2.id

  tags = merge(
    {
      Name        = "${var.cluster_name}-nat-gateway-az2-${var.env}"
      Environment = var.env
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.main]
}

##########################################
# Route Tables
##########################################
# Public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-public-rt-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

# Private route tables
resource "aws_route_table" "private_route_table1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway1.id
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-private-rt-az1-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

resource "aws_route_table" "private_route_table2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway2.id
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-private-rt-az2-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

##########################################
# Route Table Associations
##########################################
# Public subnets associations
resource "aws_route_table_association" "public_subnet1_association" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet2_association" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_route_table.id
}

# Private app subnets associations
resource "aws_route_table_association" "private_app_subnet1_association" {
  subnet_id      = aws_subnet.private_app_subnet1.id
  route_table_id = aws_route_table.private_route_table1.id
}

resource "aws_route_table_association" "private_app_subnet2_association" {
  subnet_id      = aws_subnet.private_app_subnet2.id
  route_table_id = aws_route_table.private_route_table2.id
}

# Private data subnets associations
resource "aws_route_table_association" "private_data_subnet1_association" {
  subnet_id      = aws_subnet.private_data_subnet1.id
  route_table_id = aws_route_table.private_route_table1.id
}

resource "aws_route_table_association" "private_data_subnet2_association" {
  subnet_id      = aws_subnet.private_data_subnet2.id
  route_table_id = aws_route_table.private_route_table2.id
}