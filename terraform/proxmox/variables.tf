variable "pm_api_url"          { type = string }
variable "pm_api_token_id"     { type = string }
variable "pm_api_token_secret" { type = string }

variable "pve_node"      { type = string  default = "homelab" }
variable "template_name" { type = string  default = "ubuntu-24.04-ci" } # VM 9000
variable "bridge"        { type = string  default = "vmbr0" }
variable "storage"       { type = string  default = "local-lvm" }

variable "vmid"          { type = number  default = 103 }
variable "name"          { type = string  default = "web02" }
variable "cores"         { type = number  default = 2 }
variable "memory"        { type = number  default = 4096 }
variable "disk_size"     { type = string  default = "12G" }

variable "ci_user"       { type = string  default = "ubuntu" }
variable "ssh_public_key"{ type = string }                    # kommt aus tfvars
variable "ipconfig0"     { type = string  default = "ip=dhcp" }
