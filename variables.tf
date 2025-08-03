variable "ubuntu_18_img_url" {
  description = "Path or URL to the Ubuntu image"
  default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

variable "disk_size" {
  description = "Disk size in bytes for each VM"
  type        = number
  default     = 21474836480
}

variable "vms" {
  description = "Map of VM configurations"
  type = map(object({
    vm_hostname = string
    memory      = number
    vcpu        = number
    role        = string
    disk_size   = number
  }))
  default = {
    "control-plane" = {
      vm_hostname = "k8s-control-plane"
      memory      = 4096
      vcpu        = 2
      role        = "control-plane"
      disk_size   = 21474836480
    },
    "worker1" = {
      vm_hostname = "k8s-worker1"
      memory      = 4096
      vcpu        = 2
      role        = "worker"
      disk_size   = 21474836480
    }
  }
}

variable "inventory_path" {
  type        = string
  description = "Path to the Ansible inventory file to be generated."
  default     = "ansible/inventory/k8-clusters/inventory.ini"
}

variable "kubespray_playbook_path" {
  type        = string
  description = "Path to the main Kubespray cluster.yml playbook."
  default     = "kubespray-integration/kubespray/cluster.yml"
}
