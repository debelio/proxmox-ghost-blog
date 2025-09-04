# Ghost Blog Deployment on Proxmox VE

This PoC project automates the deployment of a Ghost blog in an LXC container on Proxmox VE using Terraform for infrastructure provisioning and Ansible for application configuration.

## Project Structure

```
ghost-blog/
├── README.md
├── .gitignore
├── provision.sh              # Main provisioning script
├── configure.sh              # Ghost configuration script
├── src/
│   ├── terraform/
│   │   ├── main.tf           # Terraform configuration
│   │   ├── vars.tf           # Variable definitions
│   │   ├── outputs.tf        # Output definitions
│   │   └── .env              # Environment variables (not in repo)
│   └── ansible/
│       ├── ghost-blog-playbook.yml    # Ansible playbook
│       ├── inventory.template          # Inventory template
│       ├── vault.yml                  # Encrypted variables
│       └── templates/
│           └── ghost-nginx.conf.j2    # Nginx configuration template
```

## Prerequisites

- **Proxmox VE environment** (tested with v.9.0.6)
- **Terraform** or **OpenTofu** installed on your local machine
- **Ansible** installed with required collections
- **Proxmox provider** for Terraform
- **API token** with sufficient permissions in Proxmox
- **Container template** (Ubuntu 24.04) downloaded in Proxmox
- **netcat (nc)** for connection testing

## Setup Instructions

### 1. Set up Proxmox Role, User, and API Token

#### Create a role with required privileges
```shell
pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.PowerMgmt SDN.Use"
```

#### Create a user for Terraform
```shell
pveum user add terraform@pve
```

#### Assign the role to the user
```shell
pveum aclmod / -user terraform@pve -role TerraformProv
```

#### Create an API token
```shell
pveum user token add terraform@pve ghostBlogProvision --privsep 0
```

#### Download the Ubuntu container template
```shell
pveam update
pveam download local-storage ubuntu-24.04-standard_24.04-2_amd64.tar.zst
```

### 2. Configure Environment Variables

Create a `.env` file in the `src/terraform/` directory:

```bash
# src/terraform/.env
API_TOKEN_ID='terraform@pve!ghostBlogProvision'
API_TOKEN_SECRET="your-actual-token-secret"
PM_API_URL="https://your-proxmox-server:8006/api2/json"
```

### 3. Configure Ansible Vault

The project uses Ansible Vault to encrypt sensitive variables. The vault password is: `secretPassword`.

To view/edit the vault file:
```bash
ansible-vault edit src/ansible/vault.yml --ask-vault-pass
```

### 4. Terraform Variables Configuration

Review and modify the default values in `src/terraform/vars.tf` according to your environment:

```bash
# Edit Terraform variables if needed
vim src/terraform/vars.tf
```

Key variables you may want to customize:
- **Container IP address** (default: 192.168.10.5/24)
- **Resource allocation** (CPU cores, RAM, storage)
- **SSH public key path**
- **Proxmox node name** and **storage locations**

## Deployment

### Automated Deployment

Run the main provisioning script:
```bash
./provision.sh
```

This script will:
1. Load environment variables from `.env`
2. Initialize and plan Terraform configuration
3. Ask for confirmation before applying changes
4. Provision the LXC container
5. Automatically run the Ansible configuration
6. Display the Ghost blog URL when complete

### Manual Deployment

#### Step 1: Provision Infrastructure
```bash
cd src/terraform
export TF_VAR_pm_api_token_id='terraform@pve!ghostBlogProvision'
export TF_VAR_pm_api_token_secret="your-token-secret"
export TF_VAR_pm_api_url="https://your-proxmox-server:8006/api2/json"

terraform init
terraform plan
terraform apply
```

#### Step 2: Configure Ghost Blog
```bash
cd ../..
export CONTAINER_IP=$(cd src/terraform && terraform output -raw container_ip | cut -d'/' -f1)
./configure.sh
```

## What Gets Deployed

### Infrastructure (via Terraform)
- **LXC Container** with Ubuntu 24.04
- **4 CPU cores** and **2GB RAM**
- **20GB storage** on ZFS
- **Static IP assignment** (192.168.10.5/24)
- **SSH key authentication** configured

### Application Stack (via Ansible)
- **Node.js 22.x** runtime
- **MySQL server** with dedicated Ghost database
- **Ghost CMS** with CLI installation
- **Nginx** reverse proxy with optimized configuration
- **Systemd service** for Ghost management
- **Security headers** and **gzip compression** configured

### Ghost Configuration
- **Database**: MySQL (not SQLite)
- **Port**: 2368 (internal)
- **Reverse Proxy**: Nginx on port 80
- **Admin Panel**: Available at `/ghost/`
- **Systemd Integration**: Auto-start on boot

## Access Your Ghost Blog

After successful deployment:
- **Blog URL**: `http://CONTAINER_IP`
- **Admin Panel**: `http://CONTAINER_IP/ghost/`
- **Direct Ghost**: `http://CONTAINER_IP:2368` (internal only)

## File Descriptions

- **[provision.sh](provision.sh)**: Main script that orchestrates the entire deployment
- **[configure.sh](configure.sh)**: Ansible automation script for Ghost setup
- **[src/terraform/main.tf](src/terraform/main.tf)**: Terraform LXC container definition
- **[src/terraform/vars.tf](src/terraform/vars.tf)**: Terraform variable definitions
- **[src/terraform/outputs.tf](src/terraform/outputs.tf)**: Terraform outputs (IP, hostname, VMID)
- **[src/ansible/ghost-blog-playbook.yml](src/ansible/ghost-blog-playbook.yml)**: Complete Ghost installation playbook
- **[src/ansible/templates/ghost-nginx.conf.j2](src/ansible/templates/ghost-nginx.conf.j2)**: Nginx configuration template

## Security Features

- **Unprivileged LXC container**
- **SSH key-only authentication**
- **Dedicated MySQL database user**
- **Nginx security headers**
- **Ansible Vault for sensitive data**
- **Ghost user with limited sudo privileges**

## Troubleshooting

### Common Issues

1. **Connection refused**: Container may still be starting up
2. **Terraform apply fails**: Check API token permissions
3. **Ansible fails**: Verify SSH connectivity and vault password
4. **Ghost not accessible**: Check nginx configuration and Ghost service status

### Useful Commands

```bash
# Check container status
ssh root@CONTAINER_IP systemctl status ghost_*

# View Ghost logs
ssh root@CONTAINER_IP journalctl -u ghost_* -f

# Check Nginx status
ssh root@CONTAINER_IP systemctl status nginx

# Test Ghost directly
curl http://CONTAINER_IP:2368
```

## Cleanup

To destroy the infrastructure:
```bash
cd src/terraform
terraform destroy
```

## Future Enhancements
- Add SSL/TLS support with Let's Encrypt
- Add automated backups for Ghost content
- Restore from backups
- Implement monitoring and alerting

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

This is a proof-of-concept project created for demonstration purposes. Feel free to fork and modify according to your needs.
