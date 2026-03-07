#!/bin/bash
# ==========================================================================
# Exegol GPU Setup (Container-Side)
# ==========================================================================
# Runs inside the Exegol container on first start.
# Auto-detects mounted NVIDIA driver version and configures OpenCL/CUDA.
# Optionally reads gpu-host.conf (written by install-gpu.sh) for version
# matching against the host driver.
#
# Requires: container started with  exegol start <name> <image> --gpu
# ==========================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CONF="/opt/my-resources/setup/gpu/gpu-host.conf"
MARKER="/tmp/.gpu-setup-done"

[ -f "$MARKER" ] && exit 0

echo -e "${BLUE}[*]${NC} Starting NVIDIA GPU setup..."

# --------------------------------------------------------------------------
# 1. Load expected host config (if present)
# --------------------------------------------------------------------------
EXPECTED_DRIVER=""
EXPECTED_CUDA=""
EXPECTED_GPU=""

if [ -f "$CONF" ]; then
    source "$CONF"
    EXPECTED_DRIVER="$HOST_DRIVER_VERSION"
    EXPECTED_CUDA="$HOST_CUDA_VERSION"
    EXPECTED_GPU="$HOST_GPU_NAME"
    echo -e "${BLUE}[*]${NC} Host config: ${EXPECTED_GPU} | driver ${EXPECTED_DRIVER} | CUDA ${EXPECTED_CUDA}"
else
    echo -e "${YELLOW}[~]${NC} No gpu-host.conf found, will auto-detect from mounted libs"
fi

# --------------------------------------------------------------------------
# 2. Detect mounted driver version
# --------------------------------------------------------------------------
MOUNTED_DRIVER=""

# Method 1: nvidia-smi (most reliable if available)
if command -v nvidia-smi &>/dev/null; then
    MOUNTED_DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 | tr -d '[:space:]')
fi

