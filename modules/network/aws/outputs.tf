# ============================================
# network/aws — outputs (the network concept's contract surface)
# ============================================
# Downstream concepts (cluster, loadbalancer, service) consume these.

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC."
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table (null when there is no public tier)."
  value       = one(aws_route_table.public[*].id)
}

output "private_route_table_ids" {
  description = "IDs of the private route tables."
  value       = aws_route_table.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway (null when there is no public tier)."
  value       = one(aws_internet_gateway.main[*].id)
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways (empty when NAT is disabled)."
  value       = aws_nat_gateway.main[*].id
}

output "nat_public_ips" {
  description = "Public Elastic IPs of the NAT gateways."
  value       = aws_eip.nat[*].public_ip
}

output "availability_zones" {
  description = "Availability zones the subnets were placed in."
  value       = var.availability_zones
}
