variable "region" {
  default = "ap-south-1"
}

variable "public_key_path" {
  default = "id_rsa.pub"
}

variable "bastion_ip" {
  default = "<IP here>/32"  # Update with your actual public IP
}
