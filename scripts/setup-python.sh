#!/usr/bin/env bash
# =============================================================================
#  NovaPi OS – Python & JupyterLab Setup
#  Python 3, pip, virtualenv, JupyterLab, data science basics
# =============================================================================
set -euo pipefail

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

log()  { echo -e "\033[0;32m[✔]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }

# ── 1. Python 3 and build deps ────────────────────────────────────────────────
log "Installing Python 3 and build dependencies..."
apt-get install -y -qq \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-setuptools \
    python3-wheel \
    libssl-dev \
    libffi-dev \
    libblas-dev \
    liblapack-dev

PY_VER=$(python3 --version)
log "Python installed: $PY_VER"

# ── 2. Upgrade pip ───────────────────────────────────────────────────────────
log "Upgrading pip..."
sudo -u "$REAL_USER" python3 -m pip install --upgrade pip --quiet

# ── 3. JupyterLab and Python essentials ──────────────────────────────────────
log "Installing JupyterLab and essential packages..."
sudo -u "$REAL_USER" pip3 install --quiet \
    jupyterlab \
    notebook \
    ipywidgets \
    numpy \
    pandas \
    matplotlib \
    requests \
    Pillow \
    rich \
    httpx \
    black \
    pylint

log "JupyterLab installed: $(sudo -u "$REAL_USER" jupyter lab --version 2>/dev/null)"

# ── 4. JupyterLab configuration ───────────────────────────────────────────────
log "Configuring JupyterLab..."
JUPYTER_CONFIG="$REAL_HOME/.jupyter"
mkdir -p "$JUPYTER_CONFIG"

# Generate config as the real user
sudo -u "$REAL_USER" jupyter lab --generate-config --y 2>/dev/null || true

JUPYTER_CONFIG_FILE="$JUPYTER_CONFIG/jupyter_lab_config.py"

cat > "$JUPYTER_CONFIG_FILE" << 'EOF'
# NovaPi JupyterLab Configuration
c = get_config()  # noqa

# Server
c.ServerApp.ip = '0.0.0.0'          # Accept connections from local network
c.ServerApp.port = 8888
c.ServerApp.open_browser = True      # Auto-open browser
c.ServerApp.token = ''               # No token for local use
c.ServerApp.password = ''
c.ServerApp.allow_remote_access = True
c.ServerApp.notebook_dir = '/home/NOVAPI_USER/Notebooks'

# UI
c.LabApp.default_url = '/lab'

# File size limit (100MB)
c.ServerApp.max_body_size = 104857600
c.ServerApp.max_buffer_size = 104857600
EOF
sed -i "s/NOVAPI_USER/$REAL_USER/g" "$JUPYTER_CONFIG_FILE"

# ── 5. Notebooks directory with starter notebooks ────────────────────────────
log "Creating Notebooks directory with starter content..."
NOTEBOOKS_DIR="$REAL_HOME/Notebooks"
mkdir -p "$NOTEBOOKS_DIR"

# Welcome notebook
cat > "$NOTEBOOKS_DIR/00-Welcome-to-NovaPi.ipynb" << 'NBEOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Welcome to NovaPi OS! 🚀\n",
    "\n",
    "Your Raspberry Pi 5 is set up with:\n",
    "- **Python 3** — powerful, beginner-friendly programming language\n",
    "- **JupyterLab** — interactive notebook environment (you're in it!)\n",
    "- **NumPy, Pandas, Matplotlib** — data science libraries\n",
    "\n",
    "## How to use this notebook\n",
    "- Click a cell and press **Shift+Enter** to run it\n",
    "- Add new cells with the **+** button above\n",
    "- Save with **Ctrl+S**"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Your first Python code! Press Shift+Enter to run\n",
    "print('Hello from NovaPi OS!')\n",
    "print('Python is running on your Raspberry Pi 5!')"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Check system info\n",
    "import platform\n",
    "import sys\n",
    "\n",
    "print(f'Python version : {sys.version}')\n",
    "print(f'Platform       : {platform.platform()}')\n",
    "print(f'Machine        : {platform.machine()}')"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Simple data visualization\n",
    "import matplotlib.pyplot as plt\n",
    "import numpy as np\n",
    "\n",
    "x = np.linspace(0, 2 * np.pi, 100)\n",
    "y = np.sin(x)\n",
    "\n",
    "plt.figure(figsize=(10, 4))\n",
    "plt.plot(x, y, color='cyan', linewidth=2)\n",
    "plt.title('Sine Wave — matplotlib on NovaPi', color='white', fontsize=14)\n",
    "plt.facecolor = '#0d0d1a'\n",
    "plt.grid(True, alpha=0.3)\n",
    "plt.show()"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Explore more notebooks\n",
    "- `01-Python-Basics.ipynb` — Variables, loops, functions\n",
    "- `02-Linux-Commands.ipynb` — Learn shell from Python\n",
    "- `03-GPIO-Blink.ipynb` — Control Pi GPIO pins"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {"name": "python", "version": "3.11.0"}
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
NBEOF

# Python Basics notebook
cat > "$NOTEBOOKS_DIR/01-Python-Basics.ipynb" << 'NBEOF'
{
 "cells": [
  {"cell_type": "markdown", "metadata": {}, "source": ["# Python Basics\n", "Learn Python fundamentals on your Raspberry Pi 5!"]},
  {"cell_type": "code", "execution_count": null, "metadata": {}, "outputs": [], "source": ["# Variables\nname = 'NovaPi'\nversion = 1.0\nis_cool = True\nprint(f'{name} version {version} — Cool: {is_cool}')"]},
  {"cell_type": "code", "execution_count": null, "metadata": {}, "outputs": [], "source": ["# Lists and loops\nfruits = ['apple', 'banana', 'cherry']\nfor i, fruit in enumerate(fruits):\n    print(f'{i+1}. {fruit}')"]},
  {"cell_type": "code", "execution_count": null, "metadata": {}, "outputs": [], "source": ["# Functions\ndef greet(name, greeting='Hello'):\n    return f'{greeting}, {name}!'\n\nprint(greet('Pi'))\nprint(greet('World', 'Hiya'))"]},
  {"cell_type": "code", "execution_count": null, "metadata": {}, "outputs": [], "source": ["# Dictionary\npi_info = {'model': 'Pi 5', 'ram': '16GB', 'os': 'NovaPi'}\nfor key, val in pi_info.items():\n    print(f'  {key}: {val}')"]}
 ],
 "metadata": {"kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"}, "language_info": {"name": "python", "version": "3.11.0"}},
 "nbformat": 4, "nbformat_minor": 5
}
NBEOF

