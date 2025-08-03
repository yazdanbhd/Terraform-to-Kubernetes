output "ips" {
  description = "Map of VM names to their primary IP addresses"
  value = {
    for key, domain in libvirt_domain.domain_ubuntu :
    key => try(domain.network_interface[0].addresses[0], "IP not assigned yet")
  }
}

output "vm_details" {
  description = "Detailed information about each VM"
  value = {
    for key, domain in libvirt_domain.domain_ubuntu :
    key => {
      hostname = domain.name
      ip       = try(domain.network_interface[0].addresses[0], "IP not assigned yet")
      role     = var.vms[key].role
      memory   = var.vms[key].memory
      vcpu     = var.vms[key].vcpu
    }
  }
}

output "control_plane_ip" {
  description = "IP address of the control plane node"
  value = {
    for key, domain in libvirt_domain.domain_ubuntu :
    key => try(domain.network_interface[0].addresses[0], "IP not assigned yet")
    if var.vms[key].role == "control-plane"
  }
}

output "worker_ips" {
  description = "IP addresses of worker nodes"
  value = [
    for key, domain in libvirt_domain.domain_ubuntu :
    try(domain.network_interface[0].addresses[0], "IP not assigned yet")
    if var.vms[key].role == "worker"
  ]
}