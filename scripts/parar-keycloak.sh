#!/usr/bin/env bash
set -euo pipefail
docker stop keycloak >/dev/null 2>&1 || true
echo "[OK] Keycloak parado."
