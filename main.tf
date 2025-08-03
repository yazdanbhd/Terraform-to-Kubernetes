provider "libvirt" {
  uri = "qemu:///system"
}



data "template_file" "network_config" {
  template = file("${path.module}/config/network_config.yml")
}

# Create a base disk from the Ubuntu image
resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-base.qcow2"
  source = var.ubuntu_18_img_url
  format = "qcow2"
}

# Create a disk for each VM by cloning and resizing the base
resource "libvirt_volume" "ubuntu_qcow2" {
  for_each = var.vms

  name           = "${each.key}-ubuntu-disk.qcow2"
  base_volume_id = libvirt_volume.ubuntu_base.id
  size           = each.value.disk_size
}

# Create a cloudinit disk for each VM
resource "libvirt_cloudinit_disk" "commoninit" {
  for_each = var.vms

  name           = "${each.key}-commoninit.iso"
  user_data      = templatefile("${path.module}/config/cloud_init.cfg", {
    hostname = each.value.vm_hostname
  })
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
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }

  timeouts {
    create = "5m"
  }
}

# First, create maps of VMs filtered by their role for easier templating.
locals {
  all_vms = {
    for k, vm in libvirt_domain.domain_ubuntu : k => {
      hostname = vm.name
      ip       = try(vm.network_interface.0.addresses.0, "")
      role     = var.vms[k].role
      is_etcd  = var.vms[k].role == "control-plane"
    }
  }

  control_plane_vms = {
    for k, vm in local.all_vms : k => vm if vm.role == "control-plane"
  }
}


# 1. Generate the inventory.ini file using the new dynamic template
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.ini.tmpl", {
    all_vms           = local.all_vms
    control_plane_vms = local.control_plane_vms
  })
  filename = var.inventory_path
}



# 2. Run Kubespray using Ansible after the VMs and inventory are ready
resource "null_resource" "run_kubespray" {
  depends_on = [local_file.ansible_inventory]

  provisioner "local-exec" {
    working_dir = "kubespray-integration/kubespray/"
    command = <<EOT
      ansible-playbook \
      -i ../../ansible/inventory/k8-clusters/inventory.ini \
      cluster.yml \
      -b -v --ask-vault-pass
    EOT
  }
}