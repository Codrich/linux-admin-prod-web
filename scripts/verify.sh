#!/usr/bin/env bash
set -euo pipefail
IP="$1"
echo "[*] HTTP check"
curl -sSfI "http://$IP" | head -n1
echo "[*] Open ports"
nc -zv "$IP" 80 443 22