# Method 2: scan for versioned libcuda.so
if [ -z "$MOUNTED_DRIVER" ]; then
    for search_dir in /usr/lib/x86_64-linux-gnu /usr/lib /usr/local/nvidia/lib64 /usr/lib64; do
        ver=$(ls "${search_dir}/libcuda.so."[0-9]* 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
        if [ -n "$ver" ]; then
            MOUNTED_DRIVER="$ver"
            break
        fi
    done
fi

# Method 3: scan libnvidia-ml.so
if [ -z "$MOUNTED_DRIVER" ]; then
    for search_dir in /usr/lib/x86_64-linux-gnu /usr/lib /usr/local/nvidia/lib64 /usr/lib64; do
        ver=$(ls "${search_dir}/libnvidia-ml.so."[0-9]* 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
        if [ -n "$ver" ]; then
            MOUNTED_DRIVER="$ver"
            break
        fi
    done
fi

if [ -z "$MOUNTED_DRIVER" ]; then
    echo -e "${RED}[-]${NC} No NVIDIA driver libraries found in container."
    echo -e "${RED}[-]${NC} Start container with: exegol start <name> <image> --gpu"
    exit 1
fi

echo -e "${GREEN}[+]${NC} Mounted driver version: ${MOUNTED_DRIVER}"

# --------------------------------------------------------------------------
# 3. Version match check
# --------------------------------------------------------------------------
if [ -n "$EXPECTED_DRIVER" ] && [ "$EXPECTED_DRIVER" != "$MOUNTED_DRIVER" ]; then
    echo -e "${RED}[!]${NC} DRIVER MISMATCH: host=${EXPECTED_DRIVER} container=${MOUNTED_DRIVER}"
    echo -e "${RED}[!]${NC} Run install-gpu.sh on the host to update gpu-host.conf"
    echo -e "${YELLOW}[~]${NC} Proceeding with mounted version ${MOUNTED_DRIVER}..."
fi

# --------------------------------------------------------------------------
# 4. Find where nvidia libs live in this container
# --------------------------------------------------------------------------
NVIDIA_LIB_DIR=""
for dir in /usr/lib/x86_64-linux-gnu /usr/lib /usr/local/nvidia/lib64 /usr/lib64; do
    if [ -f "${dir}/libcuda.so.${MOUNTED_DRIVER}" ] || [ -f "${dir}/libnvidia-ml.so.${MOUNTED_DRIVER}" ]; then
        NVIDIA_LIB_DIR="$dir"
        break
    fi
done

if [ -z "$NVIDIA_LIB_DIR" ]; then
    echo -e "${RED}[-]${NC} Could not locate nvidia library directory"
    exit 1
fi

echo -e "${BLUE}[*]${NC} NVIDIA libs located in: ${NVIDIA_LIB_DIR}"

# --------------------------------------------------------------------------
# 5. Create/fix symlinks for the detected driver version
# --------------------------------------------------------------------------
echo -e "${BLUE}[*]${NC} Fixing library symlinks for driver ${MOUNTED_DRIVER}..."

declare -a NVIDIA_LIBS=(
    "libcuda.so"
    "libcudadebugger.so"
    "libnvidia-ml.so"
    "libnvidia-opencl.so"
    "libnvidia-ptxjitcompiler.so"
    "libnvidia-nvvm.so"
    "libnvidia-gpucomp.so"
    "libnvidia-allocator.so"
    "libnvidia-vulkan-producer.so"
    "libnvidia-encode.so"
    "libnvidia-opticalflow.so"
)

for lib in "${NVIDIA_LIBS[@]}"; do
    versioned="${NVIDIA_LIB_DIR}/${lib}.${MOUNTED_DRIVER}"
    so1="${NVIDIA_LIB_DIR}/${lib}.1"
    so="${NVIDIA_LIB_DIR}/${lib}"

    if [ -f "$versioned" ]; then
        # .so.1 -> .so.<version>
        if [ ! -e "$so1" ] || [ "$(readlink -f "$so1")" != "$versioned" ]; then
            ln -sf "$versioned" "$so1"
        fi
        # .so -> .so.1
        if [ ! -e "$so" ] || [ "$(readlink -f "$so")" != "$(readlink -f "$so1")" ]; then
            ln -sf "$so1" "$so"
        fi
    fi
done

ldconfig 2>/dev/null
echo -e "${GREEN}[+]${NC} Library symlinks configured"

# --------------------------------------------------------------------------
# 6. OpenCL ICD setup
# --------------------------------------------------------------------------
echo -e "${BLUE}[*]${NC} Configuring OpenCL ICD..."

mkdir -p /etc/OpenCL/vendors

# Remove stale ICD files
rm -f /etc/OpenCL/vendors/nvidia*.icd

if [ -f "${NVIDIA_LIB_DIR}/libnvidia-opencl.so.1" ]; then
    echo "${NVIDIA_LIB_DIR}/libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd
    echo -e "${GREEN}[+]${NC} OpenCL ICD: ${NVIDIA_LIB_DIR}/libnvidia-opencl.so.1"
elif [ -f "${NVIDIA_LIB_DIR}/libnvidia-opencl.so.${MOUNTED_DRIVER}" ]; then
    echo "${NVIDIA_LIB_DIR}/libnvidia-opencl.so.${MOUNTED_DRIVER}" > /etc/OpenCL/vendors/nvidia.icd
    echo -e "${GREEN}[+]${NC} OpenCL ICD: ${NVIDIA_LIB_DIR}/libnvidia-opencl.so.${MOUNTED_DRIVER}"
else
    echo -e "${YELLOW}[~]${NC} libnvidia-opencl not found, hashcat may use CUDA backend instead"
fi

# --------------------------------------------------------------------------
# 7. Install OpenCL packages (Exegol containers are Debian-based)
# --------------------------------------------------------------------------
if command -v apt-get &>/dev/null; then
    echo -e "${BLUE}[*]${NC} Installing OpenCL packages..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq 2>/dev/null
    apt-get install -y -qq ocl-icd-libopencl1 clinfo 2>/dev/null
    echo -e "${GREEN}[+]${NC} OpenCL packages installed"
fi

# --------------------------------------------------------------------------
# 8. Environment variables
# --------------------------------------------------------------------------
cat > /etc/profile.d/gpu-env.sh << GPUENV
# NVIDIA GPU environment - auto-configured by setup-gpu.sh
# Driver: ${MOUNTED_DRIVER} | Lib dir: ${NVIDIA_LIB_DIR}
export NVIDIA_VISIBLE_DEVICES=all
export NVIDIA_DRIVER_CAPABILITIES=compute,utility
export LD_LIBRARY_PATH="${NVIDIA_LIB_DIR}\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
GPUENV
chmod +x /etc/profile.d/gpu-env.sh
source /etc/profile.d/gpu-env.sh

if ! grep -q "gpu-env.sh" /root/.zshrc 2>/dev/null; then
    printf '\n[ -f /etc/profile.d/gpu-env.sh ] && source /etc/profile.d/gpu-env.sh\n' >> /root/.zshrc
fi

# --------------------------------------------------------------------------
# 9. Helper aliases
# --------------------------------------------------------------------------
cat > /etc/profile.d/gpu-aliases.sh << 'GPUALIAS'
alias gpu-info='nvidia-smi 2>/dev/null || echo "nvidia-smi not available"'
alias gpu-watch='watch -n 1 nvidia-smi'
alias gpu-test='hashcat -b -d 1 -m 0'
alias gpu-check='echo "=== clinfo ===" && clinfo --list 2>/dev/null; echo "=== hashcat ===" && hashcat -I 2>/dev/null | head -30'
GPUALIAS
chmod +x /etc/profile.d/gpu-aliases.sh

# --------------------------------------------------------------------------
# 10. Verify
# --------------------------------------------------------------------------
echo -e "${BLUE}[*]${NC} Verifying GPU setup..."

if command -v nvidia-smi &>/dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    GPU_MEM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1)
    echo -e "${GREEN}[+]${NC} nvidia-smi: ${GPU_NAME} (${GPU_MEM})"
fi

if command -v clinfo &>/dev/null; then
    NDEV=$(clinfo --list 2>/dev/null | grep -ci "gpu\|nvidia" || echo "0")
    echo -e "${GREEN}[+]${NC} clinfo: ${NDEV} NVIDIA device(s)"
fi

if command -v hashcat &>/dev/null; then
    if hashcat -I 2>/dev/null | grep -qi "nvidia\|cuda\|opencl"; then
        echo -e "${GREEN}[+]${NC} hashcat GPU backend available"
    else
        echo -e "${YELLOW}[~]${NC} hashcat may not detect GPU yet - try: hashcat -I"
    fi
fi

touch "$MARKER"
echo -e "${GREEN}[+]${NC} GPU setup complete (driver ${MOUNTED_DRIVER})"
