#!/bin/bash
# Deploy script to copy application to remote Pis

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <target-pi-ip> [target-pi-ip ...]"
    echo "Example: $0 192.168.1.101 192.168.1.102"
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_DIR="/home/pi/ServerRack"
REMOTE_USER="pi"

echo "Deploying ServerRack application to remote Pis..."

for TARGET_IP in "$@"; do
    echo ""
    echo "========================================="
    echo "Deploying to $TARGET_IP"
    echo "========================================="

    # Create remote directory
    ssh ${REMOTE_USER}@${TARGET_IP} "mkdir -p ${REMOTE_DIR}"

    # Copy files
    echo "Copying files..."
    rsync -avz --exclude 'venv' --exclude '__pycache__' --exclude '*.pyc' \
        ${PROJECT_DIR}/ ${REMOTE_USER}@${TARGET_IP}:${REMOTE_DIR}/

    # Run setup script
    echo "Running setup script..."
    ssh ${REMOTE_USER}@${TARGET_IP} "cd ${REMOTE_DIR} && chmod +x setup.sh && ./setup.sh"

    echo "Deployment to $TARGET_IP complete!"
done

echo ""
echo "========================================="
echo "All deployments complete!"
echo "========================================="
