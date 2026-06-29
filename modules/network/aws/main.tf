# ============================================
# network/aws — VPC, subnets, routing, egress
# ============================================
# Reference implementation of the `network` concept. The pattern here (locals for
# naming/tags, enable_* toggles, count-driven optional resources) is the template every
# other keel-infra module follows. See docs/contract.md.

data "aws_region" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  has_public  = length(var.public_subnet_cidrs) > 0
  has_private = length(var.private_subnet_cidrs) > 0

  # One NAT per AZ when single_nat_gateway is false; otherwise a single shared NAT.
  nat_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)) : 0

  # Per-AZ NAT needs a route table per private subnet so each routes to its own NAT;
  # otherwise a single private route table is enough.
  private_rt_count = local.has_private ? (var.enable_nat_gateway && !var.single_nat_gateway ? length(var.private_subnet_cidrs) : 1) : 0

  module_tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "network"
  })
}

# ----- VPC -----

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.module_tags, { Name = "${local.name_prefix}-vpc" })
}

# ----- Internet gateway (only when there is a public tier) -----

resource "aws_internet_gateway" "main" {
  count  = local.has_public ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(local.module_tags, { Name = "${local.name_prefix}-igw" })
}

# ----- Subnets -----

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(local.module_tags, {
    Name = "${local.name_prefix}-public-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index)

  tags = merge(local.module_tags, {
    Name = "${local.name_prefix}-private-${count.index + 1}"
    Tier = "private"
  })
}

# ----- Public routing -----

resource "aws_route_table" "public" {
  count  = local.has_public ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(local.module_tags, { Name = "${local.name_prefix}-public-rt" })
}

resource "aws_route" "public_internet" {
  count                  = local.has_public ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# ----- NAT gateways (egress for private subnets) -----

resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"

  tags = merge(local.module_tags, { Name = "${local.name_prefix}-nat-eip-${count.index + 1}" })
}

resource "aws_nat_gateway" "main" {
  count = local.nat_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.module_tags, { Name = "${local.name_prefix}-nat-${count.index + 1}" })

  depends_on = [aws_internet_gateway.main]

  lifecycle {
    precondition {
      condition     = local.has_public
      error_message = "enable_nat_gateway requires at least one public subnet to host the NAT gateway."
    }
  }
}

# ----- Private routing -----

resource "aws_route_table" "private" {
  count  = local.private_rt_count
  vpc_id = aws_vpc.main.id

  tags = merge(local.module_tags, { Name = "${local.name_prefix}-private-rt-${count.index + 1}" })
}

resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway ? local.private_rt_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id = aws_subnet.private[count.index].id
  # Per-AZ NAT: index-matched route table. Otherwise everyone shares the single one.
  route_table_id = (var.enable_nat_gateway && !var.single_nat_gateway) ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
}

# ----- S3 gateway endpoint (free; keeps S3 traffic off the NAT) -----

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_gateway_endpoint ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(aws_route_table.private[*].id, aws_route_table.public[*].id)

  tags = merge(local.module_tags, { Name = "${local.name_prefix}-s3-endpoint" })
}

# ----- Flow logs -----

resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc/${local.name_prefix}"
  retention_in_days = var.flow_logs_retention_days

  tags = local.module_tags
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${local.name_prefix}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })

  tags = local.module_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${local.name_prefix}-flow-logs-policy"
  role  = aws_iam_role.flow_logs[0].id

  # Scoped to this VPC's log group (not "*") — least privilege.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
      ]
      Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
    }]
  })
}

resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(local.module_tags, { Name = "${local.name_prefix}-flow-logs" })
}
