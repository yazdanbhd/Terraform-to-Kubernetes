provider "libvirt" {
  uri = "qemu:///system"
}

data "template_file" "user_data" {
  template = file("${path.module}/config/cloud_init.cfg")
}

data "template_file" "network_config" {
  template = file("${path.module}/config/network_config.yml")
}

# Create a disk for each VM
resource "libvirt_volume" "ubuntu_qcow2" {
  for_each = var.vms

  name   = "${each.key}-ubuntu-disk.qcow2"
  source = var.ubuntu_18_img_url
  format = "qcow2"
  # size   = each.value.disk_size
}

# Create a cloudinit disk for each VM
resource "libvirt_cloudinit_disk" "commoninit" {
  for_each = var.vms

  name           = "${each.key}-commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
}

# Create a VM (domain) for each VM configuration
resource "libvirt_domain" "domain_ubuntu" {
  for_each = var.vms

  name   = each.value.vm_hostname
  memory = each.value.memory
  vcpu   = each.value.vcpu

  cloudinit = libvirt_cloudinit_disk.commoninit[each.key].id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
    hostname       = each.value.vm_hostname
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.ubuntu_qcow2[each.key].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
