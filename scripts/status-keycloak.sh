#!/usr/bin/env bash
set -euo pipefail
command -v docker >/dev/null 2>&1 || { echo "[ERRO] Docker não encontrado."; exit 1; }
docker --version
docker ps -a --filter name='^keycloak$'
if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
  echo "[OK] Keycloak respondendo em localhost:8080"
  [[ -n "${CODESPACE_NAME:-}" ]] && echo "URL: https://${CODESPACE_NAME}-8080.app.github.dev"
else
  echo "[AVISO] Keycloak não está respondendo."
fi
