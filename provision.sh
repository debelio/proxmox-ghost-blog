#!/usr/bin/env bash

#############################################
#                                           #
# Proxmox LXC container provisioning script #
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

# Track timing
START_TIME=$(date +%s)

# Lock file path
SCRIPT_NAME=$(basename "$0")
LOCK_FILE="/tmp/${SCRIPT_NAME%.*}.lock"

# Script working directory
WORKING_DIR=$(pwd)

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

# Format time in seconds to a readable format
format_time() {
  local SECONDS=$1
  local HOURS=$((SECONDS / 3600))
  local MINUTES=$(((SECONDS % 3600) / 60))
  local SECS=$((SECONDS % 60))
  
  if [ $HOURS -gt 0 ]; then
    echo "${HOURS}h:${MINUTES}m:${SECS}s"
  elif [ $MINUTES -gt 0 ]; then
    echo "${MINUTES}m:${SECS}s"
  else
    echo "${SECS}s"
  fi
}

# Ask user for confirmation
ask_confirmation() {
  local PROMPT="$1"
  local RESPONSE
  
  while true; do
    print-warning "$PROMPT [y/N]: "
    read -r RESPONSE
    case "$RESPONSE" in
      [yY]|[yY][eE][sS])
        return 0
        ;;
      [nN]|[nN][oO]|"")
        return 1
        ;;
      *)
        print-error "Please answer yes or no (y/n)."
        ;;
    esac
  done
}

# Calculate and display total execution time
calculate_and_display_total_time() {
  local END_TIME
  END_TIME=$(date +%s)
  local TOTAL_TIME=$((END_TIME - START_TIME))
  local TOTAL_FORMATTED
  TOTAL_FORMATTED=$(format_time $TOTAL_TIME)

  print-info "Total execution time: $TOTAL_FORMATTED."
}

## Main script execution
#
print-info "Starting container provisioning..."

# Check if lock file exists, if not create it and set trap on exit
if { set -C; 2>/dev/null true >"${LOCK_FILE}"; }; then
  trap 'rm -f ${LOCK_FILE}' EXIT
else
  print-error "The lock file ${LOCK_FILE} exists. The script will exit now!"
  exit
fi

# Load environment variables from .env file
ENV_FILE="$WORKING_DIR/src/terraform/.env"
if [ -f "$ENV_FILE" ]; then
  print-info "Loading environment variables from the .env file..."
  # Export variables from .env file
  set -a  # automatically export all variables
  # shellcheck source=./src/terraform/.env
  source "$ENV_FILE"
  set +a  # stop automatically exporting
else
  print-error ".env file not found at $ENV_FILE!"
  exit 1
fi

# Check if required environment variables are set
if [ -z "$API_TOKEN_ID" ] || [ -z "$API_TOKEN_SECRET" ] || [ -z "$PM_API_URL" ]; then
    print-error "API_TOKEN_ID, API_TOKEN_SECRET and PM_API_URL must be set in the .env file!"
    exit 1
fi

# Set environment variables for Terraform
print-info "Loading environment variables for the Terraform provider..."
export TF_VAR_pm_api_token_id=$API_TOKEN_ID
export TF_VAR_pm_api_token_secret=$API_TOKEN_SECRET
export TF_VAR_pm_api_url=$PM_API_URL

# Check if Terraform or OpenTofu
if command -v terraform >/dev/null 2>&1; then
  print-info "Using Terraform..."
  TERRAFORM=terraform
elif command -v tofu >/dev/null 2>&1; then
  print-info "Using OpenTofu..."
  TERRAFORM=tofu
else
  print-error "Neither Terraform nor OpenTofu is installed. Please install one of them to proceed!"
  exit 1
fi

# Change working directory to terraform
cd "$WORKING_DIR/src/terraform" || exit 1

# Initialize and apply Terraform configuration
print-info "Initializing Terraform..."
if ! $TERRAFORM init; then
    print-error "Terraform init failed!"
    exit 1
fi

print-info "Running Terraform plan..."
$TERRAFORM plan
PLAN_EXIT_CODE=$?

if [ $PLAN_EXIT_CODE -eq 0 ]; then
    print-success "Terraform plan completed successfully."
elif [ $PLAN_EXIT_CODE -eq 2 ]; then
    print-info "Terraform plan completed - changes to existing resources detected."
else
    print-error "Terraform plan failed with exit code $PLAN_EXIT_CODE!"
    exit 1
fi

# Ask user if they want to continue with apply
if ask_confirmation "Do you want to apply the Terraform configuration?"; then
    # Apply Terraform configuration
    print-info "Applying Terraform configuration..."
    if ! $TERRAFORM apply -auto-approve; then
        print-error "Terraform apply failed!"
        exit 1
    fi
    print-success "Terraform apply completed successfully."
    
    # Get container IP from Terraform output
    print-info "Retrieving container information..."
    CONTAINER_IP=$($TERRAFORM output -raw container_ip 2>/dev/null | cut -d'/' -f1)
    CONTAINER_HOSTNAME=$($TERRAFORM output -raw container_hostname 2>/dev/null)
    CONTAINER_VMID=$($TERRAFORM output -raw container_vmid 2>/dev/null)
    
    if [ -z "$CONTAINER_IP" ]; then
        print-error "Failed to retrieve container IP from Terraform output!"
        calculate_and_display_total_time
        exit 1
    fi

    print-success "Container deployed with IP: $CONTAINER_IP"

    # Change working directory
    cd "$WORKING_DIR"|| exit 1
    # Execute the configuration script with container details
    CONFIGURE_SCRIPT="$WORKING_DIR/configure.sh"
    if [ -f "$CONFIGURE_SCRIPT" ]; then
        print-info "Running Ghost blog configuration script..."
        if CONTAINER_IP="$CONTAINER_IP" CONTAINER_HOSTNAME="$CONTAINER_HOSTNAME" CONTAINER_VMID="$CONTAINER_VMID" bash "$CONFIGURE_SCRIPT"; then
            print-success "Ghost blog configuration completed successfully."
        else
            print-error "Ghost blog configuration failed!"
            calculate_and_display_total_time
            exit 1
        fi
    else
        print-warning "Configuration script not found at $CONFIGURE_SCRIPT."
    fi
else
    print-info "Terraform apply cancelled by user. Exiting..."
    calculate_and_display_total_time
    exit 0
fi

# Total execution time
calculate_and_display_total_time
