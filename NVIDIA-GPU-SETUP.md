# NVIDIA GPU Setup - Permanent Configuration

This document describes the permanent fixes applied to ensure NVIDIA GPU support works consistently.

## Permanent Changes Made

### 1. Docker Daemon Configuration (`/etc/docker/daemon.json`)
```json
{
    "log-driver": "json-file",
    "log-opts": {
        "max-file": "5",
        "max-size": "10m"
    },
    "runtimes": {
        "nvidia": {
            "args": [],
            "path": "nvidia-container-runtime"
        }
    },
    "features": {
        "cdi": true
    }
}
```
**Purpose**: Explicitly enables CDI (Container Device Interface) support in Docker.

### 2. Docker Compose Configuration (`docker-compose.yml`)
**Changed from legacy approach:**
```yaml
# OLD (problematic)
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```

**To CDI approach:**
```yaml
# NEW (working)
devices:
  - nvidia.com/gpu=0
```
**Purpose**: Uses modern CDI device specification instead of legacy `--gpus` flag.

### 3. Systemd Services for Automatic Setup
Created two services to ensure GPU setup survives reboots:

#### `/etc/systemd/system/nvidia-cdi-generate.service`
```ini
[Unit]
Description=Generate NVIDIA Container Device Interface
After=multi-user.target
Wants=nvidia-persistenced.service

[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
RemainAfterExit=true
User=root

[Install]
WantedBy=multi-user.target
```

#### `/etc/systemd/system/docker-nvidia-setup.service`
```ini
[Unit]
Description=Setup Docker NVIDIA Runtime
After=docker.service nvidia-cdi-generate.service
Requires=docker.service
Wants=nvidia-cdi-generate.service

[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-ctk runtime configure --runtime=docker --set-as-default=false
ExecStart=/bin/systemctl reload docker.service
RemainAfterExit=true
User=root

[Install]
WantedBy=multi-user.target
```

**Purpose**: Automatically generates CDI specs and configures Docker on boot.

### 4. Enhanced Start Script (`start_services.py`)
Added `verify_gpu_setup()` function that:
- Checks if NVIDIA runtime is available in Docker
- Verifies CDI devices are generated
- Tests actual GPU access before starting services
- Falls back to CPU profile if GPU setup fails

## Root Cause Analysis
The recurring issue was caused by:
1. **Legacy `--gpus` approach**: Caused `nvidia-container-cli: ldcache error`
2. **Missing CDI specs**: Required manual regeneration after reboots
3. **No verification**: Script would try to start GPU services without checking if GPU was accessible

## Verification Commands
To check if the setup is working:

```bash
# Check Docker NVIDIA runtime
docker info | grep nvidia

# Check CDI devices
nvidia-ctk cdi list

# Test GPU access
docker run --rm --device nvidia.com/gpu=0 ubuntu:22.04 ls -la /dev/nvidia*

# Check Ollama GPU detection
docker logs ollama | grep -i "inference compute"
```

## Manual Recovery (if needed)
If issues persist, run:
```bash
sudo systemctl start nvidia-cdi-generate.service
sudo systemctl start docker-nvidia-setup.service
sudo systemctl restart docker
```

## Benefits of This Setup
1. **Persistent**: Survives system reboots
2. **Self-healing**: Automatically regenerates CDI specs
3. **Graceful fallback**: Falls back to CPU if GPU fails
4. **Modern approach**: Uses CDI instead of deprecated `--gpus`
5. **Verification**: Tests GPU access before starting services