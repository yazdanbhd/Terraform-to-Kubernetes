# Setting up a QEMU/KVM Virtual Machine with Libvirt using Terraform

This guide will help you set up a virtual machine using QEMU/KVM with libvirt through Terraform.

## Prerequisites
- Ubuntu 24.10 with QEMU, KVM, and libvirt installed
- Terraform v1.10.5 installed
- `terraform-provider-libvirt` ([dmacvicar/libvirt](https://registry.terraform.io/providers/dmacvicar/libvirt/latest)) plugin installed

## Configuration Steps

### 1. Enable Libvirt and Adjust Permissions
To avoid permission denied errors when using Terraform with libvirt, modify the `/etc/libvirt/qemu.conf` file:

```sh
sudo nano /etc/libvirt/qemu.conf
```

Find the following line:

```sh
# security_driver = "selinux"
```

Change it to:

```sh
security_driver = "none"
```

Then restart libvirt:

```sh
sudo systemctl restart libvirtd
```

### 2. Clone Terraform Configuration Repository
If you have a predefined Terraform configuration, clone the repository:

```sh
git clone https://github.com/ArmanTaheriGhaleTaki/terraform-libvirt-sample.git
cd terraform-libvirt-sample
```

### 3. Initialize Terraform
Run the following command to initialize the Terraform working directory:

```sh
terraform init
```

### 4. Validate and Plan
Before applying the configuration, validate and check the execution plan:

```sh
terraform validate
terraform plan
```

### 5. Apply the Terraform Configuration
Once validated, apply the configuration to create the virtual machine:

```sh
terraform apply -auto-approve
```

### 6. Modify Cloud-Init Configuration
To customize your VM’s initialization process, update the Cloud-Init configuration according to your needs. Modify user-data and meta-data files accordingly.

### ⚠️⚠️ Static IP Issue ⚠️⚠️
If you configure a static IP for the VM, Terraform will not terminate successfully and will keep retrying endlessly. However, this is expected behavior, and you can safely interrupt the process and SSH into the server manually without issues.

###  Destroy the VM 
If you need to remove the VM, use:

```sh
terraform destroy -auto-approve
```

## Acknowledgment
Special thanks to **Molla Salehi** (GitHub: [mm3906078](https://github.com/mm3906078)) for contributions and guidance.


