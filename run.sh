#!/bin/bash
# Run the Raspberry Pi Cluster Control application

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Activate virtual environment
if [ -d "${PROJECT_DIR}/venv" ]; then
    source "${PROJECT_DIR}/venv/bin/activate"
else
    echo "Virtual environment not found. Please run setup.sh first."
    exit 1
fi

# Check if Ollama is running
if ! systemctl is-active --quiet ollama; then
    echo "Starting Ollama service..."
    sudo systemctl start ollama
    sleep 2
fi

# Change to src directory and run application
cd "${PROJECT_DIR}/src"
python gui_app.py
