#!/usr/bin/env bash
set -euo pipefail

if docker ps -a --format '{{.Names}}' | grep -qx keycloak; then
  docker stop keycloak >/dev/null
  echo "[OK] Keycloak parado."
else
  echo "[INFO] Container keycloak nao encontrado."
fi
