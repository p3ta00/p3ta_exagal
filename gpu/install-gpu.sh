#!/bin/bash
# ==========================================================================
# Exegol GPU Host Setup
# ==========================================================================
# Run this on your HOST machine to:
#   1. Detect NVIDIA driver version, CUDA version, GPU model
#   2. Verify nvidia-container-toolkit is installed
#   3. Write gpu-host.conf so the container script can match versions
#   4. Patch load_user_setup.sh to call setup-gpu.sh on container start
#
# Supports: Arch/CachyOS/EndeavourOS, Fedora/RHEL/Nobara,
#           Debian/Ubuntu/Kali/ParrotOS
# ==========================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Where Exegol my-resources lives on the host
EXEGOL_RESOURCES="${HOME}/.exegol/my-resources"
GPU_DIR="${EXEGOL_RESOURCES}/setup/gpu"
CONF="${GPU_DIR}/gpu-host.conf"
SETUP_SCRIPT="${EXEGOL_RESOURCES}/setup/load_user_setup.sh"

# --------------------------------------------------------------------------
# 0. Detect host distro family
# --------------------------------------------------------------------------
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            arch|cachyos|endeavouros|manjaro|garuda|artix)
                DISTRO_FAMILY="arch"
                ;;
            fedora|rhel|centos|rocky|alma|nobara)
                DISTRO_FAMILY="fedora"
                ;;
            debian|ubuntu|pop|mint|kali|parrot)
                DISTRO_FAMILY="debian"
                ;;
            opensuse*|sles)
                DISTRO_FAMILY="suse"
                ;;
            *)
                DISTRO_FAMILY="unknown"
                ;;
        esac
        DISTRO_NAME="${PRETTY_NAME:-$ID}"
    else
        DISTRO_FAMILY="unknown"
        DISTRO_NAME="Unknown"
    fi
    echo -e "${BLUE}[*]${NC} Detected distro: ${DISTRO_NAME} (family: ${DISTRO_FAMILY})"
}

# --------------------------------------------------------------------------
# 1. Detect NVIDIA driver + GPU
# --------------------------------------------------------------------------
detect_gpu() {
    echo -e "${BLUE}[*]${NC} Detecting NVIDIA GPU..."

    if ! command -v nvidia-smi &>/dev/null; then
        echo -e "${RED}[-]${NC} nvidia-smi not found. Install NVIDIA drivers first."
        case "$DISTRO_FAMILY" in
            arch)   echo -e "${BLUE}[*]${NC} Try: sudo pacman -S nvidia nvidia-utils" ;;
            fedora) echo -e "${BLUE}[*]${NC} Try: sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda" ;;
            debian) echo -e "${BLUE}[*]${NC} Try: sudo apt install nvidia-driver-XXX" ;;
        esac
        exit 1
    fi

    HOST_GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 | xargs)
    HOST_DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 | xargs)
    HOST_COMPUTE_CAP=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | head -1 | xargs)
    HOST_GPU_MEM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1 | xargs)

    # CUDA version from nvidia-container-cli or nvidia-smi
    HOST_CUDA_VERSION=""
    if command -v nvidia-container-cli &>/dev/null; then
        HOST_CUDA_VERSION=$(nvidia-container-cli info 2>/dev/null | grep "CUDA" | awk '{print $NF}')
    fi
    if [ -z "$HOST_CUDA_VERSION" ]; then
        HOST_CUDA_VERSION=$(nvidia-smi 2>/dev/null | grep -oP 'CUDA Version: \K[\d.]+')
    fi

    if [ -z "$HOST_DRIVER_VERSION" ]; then
        echo -e "${RED}[-]${NC} Could not detect NVIDIA driver version"
        exit 1
    fi

    echo -e "${GREEN}[+]${NC} GPU:     ${HOST_GPU_NAME}"
    echo -e "${GREEN}[+]${NC} Driver:  ${HOST_DRIVER_VERSION}"
    echo -e "${GREEN}[+]${NC} CUDA:    ${HOST_CUDA_VERSION}"
    echo -e "${GREEN}[+]${NC} Compute: ${HOST_COMPUTE_CAP}"
    echo -e "${GREEN}[+]${NC} VRAM:    ${HOST_GPU_MEM}"

    # Detect host nvidia lib path (varies by distro)
    # Arch/CachyOS: /usr/lib
    # Debian/Ubuntu: /usr/lib/x86_64-linux-gnu
    # Fedora/RHEL:   /usr/lib64
    HOST_NVIDIA_LIB_DIR=""
    for dir in /usr/lib/x86_64-linux-gnu /usr/lib /usr/lib64 /usr/local/nvidia/lib64; do
        if [ -f "${dir}/libcuda.so.${HOST_DRIVER_VERSION}" ]; then
            HOST_NVIDIA_LIB_DIR="$dir"
            break
        fi
    done
    echo -e "${BLUE}[*]${NC} Host lib dir: ${HOST_NVIDIA_LIB_DIR:-not found (nvidia-container-toolkit handles mapping)}"
}

