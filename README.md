# Setting up a QEMU/KVM Virtual Machine with Libvirt using Terraform

This guide will help you set up a virtual machine using QEMU/KVM with libvirt through Terraform.

## Prerequisites
- Ubuntu 24.10 with QEMU, KVM, and libvirt installed
- Terraform v1.10.5 installed
- `terraform-provider-libvirt` ([dmacvicar/libvirt](https://registry.terraform.io/providers/dmacvicar/libvirt/latest)) plugin installed

## Quick Setup (Automated)

For a quick automated setup, you can use the provided script:

```sh
# Make the script executable
chmod +x script/setup-libvirt.sh

# Run the automated setup
./script/setup-libvirt.sh
```

This script will:
- Install QEMU/KVM and libvirt packages
- Create and configure the default storage pool
- Set proper permissions
- Add your user to the libvirt group
- Download and prepare the Ubuntu Cloud image
- Provide the absolute path to use in your Terraform configuration

After running the script, log out and log back in for group membership changes to take effect.

## Manual Configuration Steps

If you prefer to set up everything manually, follow these steps:

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

## Setup Script

The repository includes an automated setup script (`script/setup-libvirt.sh`) that handles the initial configuration of your system for libvirt and QEMU/KVM. This script:

- **Installs Dependencies**: Automatically installs `qemu-kvm`, `libvirt-daemon-system`, and `virt-manager`
- **Configures Storage Pool**: Creates and configures the default storage pool at `/var/lib/libvirt/images/default`
- **Sets Permissions**: Ensures proper ownership and permissions for the storage pool
- **Downloads Cloud Image**: Downloads the Ubuntu Jammy (22.04) cloud image and resizes it by +50G
- **User Configuration**: Adds your user to the libvirt group for proper access

The script provides the absolute path of the downloaded image, which you can use directly in your `variables.tf` file.

## Acknowledgment
Special thanks to **Molla Salehi** (GitHub: [mm3906078](https://github.com/mm3906078)) for contributions and guidance.



## Ansible: Deploying Nexus Repository Manager

This repository includes an Ansible role to install and configure Nexus Repository Manager on a host. Two approaches exist in the repo today; the recommended one is the role-based install.

### Structure assessment
- The `ansible/roles/nexus` role is correctly structured with `tasks/`, `templates/`, `handlers/`, and `defaults/` (added).
- Inventories live under `ansible/inventory/` with a `nexus/` inventory including `group_vars/nexus.yml`.
- There are duplicate playbooks for Nexus:
  - `ansible/deploy-nexus.yml` (role-based on remote host via inventory) — RECOMMENDED
  - `/deploy-nexus.yml` (imperative localhost flow) — legacy/example
  - `inventory/nexus/deploy-nexus.yml` (Docker-based Nexus) — optional alternative

Recommendation: Standardize on the role-based playbook with the `ansible/inventory/nexus` inventory. Treat the others as examples or remove them if not needed.

### Prerequisites
- A reachable Linux host (Ubuntu/Debian or RHEL-like) with Python 3 for Ansible
- SSH access as a sudo-capable user (configured in inventory)
- Ansible installed locally

### Inventory
Edit `ansible/inventory/nexus/inventory.ini` and `ansible/inventory/nexus/group_vars/nexus.yml` as needed. Defaults include:
- User/group: `nexus`
- Install dir: `/opt`
- Data dir: `/opt/sonatype-work/nexus3`
- UI port: `8081`
- Admin new password: `ChangeMe_123!` (change this!)

### Run (role-based install)
From the repo root:

```sh
ansible-playbook -i ansible/inventory/nexus/inventory.ini ansible/deploy-nexus.yml
```

What this does:
- Installs Java and dependencies
- Downloads and installs Nexus under `/opt`, creates `/opt/nexus` symlink
- Writes `nexus.properties` with `application-port={{ nexus_ui_port }}`
- Installs and enables a `systemd` service `nexus`
- Waits for the UI, rotates the admin password if still default
- Enables Docker Bearer Token Realm
- Optionally creates a `docker-hosted` repo if `docker_http_port` is set

Access:
- Web UI: `http://<your-host>:8081`
- Username: `admin`
- Password: the value set in `nexus_admin_new_password` (default rotates from initial)

### Alternative: Run Nexus via Docker
If you prefer to run Nexus as a container on the target host, an example playbook exists:

```sh
ansible-playbook -i inventory/nexus/inventory.ini inventory/nexus/deploy-nexus.yml
```

This will:
- Install Docker
- Create `/opt/nexus-data`
- Run `sonatype/nexus3` with ports `8081` and `5000` exposed

Note: The Docker approach doesn’t perform admin password rotation or REST API configuration. Use the role-based install for full automation.

### Nexus repository configuration (optional)
To programmatically create proxy/group/raw repositories (for air‑gapped K8s, Docker Hub mirrors, etc.), you can use the example playbook at the repo root:

```sh
export NEXUS_USER=admin
export NEXUS_PASSWORD='<your-admin-password>'
ansible-playbook deploy-nexus.yml
```

Update `nexus_host` inside that playbook to point to your Nexus URL.
