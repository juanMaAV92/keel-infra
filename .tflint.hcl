# tflint configuration — https://github.com/terraform-linters/tflint
# Runs in CI and locally via `tflint --recursive`.

config {
  # Lint module calls as well as root configs.
  call_module_type = "all"
  force            = false
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# AWS ruleset — enabled now because AWS is the V1 target cloud.
# Add `google` / `azurerm` plugins here as those implementations land.
plugin "aws" {
  enabled = true
  version = "0.39.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
