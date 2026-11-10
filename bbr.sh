#!/usr/bin/env bash
set -euo pipefail

# 1. Check root privileges
if [[ $EUID -ne 0 ]]; then
    echo "Error: Please run this script as root or with sudo." >&2
    exit 1
fi

# Note: Using zzz- prefix ensures this file loads last during boot
SYSCTL_FILE="/etc/sysctl.d/99-zzz-bbr.conf"
MODULES_FILE="/etc/modules-load.d/bbr.conf"

# 2. Try loading modules (ignore failure in case they are built-in or inside a container)
modprobe tcp_bbr 2>/dev/null || true
modprobe sch_fq 2>/dev/null || true

# 3. Persist modules for boot (if modules-load.d exists)
if [[ -d /etc/modules-load.d ]]; then
    cat > "$MODULES_FILE" <<'EOF'
tcp_bbr
sch_fq
EOF
fi

# 4. Write sysctl settings
mkdir -p /etc/sysctl.d
cat > "$SYSCTL_FILE" <<'EOF'
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

# 5. Apply only our specific file to avoid crashing on unrelated broken sysctl keys
if ! sysctl -p "$SYSCTL_FILE" >/dev/null 2>&1; then
    echo "Error: Kernel rejected BBR or FQ settings (likely an unsupported kernel or container restriction)." >&2
    exit 1
fi

# 6. Verify actual running values directly from the kernel
CC=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")
QDISC=$(sysctl -n net.core.default_qdisc 2>/dev/null || echo "unknown")

echo "Congestion control: $CC"
echo "Default qdisc:      $QDISC"

# 7. Final check based on active kernel state rather than lsmod
if [[ "$CC" == "bbr" && "$QDISC" == "fq" ]]; then
    echo "BBR enabled successfully."
else
    echo "Failed to enable BBR (Current CC: $CC, QDISC: $QDISC)." >&2
    exit 1
fi
