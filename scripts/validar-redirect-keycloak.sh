#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -z "${CODESPACE_NAME:-}" ]]; then
  echo "[AVISO] Este teste faz mais sentido dentro do GitHub Codespaces."
fi

EXPECTED_BASE="${CODESPACE_NAME:+https://${CODESPACE_NAME}-8080.app.github.dev}"

echo "=== REDIRECT / HOSTNAME DIAGNOSTIC ==="
echo

echo "[1] Location do /admin/:"
curl -sSI http://localhost:8080/admin/ | grep -i '^location:' || echo "Sem Location explícito."
echo

echo "[2] Issuer OIDC:"
ISSUER="$(
  curl -fsS http://localhost:8080/realms/master/.well-known/openid-configuration \
  | python3 -c 'import sys,json; print(json.load(sys.stdin).get("issuer",""))'
)"
echo "$ISSUER"
echo

if [[ -n "${EXPECTED_BASE}" ]]; then
  EXPECTED_ISSUER="${EXPECTED_BASE}/realms/master"

  if [[ "$ISSUER" == "$EXPECTED_ISSUER" ]]; then
    echo "[OK] Issuer correto para Codespaces."
  else
    echo "[ERRO] Issuer incorreto."
    echo "Esperado: $EXPECTED_ISSUER"
    exit 1
  fi
fi

echo
echo "[OK] Diagnóstico concluído."
