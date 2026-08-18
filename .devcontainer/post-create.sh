#!/usr/bin/env bash
set -u

echo "============================================================"
echo " KEYCLOAK TRAINING ACADEMY - PREPARAÇÃO DO AMBIENTE"
echo "============================================================"
. /etc/os-release
echo "Sistema: ${PRETTY_NAME:-Linux}"

if command -v docker >/dev/null 2>&1; then
  echo "[OK] Docker CLI encontrado:"
  docker --version || true
  echo "[INFO] Aguardando Docker Engine..."
  for i in $(seq 1 30); do
    if docker info >/dev/null 2>&1; then
      echo "[OK] Docker Engine disponível."
      break
    fi
    sleep 2
  done
else
  echo "[ERRO] Docker não foi instalado no Dev Container."
fi

echo "Próximo comando: ./scripts/iniciar-keycloak.sh"
