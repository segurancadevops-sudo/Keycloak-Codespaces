#!/usr/bin/env bash
set -Eeuo pipefail

CONTAINER="keycloak"
ADMIN="${KEYCLOAK_ADMIN:-admin}"
PASSWORD="${KEYCLOAK_PASSWORD:-Treinamento@2026}"

[[ -n "${CODESPACE_NAME:-}" ]] || {
  echo "[ERRO] CODESPACE_NAME ausente."
  exit 1
}

DOMAIN="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
PUBLIC_URL="https://${CODESPACE_NAME}-8080.${DOMAIN}"
TOKEN_URL="${PUBLIC_URL}/realms/master/protocol/openid-connect/token"

echo "============================================================"
echo " VALIDACAO KEYCLOAK TRAINING"
echo "============================================================"

docker info >/dev/null 2>&1
echo "[OK] Docker"

docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"
echo "[OK] Container"

curl -fsS http://localhost:8080/realms/master >/dev/null
echo "[OK] Realm master"

ISSUER="$(
  curl -fsS http://localhost:8080/realms/master/.well-known/openid-configuration \
  | sed -n 's/.*"issuer":"\([^"]*\)".*/\1/p' \
  | head -n1
)"

[[ "$ISSUER" == "${PUBLIC_URL}/realms/master" ]]
echo "[OK] Issuer"

docker exec "$CONTAINER" \
  /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user "$ADMIN" \
  --password "$PASSWORD" >/dev/null

docker exec "$CONTAINER" \
  /opt/keycloak/bin/kcadm.sh get realms \
  --fields realm >/dev/null
echo "[OK] Administrador e Admin REST API"

CLIENT="$(
  docker exec "$CONTAINER" \
    /opt/keycloak/bin/kcadm.sh get clients \
    -r master \
    -q clientId=security-admin-console \
    --fields clientId,redirectUris,webOrigins
)"

echo "$CLIENT" | grep -Fq "$PUBLIC_URL"
echo "[OK] security-admin-console"

HTTP="$(curl -sS -o /dev/null -w '%{http_code}' "${PUBLIC_URL}/realms/master")"
[[ "$HTTP" == "200" ]]
echo "[OK] URL publica"

TOKEN_STATUS="$(
  curl -sS -o /dev/null -w '%{http_code}' \
    -X POST "$TOKEN_URL" \
    -H "Origin: ${PUBLIC_URL}" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'client_id=security-admin-console' \
    --data-urlencode 'grant_type=authorization_code' \
    --data-urlencode 'code=self-test-invalido' \
    --data-urlencode "redirect_uri=${PUBLIC_URL}/admin/master/console/" \
    --data-urlencode 'code_verifier=self-test-invalido'
)"

[[ "$TOKEN_STATUS" != "403" ]]
echo "[OK] CORS /token nao retorna 403"

echo
echo "[OK] LABORATORIO FUNCIONAL"
echo "${PUBLIC_URL}/admin/"