# Linux commands notebook
cat > "$NOTEBOOKS_DIR/02-Linux-Commands.ipynb" << 'NBEOF'
{
 "cells": [
  {"cell_type": "markdown", "metadata": {}, "source": ["# Learning Linux Commands\n", "Run real Linux commands from Python using `subprocess`!"]},
  {"cell_type": "code", "execution_count": null, "metadata": {}, "outputs": [], "source": ["import subprocess\n\ndef run(cmd):\n    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)\n    print(result.stdout or result.stderr)\n\n# Who am I?\nrun('whoami')"]},
  {"cell_type": "code", "execution_count": null, "metadata": {}, "outputs": [], "source": ["# List files\nrun('ls -lh ~/Notebooks')"]},
  {"cell_type": "code", "execution_count": null, "metadata": {}, "outputs": [], "source": ["# System info\nrun('uname -a')"]},
  {"cell_type": "code", "execution_count": null, "metadata": {}, "outputs": [], "source": ["# Disk usage\nrun('df -h /')"]},
  {"cell_type": "code", "execution_count": null, "metadata": {}, "outputs": [], "source": ["# Memory info\nrun('free -h')"]},
  {"cell_type": "code", "execution_count": null, "metadata": {}, "outputs": [], "source": ["# CPU temperature (Pi specific)\nrun('vcgencmd measure_temp 2>/dev/null || cat /sys/class/thermal/thermal_zone0/temp')"]}
 ],
 "metadata": {"kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"}, "language_info": {"name": "python", "version": "3.11.0"}},
 "nbformat": 4, "nbformat_minor": 5
}
NBEOF

# ── 6. Autostart JupyterLab on login ─────────────────────────────────────────
log "Setting up JupyterLab autostart..."
mkdir -p "$REAL_HOME/.config/autostart"

cat > "$REAL_HOME/.config/autostart/jupyterlab.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=JupyterLab
Comment=Start JupyterLab server
Exec=bash -c 'sleep 5 && jupyter lab --no-browser 2>/tmp/jupyter.log &'
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

# ── 7. Add jupyter alias to bashrc ────────────────────────────────────────────
BASHRC="$REAL_HOME/.bashrc"
if ! grep -q "# NovaPi aliases" "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" << 'EOF'

# NovaPi aliases
alias jl='jupyter lab'
alias jn='jupyter notebook'
alias py='python3'
alias pip='pip3'
EOF
fi

# ── 8. Fix ownership ──────────────────────────────────────────────────────────
chown -R "$REAL_USER:$REAL_USER" "$NOTEBOOKS_DIR" "$REAL_HOME/.jupyter" \
    "$REAL_HOME/.config/autostart/jupyterlab.desktop" 2>/dev/null || true

log "Python & JupyterLab setup complete"
log "Notebooks available in ~/Notebooks/"
log "JupyterLab will auto-start at http://localhost:8888 on next login"
