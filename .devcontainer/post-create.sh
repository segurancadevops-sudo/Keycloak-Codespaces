#!/usr/bin/env bash
set -u

echo
echo "============================================================"
echo " KEYCLOAK TRAINING ACADEMY - PREPARAÇÃO"
echo "============================================================"

if command -v docker >/dev/null 2>&1; then
  echo "[OK] Docker CLI encontrado."
  docker --version || true
else
  echo "[ERRO] Docker não foi instalado."
fi

if command -v gh >/dev/null 2>&1; then
  echo "[OK] GitHub CLI encontrado."
  gh --version | head -n1 || true
else
  echo "[ERRO] GitHub CLI não foi instalado."
fi

echo
echo "Próximo comando:"
echo "  ./scripts/iniciar-keycloak.sh"
echo "============================================================"
