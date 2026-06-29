# ============================================
# network/aws — input variables
# ============================================
# Common contract inputs (every keel-infra module accepts these). See docs/contract.md.

variable "project_name" {
  description = "Project slug — the first token in every resource name (<project>-<env>-...)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "project_name must be lowercase alphanumeric with hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment slug — the second token in every resource name (e.g. stg, prod)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.environment))
    error_message = "environment must be lowercase alphanumeric with hyphens, starting with a letter."
  }
}

variable "common_tags" {
  description = "Tags merged into every resource, on top of the module's baseline tags."
  type        = map(string)
  default     = {}
}

# ----- Network-specific inputs -----

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across. Subnets are assigned to AZs by index (cycling if there are more subnets than AZs)."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) > 0
    error_message = "Provide at least one availability zone."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (routed to the internet gateway). Empty = no public tier."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets. Egress to the internet requires enable_nat_gateway. Empty = no private tier."
  type        = list(string)
  default     = []
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign a public IP to instances launched in public subnets."
  type        = bool
  default     = true
}

# ----- Egress (the gap keel-infra closes vs. an egress-less private tier) -----

variable "enable_nat_gateway" {
  description = "Create NAT gateway(s) so private subnets can reach the internet. Off by default — NAT gateways cost money."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "When enable_nat_gateway is true: one shared NAT gateway (cheaper) instead of one per AZ (more available). Ignored when NAT is disabled."
  type        = bool
  default     = true
}

variable "enable_s3_gateway_endpoint" {
  description = "Create a free S3 gateway VPC endpoint so S3 traffic skips the NAT gateway. Recommended when NAT is enabled."
  type        = bool
  default     = false
}

# ----- Observability -----

variable "enable_flow_logs" {
  description = "Capture VPC flow logs to CloudWatch."
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Retention for the flow-logs CloudWatch log group (days)."
  type        = number
  default     = 14

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.flow_logs_retention_days)
    error_message = "flow_logs_retention_days must be a value CloudWatch Logs accepts."
  }
}
