## Variable definitions for Proxmox provider
#
variable "pm_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "pm_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
}

variable "pm_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "pm_tls_insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = true
}

variable "pm_debug" {
  description = "Enable Proxmox provider debug mode"
  type        = bool
  default     = false
}

## Variables for the LXC container configuration
#
variable "lxc_target_node" {
  description = "Proxmox target node"
  type        = string
  default     = "pve"
}

variable "lxc_hostname" {
  description = "Container hostname"
  type        = string
  default     = "ghost-blog"
}

variable "lxc_ostemplate" {
  description = "OS template for the container"
  type        = string
  default     = "pve-storage:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

variable "lxc_vmid" {
  description = "Container VM ID"
  type        = number
  default     = 200
}

variable "lxc_password" {
  description = "Container root password"
  type        = string
  sensitive   = true
  default     = "your-secure-password"
}

variable "lxc_unprivileged" {
  description = "Create unprivileged container"
  type        = bool
  default     = true
}

variable "lxc_onboot" {
  description = "Start container on boot"
  type        = bool
  default     = true
}

variable "lxc_startup" {
  description = "Startup order"
  type        = string
  default     = "order=6"
}

variable "lxc_storage" {
  description = "Storage for rootfs"
  type        = string
  default     = "local-zfs"
}

variable "lxc_rootfs_size" {
  description = "Root filesystem size"
  type        = string
  default     = "20G"
}

variable "lxc_network_name" {
  description = "Network interface name"
  type        = string
  default     = "eth0"
}

variable "lxc_network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "lxc_network_ip" {
  description = "IP address configuration"
  type        = string
  default     = "192.168.10.5/24"
}

variable "lxc_network_gateway" {
  description = "Network gateway"
  type        = string
  default     = "192.168.10.1"
}

variable "lxc_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 4
}

variable "lxc_memory" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "lxc_swap" {
  description = "Swap in MB"
  type        = number
  default     = 512
}

variable "lxc_ssh_public_keys" {
  description = "SSH public keys for root access"
  type        = string
  default     = "your-ssh-public-key"
}

variable "lxc_start_container" {
  description = "Start container after creation"
  type        = bool
  default     = true
}

variable "lxc_nesting" {
  description = "Enable nesting feature"
  type        = bool
  default     = true
}
