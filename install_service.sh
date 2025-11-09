#!/bin/bash
# Install ServerRack as a systemd service

set -e

echo "Installing ServerRack as a systemd service..."

# Copy service file
sudo cp serverrack.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable serverrack.service

echo "Service installed successfully!"
echo ""
echo "Usage:"
echo "  Start service:   sudo systemctl start serverrack"
echo "  Stop service:    sudo systemctl stop serverrack"
echo "  View status:     sudo systemctl status serverrack"
echo "  View logs:       journalctl -u serverrack -f"
echo "  Disable service: sudo systemctl disable serverrack"
echo ""
echo "Note: The service will start automatically on boot"
