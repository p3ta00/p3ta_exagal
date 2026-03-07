# Exegol GPU Passthrough

NVIDIA GPU passthrough for [Exegol](https://exegol.readthedocs.io/) containers. Enables GPU-accelerated cracking with hashcat, john, and other tools.

Auto-detects your host NVIDIA driver version, writes a config file, and ensures the container environment matches - fixing library symlinks, OpenCL ICD, and CUDA paths automatically.

## Supported Host Distros

| Family | Distros |
|--------|---------|
| **Arch** | Arch, CachyOS, EndeavourOS, Manjaro, Garuda |
| **Fedora** | Fedora, Nobara, RHEL, Rocky, Alma |
| **Debian** | Debian, Ubuntu, Kali, Parrot, Pop!_OS, Mint |

## Prerequisites

1. **NVIDIA drivers** installed on host
2. **Docker** installed

The script automatically installs **nvidia-container-toolkit** and configures the **Docker NVIDIA runtime** if they're missing.

## Quick Start

```bash
# Clone
git clone https://github.com/p3ta00/exegol-gpu.git
cd exegol-gpu

# Run on your HOST machine
./install-gpu.sh
```

This will:
1. Detect your GPU model, driver version, CUDA version, compute capability
2. Install nvidia-container-toolkit if missing (via pacman/dnf/apt)
3. Configure Docker NVIDIA runtime and restart Docker if needed
4. Write `gpu-host.conf` to `~/.exegol/my-resources/setup/gpu/`
5. Copy `setup-gpu.sh` to `~/.exegol/my-resources/setup/gpu/`
6. Patch `load_user_setup.sh` to auto-run GPU setup on every new container
7. Add `--gpu` wrapper to your shell (`~/.zshrc` or `~/.bashrc`)

```bash
# Start Exegol with GPU
exegol start mybox full --gpu
```

GPU setup runs automatically on first container start.

## Verify Inside Container

```bash
gpu-check     # clinfo + hashcat device info
gpu-test      # hashcat MD5 benchmark
gpu-info      # nvidia-smi
gpu-watch     # live nvidia-smi monitor
```

## How It Works

### Host Side (`install-gpu.sh`)

- Detects distro family (Arch/Fedora/Debian) via `/etc/os-release`
- Queries `nvidia-smi` for GPU name, driver version, CUDA version, compute cap, VRAM
- Finds host nvidia lib path (`/usr/lib` on Arch, `/usr/lib/x86_64-linux-gnu` on Debian, `/usr/lib64` on Fedora)
- Installs nvidia-container-toolkit if missing (pacman/dnf/apt)
- Configures Docker NVIDIA runtime and restarts Docker if needed
- Writes all detected values to `gpu-host.conf`
- Copies `setup-gpu.sh` and patches `load_user_setup.sh`
- Adds an `exegol()` shell wrapper that translates `--gpu` into `--privileged -e NVIDIA_VISIBLE_DEVICES=all -e NVIDIA_DRIVER_CAPABILITIES=compute,utility`
- No hardcoded driver versions — survives driver updates without changes

### Container Side (`setup-gpu.sh`)

- Reads `gpu-host.conf` to know expected driver version
- Auto-detects the actual mounted driver version (nvidia-smi or scanning versioned `.so` files)
- **Warns on version mismatch** between host config and mounted libs
- Locates nvidia lib directory inside the container (handles Arch/Fedora/Debian path remapping by nvidia-container-toolkit)
- Creates/fixes all library symlinks for the specific driver version:
  - `libcuda.so`, `libnvidia-ml.so`, `libnvidia-opencl.so`, `libnvidia-ptxjitcompiler.so`, etc.
- Configures OpenCL ICD vendor file
- Installs `ocl-icd-libopencl1` and `clinfo`
- Sets `LD_LIBRARY_PATH` and NVIDIA environment variables
- Verifies with nvidia-smi, clinfo, and hashcat

## After Driver Updates

```bash
# Re-run on host to update the config
./install-gpu.sh
```

Next time a container starts, the container-side script will pick up the new driver version. If there's a mismatch with a running container, it warns but proceeds with whatever driver is actually mounted.

## Files

```
exegol-gpu/
├── install-gpu.sh     # Run on HOST - detects GPU, writes config, patches startup
├── setup-gpu.sh       # Runs INSIDE container - matches driver, fixes libs, OpenCL
└── README.md
```

`gpu-host.conf` is generated at runtime and contains your local GPU info (not committed).

## Troubleshooting

### "No NVIDIA driver libraries found in container"
Container wasn't started with GPU passthrough. Use: `exegol start <name> <image> --gpu`

### nvidia-container-toolkit install fails
The script auto-installs via pacman/dnf/apt. If it fails, check your package manager and internet connection. You can also install manually per [NVIDIA docs](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).

### "DRIVER MISMATCH" warning
Your host driver was updated since the last `install-gpu.sh` run. Re-run it on the host.

### hashcat doesn't see GPU
Try `hashcat -I` to check backends. If OpenCL isn't listed, run `gpu-check` to debug. The CUDA backend may work even without OpenCL.

## License

MIT
