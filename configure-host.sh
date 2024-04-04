#!/bin/bash
# This script configures basic host settings based on command-line arguments

# Function to log messages to syslog
log_message() {
    if [ "$VERBOSE" = true ]; then
        echo "$1"
    fi
    logger -t configure-host.sh "$1"
}

# Function to display usage information
display_usage() {
    echo "Usage: $0 [-verbose] [-name desiredName] [-ip desiredIPAddress] [-hostentry desiredName desiredIPAddress]"
    exit 1
}

# Initialize variables
VERBOSE=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -verbose)
        VERBOSE=true
        shift
        ;;
        -name)
        DESIRED_NAME="$2"
        shift
        shift
        ;;
        -ip)
        DESIRED_IP="$2"
        shift
        shift
        ;;
        -hostentry)
        HOST_NAME="$2"
        HOST_IP="$3"
        shift
        shift
        shift
        ;;
        *)
        display_usage
        ;;
    esac
done

# Verify required tools are installed
if ! command -v logger &> /dev/null; then
    echo "Error: logger command not found. Please install it." >&2
    exit 1
fi

# Configure host name
if [ -n "$DESIRED_NAME" ]; then
    CURRENT_NAME=$(hostname)
    if [ "$DESIRED_NAME" != "$CURRENT_NAME" ]; then
        log_message "Changing hostname from $CURRENT_NAME to $DESIRED_NAME"
        hostnamectl set-hostname "$DESIRED_NAME"
    fi
fi

# Configure LAN interface IP address
if [ -n "$DESIRED_IP" ]; then
    CURRENT_IP=$(hostname -I | awk '{print $1}')
    if [ "$DESIRED_IP" != "$CURRENT_IP" ]; then
        log_message "Changing LAN interface IP address from $CURRENT_IP to $DESIRED_IP"
        echo "network:
  version: 2
  ethernets:
    ens33:
      addresses: [$DESIRED_IP/24]
      gateway4: 192.168.16.2
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]" | sudo tee /etc/netplan/01-netcfg.yaml > /dev/null
        sudo netplan apply
    fi
fi

# Add or update host entry
if [ -n "$HOST_NAME" ] && [ -n "$HOST_IP" ]; then
    if grep -q "$HOST_NAME" /etc/hosts; then
        CURRENT_HOST_IP=$(grep "$HOST_NAME" /etc/hosts | awk '{print $1}')
        if [ "$HOST_IP" != "$CURRENT_HOST_IP" ]; then
            log_message "Updating host entry for $HOST_NAME from $CURRENT_HOST_IP to $HOST_IP"
            sudo sed -i "s/^$CURRENT_HOST_IP/$HOST_IP/" /etc/hosts
        fi
    else
        log_message "Adding host entry for $HOST_NAME with IP address $HOST_IP"
        echo "$HOST_IP $HOST_NAME" | sudo tee -a /etc/hosts > /dev/null
    fi
fi

# End of script