# --------------------------------------------------------------------------
# 2. Check nvidia-container-toolkit
# --------------------------------------------------------------------------
check_container_toolkit() {
    echo ""
    echo -e "${BLUE}[*]${NC} Checking nvidia-container-toolkit..."

    if command -v nvidia-container-cli &>/dev/null; then
        NCT_VERSION=$(nvidia-container-cli --version 2>/dev/null | head -1)
        echo -e "${GREEN}[+]${NC} nvidia-container-toolkit installed: ${NCT_VERSION}"
        return 0
    fi

    echo -e "${RED}[-]${NC} nvidia-container-toolkit NOT installed."
    echo ""

    case "$DISTRO_FAMILY" in
        arch)
            echo -e "${BLUE}[*]${NC} Install on Arch/CachyOS:"
            echo -e "    ${YELLOW}sudo pacman -S nvidia-container-toolkit${NC}"
            echo -e "    ${YELLOW}sudo nvidia-ctk runtime configure --runtime=docker${NC}"
            echo -e "    ${YELLOW}sudo systemctl restart docker${NC}"
            ;;
        fedora)
            echo -e "${BLUE}[*]${NC} Install on Fedora:"
            echo -e "    ${YELLOW}curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo${NC}"
            echo -e "    ${YELLOW}sudo dnf install -y nvidia-container-toolkit${NC}"
            echo -e "    ${YELLOW}sudo nvidia-ctk runtime configure --runtime=docker${NC}"
            echo -e "    ${YELLOW}sudo systemctl restart docker${NC}"
            ;;
        debian)
            echo -e "${BLUE}[*]${NC} Install on Debian/Ubuntu:"
            echo -e "    ${YELLOW}curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg${NC}"
            echo -e "    ${YELLOW}curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list${NC}"
            echo -e "    ${YELLOW}sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit${NC}"
            echo -e "    ${YELLOW}sudo nvidia-ctk runtime configure --runtime=docker${NC}"
            echo -e "    ${YELLOW}sudo systemctl restart docker${NC}"
            ;;
        *)
            echo -e "${YELLOW}[~]${NC} See: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html"
            ;;
    esac

    echo ""
    echo -e "${YELLOW}[~]${NC} After installing, re-run this script."
    return 1
}

# --------------------------------------------------------------------------
# 3. Verify docker runtime is configured
# --------------------------------------------------------------------------
check_docker_runtime() {
    echo ""
    echo -e "${BLUE}[*]${NC} Checking Docker NVIDIA runtime..."

    if ! command -v docker &>/dev/null; then
        echo -e "${YELLOW}[~]${NC} Docker not found - skipping runtime check"
        return
    fi

    DOCKER_RUNTIMES=$(docker info 2>/dev/null | grep -i "runtimes" || echo "")
    if echo "$DOCKER_RUNTIMES" | grep -qi "nvidia"; then
        echo -e "${GREEN}[+]${NC} Docker NVIDIA runtime configured"
    else
        echo -e "${YELLOW}[~]${NC} Docker NVIDIA runtime not detected."
        echo -e "${YELLOW}[~]${NC} Run: sudo nvidia-ctk runtime configure --runtime=docker && sudo systemctl restart docker"
    fi
}

# --------------------------------------------------------------------------
# 4. Write gpu-host.conf
# --------------------------------------------------------------------------
write_config() {
    echo ""
    echo -e "${BLUE}[*]${NC} Writing GPU config..."

    mkdir -p "$GPU_DIR"

    cat > "$CONF" << HOSTCONF
# Auto-generated by install-gpu.sh on $(date -Iseconds)
# Re-run install-gpu.sh after driver updates to refresh this file.

HOST_DISTRO_FAMILY="${DISTRO_FAMILY}"
HOST_DISTRO_NAME="${DISTRO_NAME}"
HOST_GPU_NAME="${HOST_GPU_NAME}"
HOST_DRIVER_VERSION="${HOST_DRIVER_VERSION}"
HOST_CUDA_VERSION="${HOST_CUDA_VERSION}"
HOST_COMPUTE_CAP="${HOST_COMPUTE_CAP}"
HOST_GPU_MEM="${HOST_GPU_MEM}"
HOST_NVIDIA_LIB_DIR="${HOST_NVIDIA_LIB_DIR}"
HOSTCONF

    echo -e "${GREEN}[+]${NC} Config written to ${CONF}"
}

