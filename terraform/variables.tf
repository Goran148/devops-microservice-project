variable "aws_region" {
  description = "AWS region za deployment"
  type        = string
  default     = "eu-central-1" # Frankfurt
}

variable "instance_type" {
  description = "Tip EC2 instance"
  type        = string
  default     = "c7i-flex.large"
}