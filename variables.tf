variable "aws_region" {
  description = "AWS region where resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix used for resource names and tags."
  type        = string
  default     = "nginx-proxy"
}

variable "create_vpc" {
  description = "Create a minimal VPC, public subnet, internet gateway, and route table."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "Existing VPC ID. Required when create_vpc is false."
  type        = string
  default     = null

  validation {
    condition     = var.create_vpc || var.vpc_id != null
    error_message = "vpc_id is required when create_vpc is false."
  }
}

variable "subnet_id" {
  description = "Existing public subnet ID. Required when create_vpc is false."
  type        = string
  default     = null

  validation {
    condition     = var.create_vpc || var.subnet_id != null
    error_message = "subnet_id is required when create_vpc is false."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC created when create_vpc is true."
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet created when create_vpc is true."
  type        = string
  default     = "10.42.1.0/24"
}

variable "availability_zone" {
  description = "Optional availability zone for the created public subnet. Leave empty to let AWS choose."
  type        = string
  default     = ""
}

variable "create_ssh_key" {
  description = "Generate and register an AWS EC2 key pair for SSH access."
  type        = bool
  default     = true
}

variable "ssh_key_name" {
  description = "Name for the generated AWS EC2 key pair when create_ssh_key is true."
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name. Required when create_ssh_key is false."
  type        = string
  default     = null

  validation {
    condition     = var.create_ssh_key || var.key_name != null
    error_message = "key_name is required when create_ssh_key is false."
  }
}

variable "ssh_cidr" {
  description = "CIDR block allowed to SSH to the proxy."
  type        = string

  validation {
    condition     = !contains(["0.0.0.0/0", "::/0"], var.ssh_cidr)
    error_message = "Do not expose SSH to the whole internet. Use your IPv4 address with /32 or IPv6 address with /128."
  }
}

variable "http_cidrs" {
  description = "CIDR blocks allowed to reach HTTP on the proxy."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_cidrs" {
  description = "CIDR blocks allowed to reach HTTPS on the proxy."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "EC2 instance type for the proxy. Defaults to an ARM-based nano instance."
  type        = string
  default     = "t4g.nano"
}

variable "enable_elastic_ip" {
  description = "Allocate and associate an Elastic IP with the proxy instance."
  type        = bool
  default     = true
}

variable "tls_mode" {
  description = "TLS setup mode. Use manual for uploaded certificates or letsencrypt for certbot."
  type        = string
  default     = "manual"

  validation {
    condition     = contains(["manual", "letsencrypt"], var.tls_mode)
    error_message = "tls_mode must be manual or letsencrypt."
  }
}

variable "domain_name" {
  description = "Domain name used by Let's Encrypt mode."
  type        = string
  default     = ""

  validation {
    condition     = var.tls_mode != "letsencrypt" || var.domain_name != ""
    error_message = "domain_name is required when tls_mode is letsencrypt."
  }
}

variable "letsencrypt_email" {
  description = "Email address used for Let's Encrypt registration and renewal notices."
  type        = string
  default     = ""

  validation {
    condition     = var.tls_mode != "letsencrypt" || var.letsencrypt_email != ""
    error_message = "letsencrypt_email is required when tls_mode is letsencrypt."
  }
}

variable "letsencrypt_staging" {
  description = "Use the Let's Encrypt staging environment for testing."
  type        = bool
  default     = false
}

variable "letsencrypt_auto_issue" {
  description = "Run certbot during first boot. Use only when DNS already points at the instance public IP."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags applied to created resources."
  type        = map(string)
  default     = {}
}
