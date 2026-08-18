#!/usr/bin/env bash
set -euo pipefail
docker ps -a --filter name='^keycloak$'
if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
  echo "[OK] Keycloak respondendo em http://localhost:8080"
else
  echo "[AVISO] Keycloak nao responde na porta 8080."
fi