# --------------------------------------------------------------------------
# 5. Copy setup-gpu.sh to my-resources
# --------------------------------------------------------------------------
copy_container_script() {
    echo ""
    echo -e "${BLUE}[*]${NC} Copying container-side GPU script..."

    if [ -f "${SCRIPT_DIR}/setup-gpu.sh" ]; then
        cp "${SCRIPT_DIR}/setup-gpu.sh" "${GPU_DIR}/setup-gpu.sh"
        chmod +x "${GPU_DIR}/setup-gpu.sh"
        echo -e "${GREEN}[+]${NC} setup-gpu.sh copied to ${GPU_DIR}/"
    else
        echo -e "${RED}[-]${NC} setup-gpu.sh not found next to this script (${SCRIPT_DIR}/)"
        echo -e "${RED}[-]${NC} Copy it manually to ${GPU_DIR}/setup-gpu.sh"
    fi
}

# --------------------------------------------------------------------------
# 6. Patch load_user_setup.sh
# --------------------------------------------------------------------------
patch_setup_script() {
    echo ""
    echo -e "${BLUE}[*]${NC} Patching load_user_setup.sh..."

    if [ ! -f "$SETUP_SCRIPT" ]; then
        echo -e "${YELLOW}[~]${NC} ${SETUP_SCRIPT} not found - skipping patch"
        echo -e "${YELLOW}[~]${NC} Add this to your load_user_setup.sh manually:"
        echo ""
        echo '    if [ -f /opt/my-resources/setup/gpu/setup-gpu.sh ]; then'
        echo '        /opt/my-resources/setup/gpu/setup-gpu.sh || echo -e "${RED}[-]${NC} GPU setup had errors, continuing..."'
        echo '    fi'
        return 0
    fi

    # Already patched?
    if grep -q "setup/gpu/setup-gpu.sh" "$SETUP_SCRIPT"; then
        echo -e "${YELLOW}[~]${NC} Already patched with setup-gpu.sh call"
    else
        # Remove trailing "First-time setup complete" line
        sed -i '/echo.*First-time setup complete/d' "$SETUP_SCRIPT"

        # Remove trailing blank lines
        sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$SETUP_SCRIPT"

        # Append the GPU setup block + completion message
        cat >> "$SETUP_SCRIPT" << 'GPUBLOCK'

# ============================================================================
# NVIDIA GPU Setup (driver-aware, auto-detected)
# ============================================================================
if [ -f /opt/my-resources/setup/gpu/setup-gpu.sh ]; then
    /opt/my-resources/setup/gpu/setup-gpu.sh || echo -e "${RED}[-]${NC} GPU setup had errors, continuing..."
fi

echo -e "${GREEN}[+]${NC} First-time setup complete!"
GPUBLOCK

        echo -e "${GREEN}[+]${NC} load_user_setup.sh patched"
    fi

    # Remove old inline NVIDIA block if present (from older setups)
    if grep -q "NVIDIA GPU Support (OpenCL ICD for hashcat" "$SETUP_SCRIPT"; then
        echo -e "${BLUE}[*]${NC} Removing old inline NVIDIA block..."
        # Use python for reliable multi-line removal, fallback to sed
        python3 -c "
import re
with open('$SETUP_SCRIPT') as f: text = f.read()
text = re.sub(r'# =+\n# NVIDIA GPU Support \(OpenCL ICD.*?\nfi\n*', '', text, flags=re.DOTALL)
with open('$SETUP_SCRIPT','w') as f: f.write(text)
" 2>/dev/null || sed -i '/NVIDIA GPU Support (OpenCL ICD/,/^fi$/d' "$SETUP_SCRIPT"
        echo -e "${GREEN}[+]${NC} Old inline block removed"
    fi
}

# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------
echo "=========================================="
echo "  Exegol GPU Host Setup"
echo "=========================================="
echo ""

detect_distro
detect_gpu
check_container_toolkit || exit 1
check_docker_runtime
write_config
copy_container_script
patch_setup_script

echo ""
echo "=========================================="
echo -e "${GREEN}[+]${NC} Setup complete!"
echo "=========================================="
echo ""
echo "Start Exegol with GPU:"
echo -e "  ${YELLOW}exegol start <name> <image> --gpu${NC}"
echo ""
echo "After driver updates, re-run this script to update gpu-host.conf."
echo ""
