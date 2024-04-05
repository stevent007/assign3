#!/bin/bash

# Function to display verbose output
verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "$@"
    fi
}

# Function to update hostname
update_hostname() {
    local desired_name="$1"
    local current_name=$(hostname)

    if [ "$current_name" != "$desired_name" ]; then
        verbose "Updating hostname to $desired_name..."
        sudo hostnamectl set-hostname "$desired_name"
        logger -t configure-host.sh "Updated hostname to $desired_name"
    else
        verbose "Hostname is already set to $desired_name. No action required."
    fi
}

# Function to update LAN interface IP address using netplan
update_ip() {
    local desired_ip="$1"
    local netplan_file="/etc/netplan/01-netcfg.yaml"

    verbose "Updating LAN interface IP address to $desired_ip..."
    sudo sed -i "s/address: .*/address: $desired_ip/" $netplan_file
    sudo netplan apply
    logger -t configure-host.sh "Updated LAN interface IP address to $desired_ip"
}

# Function to update /etc/hosts entry
update_hosts_entry() {
    local desired_name="$1"
    local desired_ip="$2"

    if grep -q "$desired_name" /etc/hosts; then
        verbose "Host entry for $desired_name already exists in /etc/hosts. No action required."
    else
        verbose "Adding host entry for $desired_name to /etc/hosts..."
        echo "$desired_ip $desired_name" | sudo tee -a /etc/hosts > /dev/null
        logger -t configure-host.sh "Added host entry for $desired_name with IP address $desired_ip"
    fi
}

# Main script
# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -verbose)
            VERBOSE=true
            shift
            ;;
        -name)
            DESIRED_NAME="$2"
            shift 2
            ;;
        -ip)
            DESIRED_IP="$2"
            shift 2
            ;;
        -hostentry)
            HOST_NAME="$2"
            HOST_IP="$3"
            shift 3
            ;;
        *)
            echo "Invalid option: $1"
            exit 1
            ;;
    esac
done

# Update hostname if specified
if [ -n "$DESIRED_NAME" ]; then
    update_hostname "$DESIRED_NAME"
fi

# Update LAN interface IP address if specified
if [ -n "$DESIRED_IP" ]; then
    update_ip "$DESIRED_IP"
fi

# Update /etc/hosts entry if specified
if [ -n "$HOST_NAME" ] && [ -n "$HOST_IP" ]; then
    update_hosts_entry "$HOST_NAME" "$HOST_IP"
fi

