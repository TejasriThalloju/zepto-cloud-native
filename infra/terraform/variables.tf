variable "region" { type=string default="ap-south-1" }
variable "project" { type=string default="quickcart" }
variable "vpc_cidr" { type=string default="10.20.0.0/16" }
variable "db_name" { type=string default="quickcart" }
variable "db_user" { type=string default="quickcart" }
variable "db_password" { type=string sensitive=true }

variable "github_org" { type = string }
variable "github_repo" { type = string }
