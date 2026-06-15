#!/bin/bash
set -euo pipefail
# Clean up logs but preserve expected paths/files.
find /var/log -type f -exec truncate -s 0 {} \;
find /var/log -type f -delete
find /var/log/* -type f  -exec rm -f {} \;
find /var/log/* -type d  -exec rm -rf {} \;
#find /var/log/ -type d -delete
# Clean up tmp directories
rm -rf /tmp/*
rm -rf /var/tmp/*

# Clear bash history for current shell and common user locations
history -c
history -w
rm -f ~/.bash_history
rm -f /root/.bash_history
find /home -maxdepth 2 -name .bash_history -type f -delete

# Remove SSH host keys so clones generate unique host identities on first boot
rm -f /etc/ssh/ssh_host_*

# Clear package manager cache and metadata
apt-get clean
rm -rf /var/lib/apt/lists/*

# Reset machine-id and random seed for uniqueness on clone
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id
rm -f /var/lib/systemd/random-seed

# Clean up cloud-init instance state
rm -rf /var/lib/cloud/instances/*

# Must be the last step; prepares first-boot behavior and powers off


echo "Ubuntu server cleanup complete"
cloud-init clean --logs --machine-id --seed #--shutdown
shutdown -h now