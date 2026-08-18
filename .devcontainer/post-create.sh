#!/usr/bin/env bash
set +e

chmod +x scripts/*.sh 2>/dev/null || true

echo
echo "============================================================"
echo " KEYCLOAK TRAINING ACADEMY"
echo "============================================================"

if command -v docker >/dev/null 2>&1; then
  echo "[OK] Docker encontrado."
  docker --version
else
  echo "[ERRO] Docker nao foi instalado corretamente."
fi

if command -v gh >/dev/null 2>&1; then
  echo "[OK] GitHub CLI encontrado."
  gh --version | head -n1
else
  echo "[ERRO] GitHub CLI nao foi instalado corretamente."
fi

echo
echo "Para iniciar o laboratorio:"
echo
echo "  ./scripts/iniciar-keycloak.sh"
echo
echo "============================================================"
