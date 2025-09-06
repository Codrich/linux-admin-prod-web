variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "linux-admin-prod-web"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "my_ip_cidr" {
  type        = string
  description = "YourIP/32"
}

variable "backup_bucket" {
  type        = string
  description = "Existing S3 bucket name for backups"
}
