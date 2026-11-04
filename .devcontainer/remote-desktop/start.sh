#!/usr/bin/env bash
set -euo pipefail

echo "Checking Codespaces remote desktop..."

mkdir -p "$HOME/.vnc"

# First run requires a personal VNC password
if [ ! -f "$HOME/.vnc/passwd" ] && \
   [ ! -f "$HOME/.config/tigervnc/passwd" ]; then
  echo "VNC password not configured."
  echo "Run: tigervncpasswd"
  echo "Then run this startup script again."
  exit 0
fi

port_open() {
  ss -H -ltn "sport = :$1" | grep -q .
}

vnc_running() {
  tigervncserver -list 2>/dev/null |
    awk '$1=="1" || $1==":1" {found=1}
         END {exit !found}'
}

if vnc_running; then
  echo "TigerVNC display :1 already exists."
elif port_open 5901; then
  echo "Port 5901 is occupied. Check VNC manually."
  exit 1
else
  echo "Starting XFCE..."
  tigervncserver :1 -localhost yes \
    -geometry 1440x900 -depth 24
fi

if ! port_open 5901; then
  echo "ERROR: VNC port 5901 is not listening."
  exit 1
fi

if ! port_open 6080; then
  echo "Starting noVNC..."
  nohup websockify \
    --web=/usr/share/novnc \
    127.0.0.1:6080 127.0.0.1:5901 \
    > "$HOME/.vnc/novnc.log" 2>&1 < /dev/null &
else
  echo "noVNC already listening."
fi

if curl -fsS --retry 5 --retry-connrefused \
  --retry-delay 1 --max-time 5 \
  http://127.0.0.1:6080/vnc.html \
  -o /dev/null; then
  echo "DESKTOP SERVICES ARE READY"
else
  echo "ERROR: noVNC health check failed."
  exit 1
fi

if [ -n "${CODESPACE_NAME:-}" ]; then
  DOMAIN="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
  echo "Open this URL in a GitHub-authenticated browser:"
  echo "https://${CODESPACE_NAME}-6080.${DOMAIN}/vnc.html"
fi

echo "Keep forwarded port 6080 PRIVATE."
