#!/usr/bin/env bash
set -euo pipefail

echo "Installing Codespaces graphical desktop..."

if [ "$(dpkg --print-architecture)" != "amd64" ]; then
  echo "Google Chrome requires an amd64 Linux Codespace."
  exit 1
fi

sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  --no-install-recommends \
  xfce4 xfce4-terminal dbus-x11 xauth \
  tigervnc-standalone-server tigervnc-tools \
  novnc websockify curl wget ca-certificates iproute2

if ! command -v google-chrome >/dev/null 2>&1; then
  wget -q -O /tmp/google-chrome.deb \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    /tmp/google-chrome.deb
fi

mkdir -p "$HOME/.vnc"

cat > "$HOME/.vnc/xstartup" <<'XFCE'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-run-session -- startxfce4
XFCE

chmod 700 "$HOME/.vnc/xstartup"

echo "Desktop software installation complete."
google-chrome --version
