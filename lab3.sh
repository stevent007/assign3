#!/bin/bash
# This script transfers and runs the configure-host.sh script on 2 servers and updates the local /etc/hosts file

# Transfer configure-host.sh script to server1
scp configure-host.sh remoteadmin@server1-mgmt:/root

# Run configure-host.sh script on server1
ssh remoteadmin@server1-mgmt -- /root/configure-host.sh -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4

# Transfer configure-host.sh script to server2
scp configure-host.sh remoteadmin@server2-mgmt:/root

# Run configure-host.sh script on server2
ssh remoteadmin@server2-mgmt -- /root/configure-host.sh -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3

# Update local /etc/hosts file
./configure-host.sh -hostentry loghost 192.168.16.3
./configure-host.sh -hostentry webhost 192.168.16.4

