output "ips" {
  description = "Map of VM names to their primary IP addresses"
  value = {
    for key, domain in libvirt_domain.domain_ubuntu :
    key => domain.network_interface[0].addresses[0]
  }
}
