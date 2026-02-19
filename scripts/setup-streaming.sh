#!/usr/bin/env bash
# =============================================================================
#  NovaPi OS – Streaming Setup
#  Chromium + Widevine DRM for Netflix, Hulu, YouTube
# =============================================================================
set -euo pipefail

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

log()  { echo -e "\033[0;32m[✔]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }

# ── 1. Install Chromium ───────────────────────────────────────────────────────
log "Installing Chromium browser..."
apt-get install -y -qq chromium chromium-sandbox
log "Chromium installed: $(chromium --version 2>/dev/null || chromium-browser --version)"

# ── 2. Widevine DRM (required for Netflix & Hulu) ───────────────────────────
# The Pi OS ships widevine as a separate package
log "Installing Widevine DRM..."

# Method 1: widevine package (Pi OS specific)
if apt-cache show libwidevinecdm0 &>/dev/null 2>&1; then
    apt-get install -y -qq libwidevinecdm0
    log "Widevine DRM installed via apt"
else
    warn "libwidevinecdm0 not found in apt — trying chromium-widevine..."
    apt-get install -y -qq chromium-widevine 2>/dev/null || \
    warn "chromium-widevine not found — Widevine may need manual setup"
fi

# ── 3. Locate and verify Widevine plugin ─────────────────────────────────────
WIDEVINE_PATHS=(
    "/usr/lib/chromium/libwidevinecdm.so"
    "/usr/lib/chromium-browser/WidevineCdm/libwidevinecdm.so"
    "/opt/WidevineCdm/libwidevinecdm.so"
    "/usr/lib/chromium/WidevineCdm/libwidevinecdm.so"
)

WIDEVINE_FOUND=""
for p in "${WIDEVINE_PATHS[@]}"; do
    if [[ -f "$p" ]]; then
        WIDEVINE_FOUND="$p"
        log "Widevine found at: $p"
        break
    fi
done

[[ -z "$WIDEVINE_FOUND" ]] && warn "Widevine library not detected — Netflix/Hulu may not work"

# ── 4. GPU & hardware video decode for smooth playback ───────────────────────
log "Installing hardware video acceleration..."
apt-get install -y -qq \
    va-driver-all \
    vainfo \
    libva2 \
    libva-drm2 \
    libva-x11-2 \
    v4l-utils 2>/dev/null || warn "Some VA-API packages unavailable"

# ── 5. Chromium flags for Pi 5 (GPU accel + DRM) ─────────────────────────────
log "Configuring Chromium flags for Pi 5..."
mkdir -p "$REAL_HOME/.config/chromium"

cat > "$REAL_HOME/.config/chromium/chrome-flags.conf" << 'EOF'
--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization
--disable-features=UseChromeOSDirectVideoDecoder
--enable-gpu-rasterization
--enable-zero-copy
--ignore-gpu-blocklist
--enable-hardware-overlays
--ozone-platform=x11
--no-sandbox-flags=allow-sandbox-debug-crash
EOF

# Chromium policy directory
mkdir -p /etc/chromium/policies/recommended

cat > /etc/chromium/policies/recommended/novapi-policy.json << 'EOF'
{
    "DefaultBrowserSettingEnabled": false,
    "BackgroundModeEnabled": true,
    "HardwareAccelerationModeEnabled": true,
    "RendererCodeIntegrityEnabled": false,
    "AllowedDomainsForApps": ["netflix.com", "hulu.com", "youtube.com"],
    "RestoreOnStartup": 1
}
EOF

# ── 6. Desktop shortcuts ──────────────────────────────────────────────────────
log "Creating streaming app shortcuts..."
DESKTOP_DIR="$REAL_HOME/Desktop"
mkdir -p "$DESKTOP_DIR"

create_shortcut() {
    local name="$1" url="$2" icon="$3" file="$4"
    cat > "$DESKTOP_DIR/$file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Comment=Watch $name
Exec=chromium --new-window "$url"
Icon=$icon
Terminal=false
Categories=Network;Video;
EOF
    chmod +x "$DESKTOP_DIR/$file"
}

create_shortcut "Netflix"  "https://www.netflix.com"  "chromium"  "netflix.desktop"
create_shortcut "YouTube"  "https://www.youtube.com"  "chromium"  "youtube.desktop"
create_shortcut "Hulu"     "https://www.hulu.com"     "chromium"  "hulu.desktop"

# ── 7. Media codecs ───────────────────────────────────────────────────────────
log "Installing media codecs..."
apt-get install -y -qq \
    ffmpeg \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    libavcodec-extra 2>/dev/null || warn "Some codec packages unavailable"

# ── 8. Fix ownership ──────────────────────────────────────────────────────────
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config" "$REAL_HOME/Desktop" 2>/dev/null || true

log "Streaming setup complete"
log "Netflix, Hulu, and YouTube shortcuts created on Desktop"
warn "Note: Log out and back in for GPU flags to fully apply"
