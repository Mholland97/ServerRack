# ServerRack Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         ServerRack Cluster                       │
│                                                                   │
│  ┌─────────────────┐      ┌─────────────────┐                  │
│  │   Pi-Main       │      │  Pi-Storage     │                  │
│  │  (Controller)   │◄────►│   (Worker)      │                  │
│  │                 │      │                 │                  │
│  │  [1TB NVME SSD] │      │  [1TB NVME SSD] │                  │
│  │  GUI App        │      │  Ollama Server  │                  │
│  │  Ollama Server  │      │  SSH Server     │                  │
│  └────────┬────────┘      └─────────────────┘                  │
│           │                                                      │
│           │  SSH Control                                         │
│           │                                                      │
│  ┌────────┴────────────────────────────┐                       │
│  │                                     │                       │
│  ▼                                     ▼                       │
│  ┌─────────────────┐      ┌─────────────────┐                  │
│  │  Pi-Worker1     │      │  Pi-Worker2     │                  │
│  │   (Worker)      │      │   (Worker)      │                  │
│  │                 │      │                 │                  │
│  │  Ollama Server  │      │  Ollama Server  │                  │
│  │  SSH Server     │      │  SSH Server     │                  │
│  └─────────────────┘      └─────────────────┘                  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Component Architecture

### GUI Application (gui_app.py)

```
┌──────────────────────────────────────┐
│         ClusterControlApp            │
├──────────────────────────────────────┤
│                                      │
│  ┌────────────┐    ┌──────────────┐ │
│  │   Chat     │    │    Node      │ │
│  │ Interface  │    │  Monitoring  │ │
│  │            │    │              │ │
│  │ - Input    │    │ - CPU        │ │
│  │ - Display  │    │ - Memory     │ │
│  │ - History  │    │ - Temp       │ │
│  └──────┬─────┘    │ - Disk       │ │
│         │          └──────┬───────┘ │
│         │                 │         │
│         ▼                 ▼         │
│  ┌──────────────────────────────┐  │
│  │    OllamaClient              │  │
│  └──────────────┬───────────────┘  │
│                 │                   │
│                 ▼                   │
│  ┌──────────────────────────────┐  │
│  │    ConfigManager             │  │
│  └──────────────────────────────┘  │
│                                      │
└──────────────────────────────────────┘
```

### Module Dependencies

```
gui_app.py
    ├── config_manager.py (ConfigManager)
    │   └── config.yaml
    │
    ├── ollama_client.py (OllamaClient)
    │   └── HTTP → Ollama API (localhost:11434)
    │
    ├── ssh_client.py (SSHClient)
    │   └── SSH → Remote Pis
    │
    ├── resource_monitor.py (ResourceMonitor)
    │   ├── psutil
    │   └── vcgencmd
    │
    └── model_manager.py (ModelManagerDialog)
        ├── OllamaClient
        └── SSHClient
```

## Data Flow

### Chat Message Flow

```
User Input
    │
    ▼
ChatInterface.send_message()
    │
    ├─► Add to chat_history (List[Dict])
    │
    ├─► Update UI with user message
    │
    └─► Background Thread
            │
            ▼
        OllamaClient.chat()
            │
            ▼
        HTTP POST → Ollama API
            │
            ▼
        Stream Response Chunks
            │
            ▼
        Update UI (main thread via .after())
            │
            ▼
        Add to chat_history
```

### Resource Monitoring Flow

```
Background Thread (monitoring_loop)
    │
    └─► For each node:
            │
            ├─► If controller node:
            │       │
            │       ▼
            │   ResourceMonitor.get_all_metrics()
            │       │
            │       ├─► psutil.cpu_percent()
            │       ├─► psutil.virtual_memory()
            │       ├─► vcgencmd measure_temp
            │       └─► psutil.disk_usage()
            │
            └─► If worker node:
                    │
                    ▼
                SSHClient.connect()
                    │
                    ▼
                SSHClient.get_system_info()
                    │
                    ├─► Execute: top -bn1
                    ├─► Execute: free -m
                    ├─► Execute: vcgencmd measure_temp
                    └─► Execute: df -h
                    │
                    ▼
                Parse output
                    │
                    ▼
                Update UI (main thread)
```

### Model Management Flow

