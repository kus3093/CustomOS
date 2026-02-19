#!/usr/bin/env bash
# =============================================================================
#  NovaPi OS – Desktop Setup
#  LXQt desktop environment with sleek dark theming
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

log()  { echo -e "\033[0;32m[✔]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }

# ── 1. Install LXQt and supporting packages ──────────────────────────────────
log "Installing LXQt desktop environment..."
apt-get install -y -qq \
    lxqt \
    openbox \
    obconf \
    lxqt-notificationd \
    lxqt-panel \
    lxqt-runner \
    lxqt-session \
    lxqt-config \
    lxqt-policykit \
    lxqt-globalkeys \
    qtterminal \
    pcmanfm-qt \
    featherpad \
    lximage-qt \
    xserver-xorg \
    lightdm \
    lightdm-gtk-greeter \
    lightdm-gtk-greeter-settings \
    xdg-utils \
    dbus-x11 \
    picom \
    feh \
    lm-sensors \
    fonts-noto \
    fonts-firacode \
    papirus-icon-theme \
    adwaita-qt

log "LXQt packages installed"

# ── 2. Dark/Neon theme (Kvantum for Qt styling) ──────────────────────────────
log "Installing Kvantum theme engine..."
apt-get install -y -qq qt5-style-kvantum qt5-style-kvantum-themes 2>/dev/null || \
    warn "Kvantum not available in this repo — skipping Qt theme engine"

# ── 3. LightDM greeter configuration ─────────────────────────────────────────
log "Configuring LightDM login screen..."
mkdir -p /etc/lightdm

cat > /etc/lightdm/lightdm.conf << 'EOF'
[Seat:*]
autologin-guest=false
autologin-user=NOVAPI_USER
autologin-user-timeout=0
user-session=lxqt
greeter-session=lightdm-gtk-greeter
EOF

# Replace placeholder with actual user
sed -i "s/NOVAPI_USER/$REAL_USER/" /etc/lightdm/lightdm.conf

cat > /etc/lightdm/lightdm-gtk-greeter.conf << 'EOF'
[greeter]
theme-name     = Adwaita-dark
icon-theme-name = Papirus-Dark
font-name      = Noto Sans 11
background     = #0d0d1a
position       = 50%,center 50%,center
indicators     = ~host;~spacer;~clock;~spacer;~session;~power
clock-format   = %A, %d %b  %H:%M
EOF

log "LightDM configured"

# ── 4. LXQt session & appearance defaults ────────────────────────────────────
log "Configuring LXQt appearance..."
USER_CONFIG="$REAL_HOME/.config"
mkdir -p "$USER_CONFIG/lxqt"

# Install pre-built config files
if [[ -d "$SCRIPT_DIR/config/lxqt" ]]; then
    cp -r "$SCRIPT_DIR/config/lxqt/." "$USER_CONFIG/lxqt/"
fi

# LXQt session
cat > "$USER_CONFIG/lxqt/session.conf" << 'EOF'
[General]
__userfile__=true
iconTheme=Papirus-Dark
singleClickActivate=false

[Environment]
QT_QPA_PLATFORMTHEME=qt5ct
QT_AUTO_SCREEN_SCALE_FACTOR=1
EOF

# LXQt panel (bottom bar)
mkdir -p "$USER_CONFIG/lxqt"
cat > "$USER_CONFIG/lxqt/panel.conf" << 'EOF'
[General]
__userfile__=true

[panel1]
alignment=-1
background=#0d0d1acc
fontColor=#e0e0ff
hidable=false
iconSize=24
lineCount=1
panelSize=40
plugins=mainmenu, taskbar, tray, statusnotifier, clock, showdesktop
position=Bottom
showBorder=true
EOF

# ── 5. Picom compositor (transparency + shadows) ─────────────────────────────
log "Configuring Picom compositor..."
mkdir -p "$REAL_HOME/.config/picom"
cat > "$REAL_HOME/.config/picom/picom.conf" << 'EOF'
# NovaPi picom compositor config
backend = "glx";
vsync = true;
glx-no-stencil = true;
glx-copy-from-front = false;

# Shadows
shadow = true;
shadow-radius = 12;
shadow-offset-x = -5;
shadow-offset-y = -5;
shadow-opacity = 0.6;
shadow-color = "#000000";
shadow-exclude = [
    "name = 'Notification'",
    "class_g = 'Conky'",
    "_GTK_FRAME_EXTENTS@:c"
];

# Transparency
active-opacity = 1.0;
inactive-opacity = 0.95;
frame-opacity = 0.9;
inactive-opacity-override = false;

opacity-rule = [
    "90:class_g = 'QTerminal'",
    "90:class_g = 'Featherpad'"
];

# Fading
fading = true;
fade-delta = 6;
fade-in-step = 0.04;
fade-out-step = 0.04;

# Blur
blur-method = "dual_kawase";
blur-strength = 5;

corner-radius = 8;
EOF

# ── 6. Autostart (picom + wallpaper) ─────────────────────────────────────────
mkdir -p "$REAL_HOME/.config/autostart"

cat > "$REAL_HOME/.config/autostart/picom.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Picom
Exec=picom --config /home/NOVAPI_USER/.config/picom/picom.conf -b
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
sed -i "s/NOVAPI_USER/$REAL_USER/g" "$REAL_HOME/.config/autostart/picom.desktop"

cat > "$REAL_HOME/.config/autostart/wallpaper.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Set Wallpaper
Exec=feh --bg-scale /opt/novapi/wallpapers/default.jpg
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

# ── 7. Download a wallpaper ───────────────────────────────────────────────────
log "Setting up wallpaper directory..."
mkdir -p /opt/novapi/wallpapers

# Generate a gradient wallpaper using Python (no download needed)
python3 - << 'PYEOF'
try:
    from PIL import Image, ImageDraw
    import math

    w, h = 1920, 1080
    img = Image.new('RGB', (w, h))
    draw = ImageDraw.Draw(img)

    for y in range(h):
        ratio = y / h
        r = int(13 + ratio * 30)
        g = int(13 + ratio * 5)
        b = int(26 + ratio * 80)
        draw.line([(0, y), (w, y)], fill=(r, g, b))

    # Add some "stars"
    import random
    random.seed(42)
    for _ in range(300):
        x = random.randint(0, w)
        y = random.randint(0, h // 2)
        r = random.randint(200, 255)
        draw.ellipse([x, y, x+1, y+1], fill=(r, r, r))

    img.save('/opt/novapi/wallpapers/default.jpg', quality=95)
    print("  Wallpaper generated")
except ImportError:
    # Pillow not installed yet — create a placeholder
    open('/opt/novapi/wallpapers/default.jpg', 'w').close()
    print("  Wallpaper placeholder created (install Pillow to generate)")
PYEOF

# ── 8. Fix ownership ──────────────────────────────────────────────────────────
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config" /opt/novapi 2>/dev/null || true

# ── 9. Set default display manager ───────────────────────────────────────────
systemctl enable lightdm 2>/dev/null || true

log "Desktop setup complete — LXQt with dark neon theme ready"
