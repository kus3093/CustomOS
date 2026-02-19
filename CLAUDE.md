# CLAUDE.md — NovaPi OS

## Project Overview

**NovaPi OS** is a Bash-based installer that transforms a stock Raspberry Pi 5 into a customized "NovaPi OS" environment. It configures a dark-themed LXQt desktop, streaming support via Chromium + Widevine DRM, a Python/JupyterLab data science setup, and a daily auto-update service.

**Target hardware:** Raspberry Pi 5 · 16GB RAM · 64GB+ Storage
**Host OS:** Raspberry Pi OS (Debian-based)
**Entry point:** `install.sh` (must be run as root via `sudo`)

---

## Repository Structure

```
CustomOS/
├── install.sh               # Main installer — orchestrates all modules
└── scripts/
    ├── setup-desktop.sh     # LXQt desktop + dark neon theme + Picom compositor
    ├── setup-streaming.sh   # Chromium + Widevine DRM (Netflix, Hulu, YouTube)
    ├── setup-python.sh      # Python 3, pip, JupyterLab, data science packages
    ├── setup-autoupdate.sh  # Systemd daily auto-update service + timer
    └── setup-utils.sh       # NovaPi utility commands (referenced, not yet created)
```

> **Note:** `setup-utils.sh` is called by `install.sh` but does not yet exist in the repo. It must be created before the full installer runs successfully.

---

## How the Installer Works

`install.sh` is the sole entry point. It:

1. Runs `preflight()` — validates root, Pi 5 hardware, disk space (≥8GB), and internet.
2. Runs `system_update()` — `apt-get update/upgrade` and installs base tools.
3. Calls `run_module()` for each sub-script in `scripts/`:
   - `setup-desktop.sh`
   - `setup-streaming.sh`
   - `setup-python.sh`
   - `setup-autoupdate.sh`
   - `setup-utils.sh`
4. Prints a summary of what was installed.

Sub-scripts are **never run directly** in production. They are invoked by `run_module()` in `install.sh`, which validates they are executable first.

---

## Module Details

### `setup-desktop.sh`
- Installs **LXQt** desktop environment via `apt`
- Configures **LightDM** with auto-login for `$REAL_USER`
- Sets up **Picom** compositor (GLX backend, blur, shadows, rounded corners)
- Creates **LXQt panel** config (bottom bar, dark `#0d0d1a` background)
- Attempts **Kvantum** Qt theme engine install (non-fatal if unavailable)
- Generates a gradient PNG wallpaper at `/opt/novapi/wallpapers/default.jpg` via Python/Pillow (falls back to empty file if Pillow absent)
- Installs Papirus-Dark icons and Adwaita-dark GTK theme
- Autostart entries: `picom.desktop`, `wallpaper.desktop`

### `setup-streaming.sh`
- Installs **Chromium** and attempts **Widevine DRM** (`libwidevinecdm0` or `chromium-widevine`)
- Checks known Widevine `.so` paths; warns if not found (non-fatal)
- Installs **VA-API** hardware video acceleration packages
- Writes `chrome-flags.conf` enabling VaapiVideoDecoder, GPU rasterization, zero-copy
- Creates Chromium managed policy JSON at `/etc/chromium/policies/recommended/novapi-policy.json`
- Creates Desktop shortcuts for Netflix, Hulu, YouTube

### `setup-python.sh`
- Installs system Python 3, pip, venv, dev headers, and BLAS/LAPACK build deps
- Installs via `pip3` (as `$REAL_USER`): `jupyterlab`, `notebook`, `ipywidgets`, `numpy`, `pandas`, `matplotlib`, `requests`, `Pillow`, `rich`, `httpx`, `black`, `pylint`
- Writes `~/.jupyter/jupyter_lab_config.py` (binds to `0.0.0.0:8888`, no auth token, opens browser)
- Creates `~/Notebooks/` with three starter `.ipynb` files: `00-Welcome`, `01-Python-Basics`, `02-Linux-Commands`
- Adds `.config/autostart/jupyterlab.desktop` (starts Jupyter 5s after login)
- Appends `jl`, `jn`, `py`, `pip` aliases to `~/.bashrc`

