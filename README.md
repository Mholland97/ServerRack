# ServerRack - Raspberry Pi Cluster Control

A modern GUI application for controlling and monitoring a cluster of Raspberry Pi 5s with integrated Ollama AI chatbot capabilities.

## Features

- **Modern GUI Interface**: Built with CustomTkinter for a sleek, dark-themed interface
- **AI Chatbot**: Integrated Ollama support with multiple LLM models (deepseek-r1:7b, gemma2, mistral)
- **Cluster Management**: Control up to 4 Raspberry Pi 5s from a central controller
- **Real-time Monitoring**: Track CPU, memory, temperature, and disk usage across all nodes
- **Model Management**: Install, remove, and switch between Ollama models on any Pi
- **File Synchronization**: Sync files between Pis with NVME SSDs
- **SSH-based Control**: Secure communication and control via SSH

## Architecture

The cluster consists of:
- **1 Controller Pi** (Main): Runs the GUI application and manages the cluster
- **1 Storage Pi**: Secondary Pi with NVME SSD for redundant storage
- **2 Worker Pis**: Additional compute nodes for distributed AI workloads

### Hardware Requirements

- 4x Raspberry Pi 5
- 2x 1TB NVME SSD (M.2)
- Network switch/router for local network
- Monitor, keyboard, mouse for the controller Pi

## Installation

### Quick Start

1. **Clone the repository on your main Pi:**
   ```bash
   git clone <repository-url>
   cd ServerRack
   ```

2. **Run the setup script:**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Configure your cluster:**
   Edit `config.yaml` with your Pi IP addresses and settings:
   ```yaml
   nodes:
     - id: "pi-main"
       ip: "192.168.1.100"  # Update with your Pi's IP
       role: "controller"
       has_ssd: true
       # ... more settings
   ```

4. **Setup SSH keys:**
   Copy your SSH public key to other Pis for passwordless authentication:
   ```bash
   ssh-copy-id pi@192.168.1.101
   ssh-copy-id pi@192.168.1.102
   ssh-copy-id pi@192.168.1.103
   ```

5. **Pull Ollama models:**
   ```bash
   ollama pull deepseek-r1:7b
   ollama pull gemma2:9b
   ollama pull mistral:7b
   ```

6. **Deploy to other Pis (optional):**
   ```bash
   ./deploy.sh 192.168.1.101 192.168.1.102 192.168.1.103
   ```

7. **Run the application:**
   ```bash
   ./run.sh
   ```

## Configuration

The `config.yaml` file contains all cluster configuration:

### Node Configuration

```yaml
nodes:
  - id: "pi-main"              # Unique identifier
    hostname: "raspberrypi-main.local"
    ip: "192.168.1.100"        # Static IP address
    role: "controller"          # controller or worker
    has_ssd: true              # Does this Pi have an SSD?
    ssd_mount: "/mnt/nvme"     # SSD mount point
    ssh_user: "pi"             # SSH username
    ssh_port: 22               # SSH port
```

### Ollama Configuration

```yaml
ollama:
  default_model: "deepseek-r1:7b"
  available_models:
    - "deepseek-r1:7b"
    - "gemma2:9b"
    - "mistral:7b"
  host: "localhost"
  port: 11434
```

### File Synchronization

```yaml
sync:
  enabled: true
  source_node: "pi-main"
  target_nodes:
    - "pi-storage"
  sync_paths:
    - "/mnt/nvme/shared"
  interval: 300  # seconds
```

## Usage

### Main Interface

The application window is divided into two main panels:

#### Left Panel: Chat Interface
- **Chat Display**: View conversation history with the AI
- **Input Field**: Type your messages
- **Send Button**: Submit messages (or use Ctrl+Enter)
- **Model Selector**: Switch between different Ollama models

#### Right Panel: Cluster Monitoring
- **Node Status**: Real-time metrics for each Pi
  - CPU usage percentage
  - Memory usage percentage
  - CPU temperature
  - Disk usage percentage
- **Control Buttons**:
  - **Sync Storage**: Synchronize files between SSDs
  - **Manage Models**: Open the model management dialog

### Model Management

Click "Manage Models" to:
- View installed models on each Pi
- Pull new models from Ollama registry
- Remove unused models to free space
- Switch between nodes using the dropdown

Common models you can install:
- `deepseek-r1:7b` - DeepSeek reasoning model
- `gemma2:9b` - Google's Gemma 2 model
- `mistral:7b` - Mistral AI's base model
- `llama3.2:3b` - Meta's efficient LLaMA model
- `qwen2.5:7b` - Alibaba's Qwen model
- `phi3:mini` - Microsoft's small model

### Storage Synchronization

The application can automatically sync directories between Pis with SSDs:

1. Configure sync paths in `config.yaml`
2. Click "Sync Storage" to manually trigger sync
3. Files are synchronized using rsync over SSH

## Project Structure

```
ServerRack/
├── config.yaml              # Cluster configuration
├── requirements.txt         # Python dependencies
├── setup.sh                # Initial setup script
├── deploy.sh               # Deploy to remote Pis
├── run.sh                  # Run the application
├── README.md               # This file
└── src/
    ├── __init__.py
    ├── gui_app.py          # Main GUI application
    ├── config_manager.py   # Configuration management
    ├── ollama_client.py    # Ollama API client
    ├── ssh_client.py       # SSH communication
    ├── resource_monitor.py # System monitoring
    └── model_manager.py    # Model management dialog
```

## Troubleshooting

### Ollama Connection Issues
```bash
# Check if Ollama is running
sudo systemctl status ollama

# Start Ollama
sudo systemctl start ollama

# View Ollama logs
sudo journalctl -u ollama -f
```

### SSH Connection Issues
```bash
# Test SSH connection
ssh pi@192.168.1.101

# Check SSH service
sudo systemctl status ssh

# Regenerate SSH keys
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```

### GUI Issues on Raspberry Pi
```bash
# Install additional dependencies
sudo apt-get install python3-tk

# Check display
echo $DISPLAY

# Run with verbose logging
cd src && python gui_app.py
```

### Temperature Monitoring
If temperature isn't showing:
```bash
# Test vcgencmd
vcgencmd measure_temp

# Add user to video group
sudo usermod -aG video $USER
```

## Performance Tips

1. **Model Selection**: Use smaller models (3B-7B parameters) for better performance on Pi 5
2. **Memory Management**: Close unused applications when running large models
3. **Cooling**: Ensure adequate cooling for sustained AI workloads
4. **Storage**: Use NVME SSD for model storage and swap space
5. **Networking**: Use Gigabit Ethernet for faster sync and communication

## Advanced Configuration

### Custom Model Parameters

Edit `src/ollama_client.py` to customize model parameters:
```python
payload = {
    "model": model,
    "messages": messages,
    "stream": stream,
    "options": {
        "temperature": 0.7,
        "top_p": 0.9,
        "num_ctx": 4096
    }
}
```

### Distributed Inference

For advanced users, you can modify the chat interface to distribute queries across multiple Pis for load balancing.

### Auto-start on Boot

Create a systemd service:
```bash
sudo nano /etc/systemd/system/serverrack.service
```

```ini
[Unit]
Description=ServerRack Cluster Control
After=network.target ollama.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/ServerRack
ExecStart=/home/pi/ServerRack/run.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Enable the service:
```bash
sudo systemctl enable serverrack
sudo systemctl start serverrack
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is provided as-is for educational and personal use.

## Acknowledgments

- Built with [CustomTkinter](https://github.com/TomSchimansky/CustomTkinter)
- Powered by [Ollama](https://ollama.com)
- Designed for Raspberry Pi 5
