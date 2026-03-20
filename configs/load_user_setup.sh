#!/bin/bash

# This script will be executed on the first startup of each new container with the "my-resources" feature enabled.

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# ============================================================================
# Install CLI Tools (starship, eza, bat, fd, zoxide, delta, zellij)
# ============================================================================
if [ -f /opt/my-resources/setup/install-tools.sh ]; then
    /opt/my-resources/setup/install-tools.sh || echo -e "${RED}[-]${NC} install-tools.sh had errors, continuing..."
fi

# ============================================================================
# UwU Toolkit Setup
# ============================================================================
UWU_DIR="/opt/my-resources/bin/uwu-toolkit"
if [ -d "$UWU_DIR" ]; then
    echo -e "${BLUE}[*]${NC} Setting up UwU Toolkit..."
    chmod +x "$UWU_DIR/uwu" "$UWU_DIR/uwu.py" "$UWU_DIR/uwu_dashboard" 2>/dev/null
    ln -sf "$UWU_DIR/uwu" /usr/local/bin/uwu
    ln -sf "$UWU_DIR/uwu_dashboard" /usr/local/bin/uwu-dashboard

    # Install Python dependencies
    pip3 install prompt_toolkit rich requests pyyaml donut-shellcode 2>/dev/null || true

    # Fix donut execstack issue (glibc 2.38+ blocks executable stack)
    python3 -c "
import struct, glob
for so in glob.glob('/usr/local/lib/python*/dist-packages/donut*.so') + glob.glob('/root/.pyenv/versions/*/lib/python*/site-packages/donut*.so'):
    with open(so,'rb') as f: data=bytearray(f.read())
    e_phoff=struct.unpack_from('<Q',data,32)[0]; e_phentsize=struct.unpack_from('<H',data,54)[0]; e_phnum=struct.unpack_from('<H',data,56)[0]
    for i in range(e_phnum):
        off=e_phoff+i*e_phentsize; p_type=struct.unpack_from('<I',data,off)[0]
        if p_type==0x6474e551:
            p_flags=struct.unpack_from('<I',data,off+4)[0]
            if p_flags&1: struct.pack_into('<I',data,off+4,p_flags&~1); open(so,'wb').write(data); print(f'[+] Patched {so}')
            break
" 2>/dev/null || true

    echo -e "${GREEN}[+]${NC} UwU Toolkit installed - run 'uwu' to start"
fi

# ============================================================================
# Donut shellcode generator CLI
# ============================================================================
if ! command -v donut &>/dev/null; then
    echo -e "${BLUE}[*]${NC} Installing donut CLI wrapper..."
    pip3 install donut-shellcode 2>/dev/null || true
    cat > /usr/local/bin/donut << 'DONUTEOF'
#!/usr/bin/env python3
import sys, getopt, donut
def usage():
    print("Usage: donut -i <input> [-o output] [-a arch] [-b bypass] [-p params]")
    sys.exit(1)
if len(sys.argv) < 2: usage()
try: opts, args = getopt.getopt(sys.argv[1:], "i:o:a:b:p:h")
except getopt.GetoptError: usage()
infile = None; outfile = "loader.bin"; kwargs = {}
for o, v in opts:
    if o == "-i": infile = v
    elif o == "-o": outfile = v
    elif o == "-a": kwargs["arch"] = int(v)
    elif o == "-b": kwargs["bypass"] = int(v)
    elif o == "-p": kwargs["params"] = v
    elif o == "-h": usage()
if not infile: usage()
sc = donut.create(file=infile, **kwargs)
if sc: open(outfile, "wb").write(sc); print(f"[+] Shellcode written to {outfile} ({len(sc)} bytes)")
else: print("[-] Failed"); sys.exit(1)
DONUTEOF
    chmod +x /usr/local/bin/donut
    echo -e "${GREEN}[+]${NC} donut installed"
fi

