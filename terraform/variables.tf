variable "instance_name" {
  description = "Value of the EC2 instance's Name tag."
  type        = string
  default     = "devops-study-v3"
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t3.micro"
}


variable "key_name" {
  description = "Key pair for SSH connection."
  type        = string
  default     = "devops-study-key"
}

variable "security_group_id" {
  description = "Security Group for the instance."
  type        = string
  default     = "sg-0d3ee6e0f1ffc0707"
}
