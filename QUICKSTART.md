# Quick Start Guide

Get your Raspberry Pi cluster running in 10 minutes!

## Prerequisites

- 4x Raspberry Pi 5 with Raspberry Pi OS installed
- All Pis connected to the same local network
- SSH enabled on all Pis
- One Pi connected to a monitor (this will be your controller)

## Step-by-Step Setup

### 1. Find Your Pi IP Addresses

On each Pi, run:
```bash
hostname -I
```

Note down the IP addresses. For example:
- Pi-Main: 192.168.1.100
- Pi-Storage: 192.168.1.101
- Pi-Worker1: 192.168.1.102
- Pi-Worker2: 192.168.1.103

### 2. Setup the Controller Pi

On your main Pi (connected to monitor):

```bash
# Clone or download the project
cd ~
git clone <repository-url> ServerRack
cd ServerRack

# Make scripts executable
chmod +x setup.sh run.sh deploy.sh

# Run setup
./setup.sh
```

Wait for the setup to complete (10-15 minutes for first time).

### 3. Configure Your Cluster

Edit the config file with your IP addresses:

```bash
nano config.yaml
```

Update the IP addresses under the `nodes` section:

```yaml
nodes:
  - id: "pi-main"
    ip: "192.168.1.100"  # Your main Pi IP
    # ... leave other settings as-is

  - id: "pi-storage"
    ip: "192.168.1.101"  # Your storage Pi IP
    # ... leave other settings as-is

  # ... update pi-worker1 and pi-worker2 IPs too
```

Save and exit (Ctrl+X, Y, Enter).

### 4. Setup SSH Keys

Copy your SSH key to the other Pis:

```bash
# When prompted, enter the password for each Pi (default: raspberry)
ssh-copy-id pi@192.168.1.101
ssh-copy-id pi@192.168.1.102
ssh-copy-id pi@192.168.1.103
```

Test the connection (should not ask for password):
```bash
ssh pi@192.168.1.101 "echo Connection OK"
```

### 5. Pull Your First AI Model

Download an AI model (this will take a few minutes):

```bash
ollama pull deepseek-r1:7b
```

For a lighter model, try:
```bash
ollama pull llama3.2:3b
```

### 6. Deploy to Other Pis (Optional)

To install the software on other Pis:

```bash
./deploy.sh 192.168.1.101 192.168.1.102 192.168.1.103
```

This will:
- Copy all files to other Pis
- Run setup on each Pi
- Install Ollama on each Pi

### 7. Launch the Application

```bash
./run.sh
```

## First Use

When the GUI opens:

1. **Test the Chat**:
   - Type "Hello, how are you?" in the input field
   - Click Send or press Ctrl+Enter
   - Watch the AI respond!

2. **Check Node Status**:
   - Look at the right panel
   - You should see your Pis with green "Online" status
   - Monitor CPU, memory, and temperature

3. **Try Model Management**:
   - Click "Manage Models"
   - Select a node
   - Pull additional models or remove unused ones

## Common First-Time Issues

### Issue: GUI doesn't start
**Solution:**
```bash
sudo apt-get install python3-tk
cd ServerRack
source venv/bin/activate
cd src
python gui_app.py
```

### Issue: Ollama not responding
**Solution:**
```bash
sudo systemctl start ollama
# Wait 5 seconds, then try again
```

### Issue: Nodes showing "Offline"
**Solution:**
```bash
# Check SSH connection
ssh pi@192.168.1.101

# If it asks for password, redo step 4
ssh-copy-id pi@192.168.1.101
```

### Issue: "Model not found" error
**Solution:**
```bash
# Pull the model first
ollama pull deepseek-r1:7b

# Check installed models
ollama list
```

## What to Try Next

1. **Test different models**: Switch models using the dropdown at the top
2. **Monitor resources**: Ask the AI to solve complex problems and watch CPU usage
3. **Sync storage**: Put some files in `/mnt/nvme/shared` and click "Sync Storage"
4. **Pull more models**: Use the Model Manager to install gemma2 or mistral

## Getting Help

- Check the full [README.md](README.md) for detailed documentation
- View logs: `journalctl -u ollama -f`
- Test individual components in the `src/` directory

## Quick Commands Reference

```bash
# Start the app
./run.sh

# Check Ollama status
sudo systemctl status ollama

# List installed models
ollama list

# Pull a model
ollama pull <model-name>

# Check all Pis are reachable
for ip in 192.168.1.{100..103}; do
  ping -c 1 $ip && echo "$ip OK" || echo "$ip FAILED"
done
```

Enjoy your AI cluster!