### `setup-autoupdate.sh`
- Installs `/opt/novapi/scripts/novapi-update.sh` update script
- Symlinks it to `/usr/local/bin/novapi-update`
- Creates and enables a **systemd service** (`novapi-update.service`) and **timer** (`novapi-update.timer`)
- Timer fires: 2 minutes after boot + daily at 03:30 AM (±10min randomized delay)
- Update script: `apt-get update/upgrade/autoremove` + `pip3 install -U` for all outdated user packages
- Logs to `/var/log/novapi-update.log` and `journalctl -u novapi-update`

---

## Key Conventions

### Shell Script Style

All scripts follow these conventions:

```bash
#!/usr/bin/env bash
set -euo pipefail          # Strict: exit on error, unset vars, pipefail
```

**Logging helpers** (defined locally in each script):
```bash
log()     { echo -e "\033[0;32m[✔]\033[0m $*"; }   # Green — success
warn()    { echo -e "\033[1;33m[!]\033[0m $*"; }   # Yellow — non-fatal warning
error()   { echo -e "\033[0;31m[✘]\033[0m $*"; exit 1; }  # Red — fatal, exits
section() { echo -e "\n${MAGENTA}${BOLD}━━━  $*  ━━━${RESET}\n"; }  # install.sh only
```

**User detection** (scripts run as root, but configure the real user's home):
```bash
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
```

**Non-fatal apt installs** use `|| warn "message"` to degrade gracefully rather than abort.

**Heredoc configs** use `<< 'EOF'` (single-quoted) to prevent variable expansion inside config file contents, then `sed -i "s/NOVAPI_USER/$REAL_USER/"` to substitute the username afterward.

**Ownership fix** at the end of each script:
```bash
chown -R "$REAL_USER:$REAL_USER" <paths> 2>/dev/null || true
```

### Running the Installer

```bash
sudo bash install.sh
```

- Must be run as root.
- Interactive: prompts once before starting (press Enter or Ctrl+C).
- All sub-scripts are called via `run_module` — not standalone.

### Adding a New Module

1. Create `scripts/setup-<name>.sh` using the same `set -euo pipefail` + helper function pattern.
2. Make it executable: `chmod +x scripts/setup-<name>.sh`
3. Add a `run_module "Display Name" "setup-<name>.sh"` call in `install.sh`'s `main()`.
4. Add relevant output to the `summary()` block in `install.sh`.

### Installed Paths Convention

| Path | Purpose |
|------|---------|
| `/opt/novapi/` | NovaPi-specific files (scripts, wallpapers) |
| `/opt/novapi/scripts/novapi-update.sh` | Auto-update script |
| `/opt/novapi/wallpapers/default.jpg` | Default wallpaper |
| `/usr/local/bin/novapi-*` | User-callable NovaPi commands |
| `/etc/systemd/system/novapi-*.{service,timer}` | Systemd units |
| `/var/log/novapi-update.log` | Auto-update log |
| `~/.config/lxqt/` | LXQt config (session, panel) |
| `~/.config/picom/picom.conf` | Picom compositor config |
| `~/.config/chromium/chrome-flags.conf` | Chromium GPU flags |
| `~/Notebooks/` | JupyterLab starter notebooks |

---

## Known Issues / TODOs

- **`setup-utils.sh` is missing.** The `install.sh` calls `run_module "NovaPi Utilities" "setup-utils.sh"` but this script does not exist. The installer will fail at that step. Create this script to provide `novapi-info` and any other utility commands.
- **JupyterLab token disabled.** The config sets `token = ''` and `password = ''`. This is intentional for local-only use but exposes the server to anyone on the local network. Consider adding a note or optional password setup.
- **Widevine is non-deterministic.** Availability depends on the specific Pi OS version and apt mirror; the installer degrades gracefully with warnings.

---

## Useful Commands (Post-Install)

```bash
novapi-update          # Manually run system + pip updates
novapi-info            # Show system info (from setup-utils.sh, once created)
jupyter lab            # Launch JupyterLab manually
jl                     # Alias for 'jupyter lab'
journalctl -u novapi-update   # View auto-update logs
cat /var/log/novapi-update.log
systemctl status novapi-update.timer
```
