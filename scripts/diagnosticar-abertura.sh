#!/usr/bin/env bash
set +e

echo "============================================================"
echo " DIAGNOSTICO KEYCLOAK TRAINING"
echo "============================================================"

DOMAIN="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
PUBLIC_URL="https://${CODESPACE_NAME:-SEM-CODESPACE}-8080.${DOMAIN}"

echo
echo "Codespace:"
echo "${CODESPACE_NAME:-nao detectado}"

echo
echo "URL calculada:"
echo "$PUBLIC_URL"

echo
echo "Docker:"
docker --version
docker ps

echo
echo "Variaveis Keycloak:"
docker inspect keycloak \
  --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null \
  | grep '^KC_' | sort

echo
echo "Teste local:"
curl -sS -o /dev/null -w 'HTTP %{http_code}\n' \
  http://localhost:8080/realms/master

echo
echo "Issuer:"
curl -sS \
  http://localhost:8080/realms/master/.well-known/openid-configuration \
  | grep -o '"issuer":"[^"]*"' || true

echo
echo "security-admin-console:"
docker exec keycloak \
  /opt/keycloak/bin/kcadm.sh get clients \
  -r master \
  -q clientId=security-admin-console \
  --fields clientId,redirectUris,webOrigins 2>&1

echo
echo "Teste remoto:"
curl -sS -o /dev/null -w 'HTTP %{http_code}\n' \
  "${PUBLIC_URL}/realms/master"

if command -v gh >/dev/null 2>&1 && [[ -n "${CODESPACE_NAME:-}" ]]; then
  export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

  echo
  echo "Portas Codespaces:"
  gh codespace ports \
    -c "$CODESPACE_NAME" \
    --json sourcePort,visibility,browseUrl 2>&1
fi

echo
echo "Ultimos HTTP 403 do Keycloak:"
docker logs keycloak 2>&1 | grep ' 403 ' | tail -n 30

echo
echo "Ultimos logs:"
docker logs keycloak --tail 100 2>&1

echo
echo "============================================================"