```
ModelManagerDialog
    │
    ├─► Select Node
    │       │
    │       ▼
    │   Refresh installed models
    │       │
    │       ├─► If local: OllamaClient.list_models()
    │       └─► If remote: SSHClient.get_ollama_models()
    │
    ├─► Pull Model
    │       │
    │       ├─► If local: OllamaClient.pull_model()
    │       │       └─► HTTP POST → /api/pull
    │       │
    │       └─► If remote: SSHClient.pull_ollama_model()
    │               └─► SSH execute: ollama pull <model>
    │
    └─► Remove Model
            │
            ├─► If local: OllamaClient.delete_model()
            │       └─► HTTP DELETE → /api/delete
            │
            └─► If remote: SSHClient.remove_ollama_model()
                    └─► SSH execute: ollama rm <model>
```

## Communication Protocols

### SSH Communication

All worker node communication uses SSH with key-based authentication:

```
Controller Pi                     Worker Pi
     │                                │
     ├─► SSH Connect (port 22) ──────►│
     │◄─── Authentication ────────────┤
     │                                │
     ├─► Execute Command ────────────►│
     │                                ├─► Run command
     │                                ├─► Capture output
     │◄─── stdout/stderr/exit_code ───┤
     │                                │
     └─► Close Connection ───────────►│
```

### Ollama API Communication

Local Ollama communication uses HTTP:

```
GUI App                          Ollama Service
    │                                │
    ├─► POST /api/chat ─────────────►│
    │   {                            ├─► Load model
    │     "model": "deepseek-r1:7b", ├─► Process prompt
    │     "messages": [...],         ├─► Generate response
    │     "stream": true             │
    │   }                            │
    │                                │
    │◄─── Stream chunks (SSE) ───────┤
    │   {"message": {"content": "..."}}
    │   {"message": {"content": "..."}}
    │   {"done": true}               │
    │                                │
```

## File Structure

```
ServerRack/
│
├── Configuration
│   └── config.yaml              # Cluster config
│
├── Documentation
│   ├── README.md               # Main documentation
│   ├── QUICKSTART.md           # Quick start guide
│   └── ARCHITECTURE.md         # This file
│
├── Scripts
│   ├── setup.sh                # Initial setup
│   ├── deploy.sh               # Deploy to workers
│   ├── run.sh                  # Run application
│   ├── make_executable.sh      # Make scripts executable
│   ├── install_service.sh      # Install systemd service
│   └── test_installation.py    # Test installation
│
├── System Files
│   ├── requirements.txt        # Python dependencies
│   ├── serverrack.service      # Systemd service file
│   └── .gitignore             # Git ignore patterns
│
└── Source Code (src/)
    ├── __init__.py
    ├── gui_app.py             # Main application
    ├── config_manager.py      # Config handling
    ├── ollama_client.py       # Ollama API client
    ├── ssh_client.py          # SSH communication
    ├── resource_monitor.py    # System monitoring
    └── model_manager.py       # Model management UI
```

## Security Considerations

### SSH Key Authentication

- Uses RSA 4096-bit keys
- No password authentication
- Keys stored in `~/.ssh/id_rsa`
- Public keys in `~/.ssh/authorized_keys` on workers

### Network Security

- All communication within local network
- No external network exposure required
- SSH port configurable (default 22)
- Ollama bound to localhost only

### File Permissions

- Config file readable by user only
- SSH keys: 600 (user read/write only)
- Scripts: 755 (user rwx, others rx)

## Performance Characteristics

### Resource Usage

**GUI Application (Controller Pi):**
- Memory: ~200-300 MB (base)
- CPU: 5-15% (idle), up to 100% (during inference)
- Disk: Minimal (logs only)

**Ollama Service (per Pi):**
- Memory: 500 MB - 8 GB (depends on model)
- CPU: Up to 100% during inference
- Disk: 3-15 GB per model

### Network Bandwidth

- SSH monitoring: ~1-5 KB/s per node
- File sync: Depends on file sizes
- Model pulls: 2-8 GB per model (one-time)

### Latency

- Local Ollama query: 100-500ms first token
- SSH command execution: 50-200ms
- Resource monitoring update: ~5 seconds interval

## Scalability

### Current Limits

- Maximum nodes: Configurable (tested with 4)
- Concurrent chat sessions: 1 (single-threaded UI)
- Model switching: Requires reload
- File sync: Sequential (not parallel)

### Future Enhancements

- [ ] Parallel model inference across nodes
- [ ] Load balancing for chat queries
- [ ] Real-time log streaming
- [ ] Web-based dashboard
- [ ] Docker containerization
- [ ] Kubernetes orchestration
