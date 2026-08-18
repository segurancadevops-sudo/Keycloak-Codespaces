#!/usr/bin/env bash
set +e

echo "============================================================"
echo " DIAGNÓSTICO DE ABERTURA DO KEYCLOAK"
echo "============================================================"

echo
echo "Codespace:"
echo "${CODESPACE_NAME:-não detectado}"

echo
echo "Docker:"
docker --version 2>&1
docker ps 2>&1

echo
echo "Variáveis Keycloak:"
docker inspect keycloak \
  --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null \
  | grep '^KC_' | sort

echo
echo "Teste local:"
curl -sS -o /dev/null -w 'HTTP %{http_code}\n' \
  http://localhost:8080/realms/master

if [[ -n "${CODESPACE_NAME:-}" ]]; then
  DOMAIN="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
  URL="https://${CODESPACE_NAME}-8080.${DOMAIN}"

  echo
  echo "URL pública:"
  echo "$URL"

  echo
  echo "Teste remoto sem token:"
  curl -L -sS -o /dev/null -w 'HTTP %{http_code}\n' \
    "${URL}/realms/master"

  echo
  echo "Issuer:"
  curl -sS \
    http://localhost:8080/realms/master/.well-known/openid-configuration \
    | grep -o '"issuer":"[^"]*"' || true

  if command -v gh >/dev/null 2>&1; then
    echo
    echo "Portas Codespaces:"
    export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
    gh codespace ports \
      -c "${CODESPACE_NAME}" \
      --json sourcePort,visibility,browseUrl 2>&1
  fi
fi

echo
echo "============================================================"
