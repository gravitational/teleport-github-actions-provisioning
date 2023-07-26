variable "region" {
  description = "The AWS region where your servers will be deployed"
}

variable "hostname" {
  description = "The hostname of your server"
}

variable "proxy_server" {
  description = "The address of your Teleport proxy, including port"
}

variable "key_name" {
  description = "The name of your SSH key on AWS, as a backup."
}

variable "join_token" {
  description = "A token generated from your Teleport cluster to allow a VM join"
}

variable "teleport_version" {
  description = "The version of Teleport to install"
}
