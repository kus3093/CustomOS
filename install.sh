#!/usr/bin/env bash
# =============================================================================
#  NovaPi OS Installer
#  Customized Raspberry Pi 5 environment
#  Raspberry Pi 5 | 16GB RAM | 64GB+ Storage
# =============================================================================
set -euo pipefail

# ── Colors ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BOLD='\033[1m'; RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

banner() {
cat << 'EOF'

  ███╗   ██╗ ██████╗ ██╗   ██╗ █████╗ ██████╗ ██╗     ██████╗ ███████╗
  ████╗  ██║██╔═══██╗██║   ██║██╔══██╗██╔══██╗██║    ██╔═══██╗██╔════╝
  ██╔██╗ ██║██║   ██║██║   ██║███████║██████╔╝██║    ██║   ██║███████╗
  ██║╚██╗██║██║   ██║╚██╗ ██╔╝██╔══██║██╔═══╝ ██║    ██║   ██║╚════██║
  ██║ ╚████║╚██████╔╝ ╚████╔╝ ██║  ██║██║     ██║    ╚██████╔╝███████║
  ╚═╝  ╚═══╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚═╝     ╚═╝     ╚═════╝ ╚══════╝

           Raspberry Pi 5  ·  Sleek  ·  Fast  ·  Funky
EOF
}

log()     { echo -e "${GREEN}[✔]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $*"; }
error()   { echo -e "${RED}[✘]${RESET} $*"; exit 1; }
section() { echo -e "\n${MAGENTA}${BOLD}━━━  $*  ━━━${RESET}\n"; }

# ── Pre-flight checks ───────────────────────────────────────────────────────
preflight() {
    section "Pre-flight Checks"

    [[ $EUID -ne 0 ]] && error "Run with sudo: sudo bash install.sh"

    # Verify Pi 5 hardware
    if grep -q "Raspberry Pi 5" /proc/cpuinfo 2>/dev/null; then
        log "Raspberry Pi 5 detected"
    else
        warn "Could not confirm Pi 5 hardware — continuing anyway"
    fi

    # Check free disk space (need at least 8GB)
    local free_kb
    free_kb=$(df / | awk 'NR==2 {print $4}')
    (( free_kb < 8388608 )) && error "Need at least 8GB free disk space"
    log "Disk space OK ($(( free_kb / 1024 / 1024 ))GB free)"

    # Check internet
    if ping -c1 -W3 1.1.1.1 &>/dev/null; then
        log "Internet connection OK"
    else
        error "No internet connection. Please connect and retry."
    fi
}

# ── System update ───────────────────────────────────────────────────────────
system_update() {
    section "Updating System Packages"
    apt-get update -qq
    apt-get upgrade -y -qq
    apt-get install -y -qq \
        curl wget git vim nano htop neofetch \
        build-essential gcc make \
        apt-transport-https ca-certificates gnupg
    log "System updated"
}

# ── Run sub-scripts ─────────────────────────────────────────────────────────
run_module() {
    local name="$1" script="$2"
    section "$name"
    if [[ -x "$SCRIPT_DIR/scripts/$script" ]]; then
        bash "$SCRIPT_DIR/scripts/$script"
        log "$name — done"
    else
        error "Script not found: scripts/$script"
    fi
}

# ── Summary ─────────────────────────────────────────────────────────────────
summary() {
    section "Installation Complete"
    cat << EOF
${CYAN}${BOLD}  NovaPi OS is ready! Here's what was installed:${RESET}

  🖥  Desktop    → LXQt with Neon theme (sleek & dark)
  🎬  Streaming  → Chromium + Widevine DRM (Netflix, Hulu, YouTube)
  🐍  Python     → Python 3, pip, virtualenv
  📓  Jupyter    → JupyterLab (browser at http://localhost:8888)
  🔄  Updates    → Auto-update runs daily at boot
  💡  Learning   → tldr, man pages, bash history configured

  ${YELLOW}Reboot to apply all changes:${RESET}
      sudo reboot

  ${YELLOW}After reboot, Jupyter starts at:${RESET}
      http://localhost:8888

  ${YELLOW}Useful commands:${RESET}
      novapi-update   → Manually run system updates
      novapi-info     → Show system info
      jupyter lab     → Launch JupyterLab manually
EOF
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    clear
    banner
    echo -e "\n${CYAN}This installer will customize your Raspberry Pi 5 into NovaPi OS${RESET}"
    echo -e "${YELLOW}Press ENTER to continue or Ctrl+C to cancel...${RESET}"
    read -r

    preflight
    system_update
    run_module "LXQt Desktop & Theme"  "setup-desktop.sh"
    run_module "Streaming (Chromium)"  "setup-streaming.sh"
    run_module "Python & JupyterLab"   "setup-python.sh"
    run_module "Auto-Update Service"   "setup-autoupdate.sh"
    run_module "NovaPi Utilities"      "setup-utils.sh"
    summary
}

main "$@"
