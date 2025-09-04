# Output the container's IP address
output "container_ip" {
  description = "IP address of the Ghost blog container"
  value       = proxmox_lxc.ghost_blog_container.network[0].ip
}

# Output the container's hostname
output "container_hostname" {
  description = "Hostname of the Ghost blog container"
  value       = proxmox_lxc.ghost_blog_container.hostname
}

# Output the container's VM ID
output "container_vmid" {
  description = "VM ID of the Ghost blog container"
  value       = proxmox_lxc.ghost_blog_container.vmid
}
