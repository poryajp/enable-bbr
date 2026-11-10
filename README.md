# Debian TCP BBR Enabler

A lightweight, idempotent, and fault-tolerant Bash script to enable Google's **TCP BBR** (Bottleneck Bandwidth and Round-trip propagation time) congestion control and **FQ** (Fair Queue) packet scheduler on Debian and Ubuntu systems.

## Why This Script?

Many basic BBR scripts fail on specific VPS environments, custom kernels, or containers. This script is engineered to avoid common pitfalls:

- **Built-in & Module Agnostic:** Safely handles kernels where `tcp_bbr` and `sch_fq` are compiled directly into the kernel (built-in) rather than loaded as external `.ko` modules.
- **Load-Order Safe:** Uses `/etc/sysctl.d/99-zzz-bbr.conf` to ensure configuration takes precedence over `/etc/sysctl.d/99-sysctl.conf` and `/etc/sysctl.conf` during boot.
- **Isolated Execution:** Applies settings strictly via `sysctl -p <file>` instead of `sysctl --system`, preventing unrelated broken sysctl keys on the host from crashing the script.
- **Direct Kernel Verification:** Validates activation by querying the live kernel state (`sysctl -n`) rather than relying on `lsmod` output.

## Prerequisites

- **OS:** Debian 9+ / Ubuntu 18.04+ (or any Linux distribution with `sysctl` and Linux Kernel **4.9+**)
- **Privileges:** Root access or `sudo`
- **Virtualization:** KVM, Xen, VMware, Bare Metal (Note: LXC/OpenVZ containers require BBR to be enabled on the host node)

## Quick Start

### Run Directly (One-Liner)

```bash
curl -fsSL [https://raw.githubusercontent.com/](https://raw.githubusercontent.com/)poryajp/enable-bbr/main/bbr.sh | sudo bash
