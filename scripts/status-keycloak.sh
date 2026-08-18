#!/usr/bin/env bash
set -euo pipefail

echo "=== CONTAINER ==="
docker ps -a --filter name='^keycloak$'

echo
echo "=== HTTP ==="
if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
  echo "[OK] Keycloak respondendo em http://localhost:8080"
else
  echo "[AVISO] Keycloak ainda nao esta respondendo na porta 8080."
fi
