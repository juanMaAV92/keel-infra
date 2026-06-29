# Plan-level tests for network/aws. No real AWS calls — they assert the plan the module
# produces from its inputs, focused on the egress toggle (the module's headline feature).
# Run: terraform test  (from modules/network/aws)

# Mock the AWS provider so tests run offline, with no credentials and no API calls.
mock_provider "aws" {}

variables {
  project_name         = "acme"
  environment          = "stg"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
}

run "defaults_have_no_egress" {
  command = plan

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR should match the input."
  }

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "Should create two public and two private subnets."
  }

  assert {
    condition     = length(aws_nat_gateway.main) == 0
    error_message = "NAT is off by default, so no NAT gateways should be planned."
  }

  assert {
    condition     = length(aws_route_table.private) == 1
    error_message = "Without per-AZ NAT, a single private route table is expected."
  }
}

run "single_nat_gateway" {
  command = plan

  variables {
    enable_nat_gateway = true
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.main) == 1
    error_message = "single_nat_gateway should yield exactly one NAT gateway."
  }

  assert {
    condition     = length(aws_eip.nat) == 1
    error_message = "The single NAT gateway needs exactly one Elastic IP."
  }
}

run "nat_gateway_per_az" {
  command = plan

  variables {
    enable_nat_gateway = true
    single_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.main) == 2
    error_message = "Per-AZ mode should create one NAT gateway per public subnet."
  }

  assert {
    condition     = length(aws_route_table.private) == 2
    error_message = "Per-AZ NAT needs one private route table per private subnet."
  }
}

run "s3_endpoint_optional" {
  command = plan

  variables {
    enable_s3_gateway_endpoint = true
  }

  assert {
    condition     = length(aws_vpc_endpoint.s3) == 1
    error_message = "Enabling the S3 gateway endpoint should plan exactly one endpoint."
  }
}
