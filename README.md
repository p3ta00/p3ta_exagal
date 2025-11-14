# Exegol Custom Environment Setup

Automated setup for custom tools and dotfiles in Exegol containers.

## What Gets Installed

- **Starship** - Fast prompt with pink "Exegol" indicator
- **Zellij** - Terminal multiplexer (Dracula theme)
- **Eza** - Modern ls with icons
- **Zoxide** - Smart cd replacement
- **Bat** - Syntax-highlighted cat
- **Fd** - Fast file finder
- **Ripgrep** - Fast text search
- **Git Delta** - Side-by-side git diffs
- **Yazi** - Terminal file manager (Dracula theme)
- **Impacket Prefix** - Kali-style `impacket-` prefixes for all 69 impacket tools
- **Custom aliases & functions** - All your host dotfiles

## How It Works

1. **Host Side**: `~/.exegol/my-resources/` - Persistent storage
   - `setup/` - Config files and scripts
   - `bin/` - Precompiled binaries (auto-added to PATH)
   - `tools/windows/` - Custom Windows tools
   - `tools/linux/` - Custom Linux tools

2. **Container Side**: Mounted at `/opt/my-resources/`
   - `load_user_setup.sh` runs on container startup
   - Installs all tools (~10 seconds)
   - Copies custom tools to `/opt/resources/` (1745 files in 0.375s with rsync)
   - Creates Kali-style `impacket-` prefixes (e.g., `impacket-secretsdump`, `impacket-psexec`)
   - Sources your zshrc with all aliases

3. **Custom Tools**: Stored in `my-resources/tools/` and automatically copied to `/opt/resources/` on startup

## Installation

```bash
git clone <your-repo-url>
cd exegol
./install.sh
```

This will:
- Set up `~/.exegol/my-resources/` directory structure
- Copy all setup scripts and configs from the `configs/` directory
- Configure Exegol to load your setup on container start
- Tools will be downloaded on first container startup (~10 seconds)

## Usage

```bash
# Start any Exegol container
exegol start my-pentest full

# Your custom environment loads automatically (~10 seconds)
# Prompt shows: Exegol ➜ ~ 𝘹
```

## Adding Custom Tools

```bash
# Add Windows tools (executables, scripts)
sudo cp tool.exe ~/.exegol/my-resources/tools/windows/

# Add Linux tools (binaries, scripts)
sudo cp linux_tool ~/.exegol/my-resources/tools/linux/

# Tools automatically copied to /opt/resources/ on container startup
```

## Impacket Tools - Kali-Style Prefix

All 69 impacket tools are automatically available with the `impacket-` prefix, just like Kali Linux:

```bash
# Instead of:
smbexec.py
secretsdump.py
psexec.py

# Use:
impacket-smbexec
impacket-secretsdump
impacket-psexec
impacket-GetNPUsers
impacket-wmiexec
# ... and 64 more tools
```

This happens automatically on container startup via `setup_impacket_prefix.sh`.

## Repository Structure

```
exegol/
├── install.sh                  # Run this to install
├── load_user_setup.sh          # Runs in containers (main script)
├── copy_tools.sh               # Copies custom tools (rsync, 0.375s)
├── setup_impacket_prefix.sh    # Creates impacket- prefixes (Kali-style)
├── setup-dotfiles.sh           # Optional dotfiles sync
└── configs/                    # Your configs (customize these!)
    ├── zshrc                   # Shell aliases & functions
    ├── starship.toml           # Prompt configuration
    └── zellij/                 # Terminal multiplexer config
```

## Installed Structure (Host)

```
~/.exegol/my-resources/
├── bin/                           # Precompiled binaries (auto PATH)
├── tools/
│   ├── windows/                  # Windows tools → /opt/resources/windows/
│   └── linux/                    # Linux tools → /opt/resources/linux/
└── setup/
    ├── load_user_setup.sh        # Runs on container startup
    ├── copy_tools.sh             # Copies tools to /opt/resources/
    ├── setup_impacket_prefix.sh  # Creates impacket- prefixes
    ├── zsh/zshrc                 # Your custom aliases
    ├── starship/                 # Prompt config
    ├── yazi/                     # File manager config + Dracula theme
    └── zellij/                   # Terminal multiplexer config
```

## Requirements

- Exegol installed
- Linux host system
- curl, git, tar

## Speed

- First run: ~10 seconds (downloads precompiled binaries)
- Subsequent runs: ~2 seconds (binaries cached)
