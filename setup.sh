#!/bin/bash
# Setup script for Raspberry Pi Cluster Control

set -e

echo "========================================="
echo "Raspberry Pi Cluster Control Setup"
echo "========================================="

# Check if running on Raspberry Pi
if [ ! -f /proc/device-tree/model ] || ! grep -q "Raspberry Pi" /proc/device-tree/model; then
    echo "Warning: This script is designed for Raspberry Pi"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Python dependencies
echo "Installing Python 3 and pip..."
sudo apt-get install -y python3 python3-pip python3-venv

# Install system dependencies
echo "Installing system dependencies..."
sudo apt-get install -y rsync openssh-server

# Create virtual environment
echo "Creating Python virtual environment..."
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install Python packages
echo "Installing Python packages..."
pip install --upgrade pip
pip install -r requirements.txt

# Install Ollama
echo "Installing Ollama..."
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "Ollama already installed"
fi

# Start Ollama service
echo "Starting Ollama service..."
sudo systemctl enable ollama
sudo systemctl start ollama

# Setup SSH keys for passwordless authentication
echo "Setting up SSH keys..."
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    echo "SSH key generated. Copy this public key to other Pis:"
    cat ~/.ssh/id_rsa.pub
else
    echo "SSH key already exists"
fi

# Create shared storage directory if SSD is present
if mount | grep -q "/mnt/nvme"; then
    echo "Creating shared storage directory..."
    sudo mkdir -p /mnt/nvme/shared
    sudo chown -R $USER:$USER /mnt/nvme/shared
fi

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Edit config.yaml with your Pi IP addresses and settings"
echo "2. Copy your SSH public key to other Pis using:"
echo "   ssh-copy-id pi@<other-pi-ip>"
echo "3. Pull your desired Ollama models:"
echo "   ollama pull deepseek-r1:7b"
echo "   ollama pull gemma2:9b"
echo "   ollama pull mistral:7b"
echo "4. Run the application:"
echo "   cd src && python gui_app.py"
echo ""
