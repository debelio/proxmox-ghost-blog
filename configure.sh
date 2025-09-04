#!/usr/bin/env bash

#############################################
#                                           #
# Ghost blog container configuration script #
#                                           #
#############################################

## Variables
#
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

VAULT_FILE="$(dirname "$0")/src/ansible/vault.yml"

## Functions
#
# Print colorized messages
print_msg() {
  local color=$1
  local message=$2
  printf "\n${color}[::] %s${NC}\n" "$message"
}

# Convenience functions for different message types
print-info() { print_msg "$BLUE" "$1"; }
print-success() { print_msg "$GREEN" "$1"; }
print-error() { print_msg "$RED" "$1"; }
print-warning() { print_msg "$YELLOW" "$1"; }

# Function to wait for container to be ready (just check if port 22 is open)
wait_for_container() {
    local host_ip=$1
    local hostname=$2
    local max_attempts=20
    local attempt=1
    local sleep_time=5
    
    print-info "Waiting for container $hostname to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        printf "Attempt %d/%d: Checking if SSH port is open... " "$attempt" "$max_attempts"
        
        if nc -z -w5 "$host_ip" 22 >/dev/null 2>&1; then
            printf "SUCCESS\n"
            print-success "Container $hostname is ready (SSH port is open)."
            return 0
        else
            printf "FAILED\n"
            if [ $attempt -lt $max_attempts ]; then
                printf "Waiting %d seconds before next attempt...\n" "$sleep_time"
                sleep $sleep_time
            fi
        fi
        
        attempt=$((attempt + 1))
    done
    
    print-error "Container $hostname did not become ready after $max_attempts attempts!"
    return 1
}

## Main script execution
#
# Check if required environment variables are set
if [ -z "$CONTAINER_IP" ]; then
    print-error "CONTAINER_IP environment variable is not set!"
    exit 1
fi

# Check if Ansible is installed
if ! command -v ansible-playbook >/dev/null 2>&1; then
    print-error "Ansible is not installed. Please install Ansible to proceed!"
    exit 1
fi

# Check if netcat is available for port checking
if ! command -v nc >/dev/null 2>&1; then
    print-error "netcat (nc) is not installed. Please install netcat to proceed!"
    exit 1
fi

print-info "Starting Ghost blog configuration..."
print-info "Container IP: $CONTAINER_IP"
print-info "Container Hostname: ${CONTAINER_HOSTNAME:-'N/A'}"
print-info "Container VM ID: ${CONTAINER_VMID:-'N/A'}"

# Wait for container to be ready (just check SSH port)
if ! wait_for_container "$CONTAINER_IP" "$CONTAINER_HOSTNAME"; then
    exit 1
fi

# Create temporary inventory file
INVENTORY_FILE=$(mktemp)
trap 'rm -f "$INVENTORY_FILE"' EXIT

# Create inventory from template with connection retries
INVENTORY_TEMPLATE="$(dirname "$0")/src/ansible/inventory.template"
if [ -f "$INVENTORY_TEMPLATE" ]; then
    sed "s/CONTAINER_IP/$CONTAINER_IP/g" "$INVENTORY_TEMPLATE" > "$INVENTORY_FILE"
else
    # Fallback: create inventory inline with connection settings
    echo "[ghost_containers]" > "$INVENTORY_FILE"
    echo "$CONTAINER_IP ansible_user=root ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' ansible_ssh_retries=5 ansible_connection_timeout=30" >> "$INVENTORY_FILE"
fi

# Check if playbook exists
PLAYBOOK_FILE="$(dirname "$0")/src/ansible/ghost-blog-playbook.yml"
if [ ! -f "$PLAYBOOK_FILE" ]; then
    print-error "Ansible playbook not found at $PLAYBOOK_FILE!"
    exit 1
fi

# Run Ansible playbook with retries
print-info "Running Ansible playbook for Ghost blog configuration..."

if ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_FILE" --ask-vault-pass --extra-vars @"$VAULT_FILE" --extra-vars "ghost_domain=$CONTAINER_IP" --timeout=30; then
    print-success "Ghost blog is now accessible at: http://$CONTAINER_IP and admin panel at: http://$CONTAINER_IP/ghost/"
else
    print-error "Ansible playbook execution failed!"
    exit 1
fi
