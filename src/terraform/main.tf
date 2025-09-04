terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

## Configure the Proxmox provider
#
provider "proxmox" {
  pm_api_url = var.pm_api_url
  pm_api_token_id = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure = var.pm_tls_insecure
  pm_debug = var.pm_debug
}

## Create LXC container for Ghost blog
#
resource "proxmox_lxc" "ghost_blog_container" {
  target_node  = var.lxc_target_node
  hostname     = var.lxc_hostname
  ostemplate   = var.lxc_ostemplate
  vmid         = var.lxc_vmid
  password     = var.lxc_password
  unprivileged = var.lxc_unprivileged
  onboot       = var.lxc_onboot
  startup      = var.lxc_startup
  
  # Root filesystem
  rootfs {
    storage = var.lxc_storage
    size    = var.lxc_rootfs_size
  }

  # Network configuration
  network {
    name   = var.lxc_network_name
    bridge = var.lxc_network_bridge
    ip     = var.lxc_network_ip
    gw     = var.lxc_network_gateway
  }

  # Resource limits
  cores  = var.lxc_cores
  memory = var.lxc_memory
  swap   = var.lxc_swap

  # SSH key for root access
  ssh_public_keys = var.lxc_ssh_public_keys

  # Start the container after creation
  start = var.lxc_start_container

  # Features
  features {
    nesting = var.lxc_nesting
  }
}
