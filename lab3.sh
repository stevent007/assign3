#!/bin/bash
# This script deploys and runs the configure-host.sh script on two servers

# Define verbose mode
VERBOSE=false

# Function to display verbose output
verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "$@"
    fi
}

# Function to handle SCP and SSH operations
deploy_and_run() {
    local script="$1"
    local server="$2"
    local args="${@:3}"  # Get arguments from third position onwards

    # Deploy script to remote server
    verbose "Deploying script to $server..."
    scp $script remoteadmin@$server:/root
    scp_exit_code=$?

    if [ $scp_exit_code -ne 0 ]; then
        echo "Error: Failed to deploy script to $server."
        exit $scp_exit_code
    fi

    # Run script on remote server
    verbose "Running script on $server..."
    ssh remoteadmin@$server -- "/root/$script $args"
}

# Main script
# Usage: ./lab3.sh [-verbose]
# Optional flag: -verbose to enable verbose mode
while [[ $# -gt 0 ]]; do
    case "$1" in
        -verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Usage: $0 [-verbose]"
            exit 1
            ;;
    esac
done

# Deploy and run configure-host.sh on server1
deploy_and_run configure-host.sh server1-mgmt -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4

# Deploy and run configure-host.sh on server2
deploy_and_run configure-host.sh server2-mgmt -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3

