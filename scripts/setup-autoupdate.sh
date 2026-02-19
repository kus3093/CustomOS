#!/usr/bin/env bash
# =============================================================================
#  NovaPi OS – Auto-Update Service Setup
#  Daily automatic system and Python package updates
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_USER="${SUDO_USER:-$USER}"

log()  { echo -e "\033[0;32m[✔]\033[0m $*"; }

# ── 1. Install the update script ──────────────────────────────────────────────
log "Installing novapi-update script..."
mkdir -p /opt/novapi/scripts

cat > /opt/novapi/scripts/novapi-update.sh << 'EOF'
#!/usr/bin/env bash
# NovaPi auto-update script
set -euo pipefail

LOG="/var/log/novapi-update.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

exec >> "$LOG" 2>&1
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "NovaPi Update — $DATE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# System packages
echo "[apt] Updating package lists..."
apt-get update -qq

echo "[apt] Upgrading packages..."
apt-get upgrade -y -qq

echo "[apt] Removing unused packages..."
apt-get autoremove -y -qq
apt-get autoclean -qq

# Python packages (for the primary user)
REAL_USER="$(getent passwd 1000 | cut -d: -f1 2>/dev/null || echo pi)"
if id "$REAL_USER" &>/dev/null; then
    echo "[pip] Upgrading Python packages for $REAL_USER..."
    sudo -u "$REAL_USER" pip3 list --outdated --format=freeze 2>/dev/null \
        | grep -v '^\-e' \
        | cut -d = -f 1 \
        | xargs -r sudo -u "$REAL_USER" pip3 install -U --quiet 2>/dev/null || true
fi

echo "[✔] Update complete — $(date '+%H:%M:%S')"
EOF

chmod +x /opt/novapi/scripts/novapi-update.sh

# ── 2. Symlink as system command ──────────────────────────────────────────────
ln -sf /opt/novapi/scripts/novapi-update.sh /usr/local/bin/novapi-update

# ── 3. Systemd service ────────────────────────────────────────────────────────
log "Installing systemd update service..."

cat > /etc/systemd/system/novapi-update.service << 'EOF'
[Unit]
Description=NovaPi OS Auto-Update
After=network-online.target
Wants=network-online.target
ConditionACPower=true

[Service]
Type=oneshot
ExecStart=/opt/novapi/scripts/novapi-update.sh
StandardOutput=journal
StandardError=journal
SyslogIdentifier=novapi-update

[Install]
WantedBy=multi-user.target
EOF

# ── 4. Systemd timer (daily, on boot after 2min) ──────────────────────────────
log "Installing systemd update timer..."

cat > /etc/systemd/system/novapi-update.timer << 'EOF'
[Unit]
Description=NovaPi OS Daily Auto-Update Timer
Requires=network-online.target

[Timer]
# Run 2 minutes after boot, then daily at 03:30 AM
OnBootSec=2min
OnCalendar=*-*-* 03:30:00
RandomizedDelaySec=10min
Persistent=true
Unit=novapi-update.service

[Install]
WantedBy=timers.target
EOF

# ── 5. Enable the timer ───────────────────────────────────────────────────────
systemctl daemon-reload
systemctl enable novapi-update.timer
systemctl start  novapi-update.timer

log "Auto-update timer enabled"
log "Updates run 2 min after boot + daily at 03:30"
log "View logs: journalctl -u novapi-update  or  cat /var/log/novapi-update.log"