# ============================================================================
# BloodHound CE Fix - Patch STORAGE MAIN for PostgreSQL 15 compatibility
# ============================================================================
BH_BIN="/opt/tools/BloodHound-CE/bloodhound"
if [ -f "$BH_BIN" ]; then
    if strings "$BH_BIN" | grep -q "STORAGE MAIN" 2>/dev/null; then
        echo -e "${BLUE}[*]${NC} Patching BloodHound CE for PostgreSQL 15 compatibility..."
        python3 -c "
data = open('$BH_BIN', 'rb').read()
old = b'TEXT STORAGE MAIN'
new = b'TEXT             '
if old in data:
    data = data.replace(old, new)
    open('$BH_BIN', 'wb').write(data)
    print('[+] BloodHound CE patched successfully')
else:
    print('[*] BloodHound CE already patched')
" 2>/dev/null || echo -e "${RED}[-]${NC} BloodHound CE patch failed, continuing..."
    else
        echo -e "${GREEN}[+]${NC} BloodHound CE already compatible"
    fi
fi

# ============================================================================
# BloodHound CE Database Persistence
# ============================================================================
if [ -f /opt/my-resources/setup/bloodhound/setup-bloodhound.sh ]; then
    /opt/my-resources/setup/bloodhound/setup-bloodhound.sh || echo -e "${RED}[-]${NC} BloodHound CE restore had errors, continuing..."
fi

# ============================================================================
# Firefox Profile Persistence
# ============================================================================
if [ -f /opt/my-resources/setup/firefox/setup-firefox.sh ]; then
    /opt/my-resources/setup/firefox/setup-firefox.sh || echo -e "${RED}[-]${NC} Firefox setup had errors, continuing..."
fi

# ============================================================================
# NVIDIA GPU Setup (driver-aware, auto-detected)
# ============================================================================
if [ -f /opt/my-resources/setup/gpu/setup-gpu.sh ]; then
    /opt/my-resources/setup/gpu/setup-gpu.sh || echo -e "${RED}[-]${NC} GPU setup had errors, continuing..."
fi

# ============================================================================
# Sliver C2 Persistence (server data + armory extensions)
# ============================================================================
if [ -f /opt/my-resources/setup/sliver/setup-sliver.sh ]; then
    /opt/my-resources/setup/sliver/setup-sliver.sh || echo -e "${RED}[-]${NC} Sliver setup had errors, continuing..."
fi

# ============================================================================
# Killshot - Global PATH
# ============================================================================
if [ -f /opt/my-resources/avbypass/killshot.sh ]; then
    ln -sf /opt/my-resources/avbypass/killshot.sh /usr/local/bin/killshot
    chmod +x /opt/my-resources/avbypass/killshot.sh
    echo -e "${GREEN}[+]${NC} killshot installed to PATH"
fi

# ============================================================================
# Sliver Daemon Auto-Start
# ============================================================================
SLIVER_SERVER=$(which sliver-server 2>/dev/null || echo "/opt/tools/bin/sliver-server")
if [ -x "$SLIVER_SERVER" ] && ! pgrep -f "sliver-server daemon" > /dev/null 2>&1; then
    echo -e "${BLUE}[*]${NC} Starting Sliver daemon..."
    SLIVER_ROOT_DIR="${HOME}/.sliver" nohup "$SLIVER_SERVER" daemon > /tmp/sliver-daemon.log 2>&1 &
    sleep 2
    if pgrep -f "sliver-server daemon" > /dev/null 2>&1; then
        echo -e "${GREEN}[+]${NC} Sliver daemon started"
    else
        echo -e "${RED}[-]${NC} Sliver daemon failed to start"
    fi
fi

# ============================================================================
# Burp Suite Pro License Persistence
# ============================================================================
if [ -d /opt/my-resources/setup/burp-config/burp ] && [ ! -f /root/.java/.userPrefs/burp/prefs.xml ]; then
    echo -e "${BLUE}[*]${NC} Restoring Burp Suite Pro license..."
    mkdir -p /root/.java/.userPrefs
    cp -r /opt/my-resources/setup/burp-config/burp /root/.java/.userPrefs/burp
    echo -e "${GREEN}[+]${NC} Burp Suite Pro license restored"
fi

echo -e "${GREEN}[+]${NC} First-time setup complete!"
