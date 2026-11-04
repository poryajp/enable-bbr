#!/usr/bin/env bash
set -euo pipefail

# Requires root
if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root or with sudo." >&2
  exit 1
fi

SYSCTL_FILE="/etc/sysctl.d/99-bbr.conf"
MODULES_FILE="/etc/modules-load.d/bbr.conf"

# Load the BBR module
if ! modprobe tcp_bbr 2>/dev/null; then
  echo "The tcp_bbr module is not supported by this kernel." >&2
  exit 1
fi

# Load the module automatically on every boot
echo "tcp_bbr" > "$MODULES_FILE"

# sysctl settings
cat > "$SYSCTL_FILE" <<'EOF'
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

# Apply settings
sysctl --system >/dev/null

# Verify result
CC=$(sysctl -n net.ipv4.tcp_congestion_control)
QDISC=$(sysctl -n net.core.default_qdisc)

echo "Congestion control: $CC"
echo "Default qdisc:      $QDISC"

if [[ "$CC" == "bbr" ]] && lsmod | grep -q '^tcp_bbr'; then
  echo "BBR enabled successfully."
else
  echo "Failed to enable BBR." >&2
  exit 1
fi
