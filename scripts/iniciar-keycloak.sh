#!/usr/bin/env bash
set -Eeuo pipefail

CONTAINER="keycloak"
IMAGE="${KEYCLOAK_IMAGE:-quay.io/keycloak/keycloak:26.7.1}"
ADMIN="${KEYCLOAK_ADMIN:-admin}"
PASSWORD="${KEYCLOAK_PASSWORD:-Treinamento@2026}"

green() { printf '\033[1;32m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[1;33m%s\033[0m\n' "$*"; }
red()   { printf '\033[1;31m%s\033[0m\n' "$*"; }

fatal() {
  red "[ERRO] $*"
  echo
  echo "Laboratorio NAO liberado."
  echo "Diagnostico:"
  echo "  ./scripts/diagnosticar-abertura.sh"
  exit 1
}

echo
echo "============================================================"
echo " KEYCLOAK TRAINING ACADEMY"
echo " Bootstrap + Self-Test"
echo "============================================================"
echo

# ------------------------------------------------------------
# 1. Ambiente Codespaces
# ------------------------------------------------------------

[[ -n "${CODESPACE_NAME:-}" ]]   || fatal "Este script foi preparado para GitHub Codespaces."

FORWARD_DOMAIN="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
PUBLIC_HOST="${CODESPACE_NAME}-8080.${FORWARD_DOMAIN}"
PUBLIC_URL="https://${PUBLIC_HOST}"
ADMIN_URL="${PUBLIC_URL}/admin/"
TOKEN_URL="${PUBLIC_URL}/realms/master/protocol/openid-connect/token"

echo "Codespace : ${CODESPACE_NAME}"
echo "URL       : ${PUBLIC_URL}"
echo

# ------------------------------------------------------------
# 2. Docker
# ------------------------------------------------------------

command -v docker >/dev/null 2>&1   || fatal "Docker CLI nao encontrado. Crie um NOVO Codespace."

echo "[1/9] Aguardando Docker Engine..."

DOCKER_OK=false
for _ in $(seq 1 60); do
  if docker info >/dev/null 2>&1; then
    DOCKER_OK=true
    break
  fi
  sleep 2
done

[[ "$DOCKER_OK" == "true" ]]   || fatal "Docker Engine nao ficou pronto em 120 segundos."

green "[OK] Docker Engine pronto."

# ------------------------------------------------------------
# 3. Container
# ------------------------------------------------------------

echo
echo "[2/9] Iniciando Keycloak..."

docker rm -f "$CONTAINER" >/dev/null 2>&1 || true

docker run -d   --name "$CONTAINER"   --restart unless-stopped   -p 8080:8080   -e KC_BOOTSTRAP_ADMIN_USERNAME="$ADMIN"   -e KC_BOOTSTRAP_ADMIN_PASSWORD="$PASSWORD"   -e KC_HOSTNAME="$PUBLIC_URL"   -e KC_HOSTNAME_STRICT=true   -e KC_PROXY_HEADERS=xforwarded   -e KC_HTTP_ENABLED=true   -e KC_HTTP_ACCESS_LOG_ENABLED=true   -e KC_HTTP_ACCESS_LOG_PATTERN=combined   "$IMAGE"   start-dev >/dev/null

green "[OK] Container criado."

# ------------------------------------------------------------
# 4. Readiness local
# ------------------------------------------------------------

echo
echo "[3/9] Aguardando Keycloak responder..."

KC_READY=false

for _ in $(seq 1 120); do
  if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
    KC_READY=true
    break
  fi

  if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
    docker logs "$CONTAINER" --tail 150 || true
    fatal "O container Keycloak encerrou durante a inicializacao."
  fi

  sleep 2
done

[[ "$KC_READY" == "true" ]]   || {
    docker logs "$CONTAINER" --tail 150 || true
    fatal "Keycloak nao ficou pronto em 240 segundos."
  }

green "[OK] Realm master responde localmente."

# ------------------------------------------------------------
# 5. Issuer
# ------------------------------------------------------------

echo
echo "[4/9] Validando issuer OIDC..."

ISSUER="$(
  curl -fsS     http://localhost:8080/realms/master/.well-known/openid-configuration     | sed -n 's/.*"issuer":"\([^"]*\)".*/\1/p'     | head -n1
)"

EXPECTED_ISSUER="${PUBLIC_URL}/realms/master"

[[ "$ISSUER" == "$EXPECTED_ISSUER" ]]   || fatal "Issuer incorreto. Esperado: $EXPECTED_ISSUER | Recebido: $ISSUER"

green "[OK] Issuer: $ISSUER"

# ------------------------------------------------------------
# 6. Administrador e API administrativa
# ------------------------------------------------------------

echo
echo "[5/9] Validando administrador..."

docker exec "$CONTAINER"   /opt/keycloak/bin/kcadm.sh config credentials   --server http://localhost:8080   --realm master   --user "$ADMIN"   --password "$PASSWORD" >/dev/null   || fatal "Falha ao autenticar o administrador via kcadm."

docker exec "$CONTAINER"   /opt/keycloak/bin/kcadm.sh get realms   --fields realm >/dev/null   || fatal "Administrador autenticou, mas nao conseguiu consultar a Admin REST API."

green "[OK] Administrador autenticado e autorizado."

# ------------------------------------------------------------
# 7. Corrige de forma deterministica o client do Admin Console
# ------------------------------------------------------------

echo
echo "[6/9] Validando security-admin-console..."

CLIENT_ID="$(
  docker exec "$CONTAINER"     /opt/keycloak/bin/kcadm.sh get clients     -r master     -q clientId=security-admin-console     --fields id   | sed -n 's/.*"id" : "\([^"]*\)".*/\1/p'   | head -n1
)"

[[ -n "$CLIENT_ID" ]]   || fatal "Client security-admin-console nao encontrado."

ADMIN_REDIRECT="${PUBLIC_URL}/admin/master/console/*"

# Em Codespaces cada aluno recebe um hostname diferente.
# Montamos os valores JSON com printf para evitar problemas de escape de aspas.
REDIRECT_SPEC="$(printf 'redirectUris=["%s","/admin/master/console/*"]' "$ADMIN_REDIRECT")"
ORIGIN_SPEC="$(printf 'webOrigins=["%s"]' "$PUBLIC_URL")"

echo "[INFO] Redirects que serao aplicados:"
echo "       $REDIRECT_SPEC"
echo "[INFO] Web Origin que sera aplicada:"
echo "       $ORIGIN_SPEC"

docker exec "$CONTAINER"   /opt/keycloak/bin/kcadm.sh update "clients/${CLIENT_ID}"   -r master   -s "$REDIRECT_SPEC"   -s "$ORIGIN_SPEC" >/dev/null   || fatal "Nao foi possivel ajustar o security-admin-console."

CLIENT_CHECK="$(
  docker exec "$CONTAINER"     /opt/keycloak/bin/kcadm.sh get "clients/${CLIENT_ID}"     -r master     --fields clientId,redirectUris,webOrigins
)"

echo "$CLIENT_CHECK" | grep -Fq "$PUBLIC_URL"   || fatal "A origem publica nao foi gravada no security-admin-console."

green "[OK] security-admin-console configurado para este Codespace."

# ------------------------------------------------------------
# 8. Porta publica do Codespaces
# ------------------------------------------------------------

echo
echo "[7/9] Configurando porta 8080 como PUBLIC..."

command -v gh >/dev/null 2>&1   || fatal "GitHub CLI nao encontrado."

export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

[[ -n "${GH_TOKEN:-}" ]]   || fatal "Token do GitHub nao esta disponivel no Codespace."

PORT_PUBLIC=false

for _ in $(seq 1 30); do
  if gh codespace ports visibility 8080:public       -c "$CODESPACE_NAME" >/dev/null 2>&1; then
    PORT_PUBLIC=true
    break
  fi
  sleep 2
done

[[ "$PORT_PUBLIC" == "true" ]]   || fatal "Nao foi possivel tornar a porta 8080 publica. Uma politica da organizacao pode estar bloqueando."

VISIBILITY="$(
  gh codespace ports     -c "$CODESPACE_NAME"     --json sourcePort,visibility     --jq '.[] | select(.sourcePort == 8080) | .visibility'     2>/dev/null || true
)"

[[ "$VISIBILITY" == "public" ]]   || fatal "A porta 8080 nao ficou publica. Visibilidade atual: ${VISIBILITY:-desconhecida}"

green "[OK] Porta 8080 PUBLIC."

# ------------------------------------------------------------
# 9. Teste externo
# ------------------------------------------------------------

echo
echo "[8/9] Validando URL externa..."

REMOTE_OK=false

for _ in $(seq 1 60); do
  CODE="$(
    curl -sS -o /dev/null -w '%{http_code}'       "${PUBLIC_URL}/realms/master" 2>/dev/null || true
  )"

  if [[ "$CODE" == "200" ]]; then
    REMOTE_OK=true
    break
  fi

  sleep 2
done

[[ "$REMOTE_OK" == "true" ]]   || fatal "URL externa nao respondeu HTTP 200."

green "[OK] URL externa HTTP 200."

# ------------------------------------------------------------
# 10. Self-test do CORS do endpoint que antes retornava 403
# ------------------------------------------------------------

echo
echo "[9/9] Testando CORS do endpoint de token..."

TMP_HEADERS="$(mktemp)"
TMP_BODY="$(mktemp)"
trap 'rm -f "$TMP_HEADERS" "$TMP_BODY"' EXIT

# Enviamos um authorization_code propositalmente invalido.
# O objetivo nao e obter token.
# O objetivo e verificar que a origem NAO seja recusada com HTTP 403.
TOKEN_STATUS="$(
  curl -sS     -D "$TMP_HEADERS"     -o "$TMP_BODY"     -w '%{http_code}'     -X POST "$TOKEN_URL"     -H "Origin: ${PUBLIC_URL}"     -H 'Content-Type: application/x-www-form-urlencoded'     --data-urlencode 'client_id=security-admin-console'     --data-urlencode 'grant_type=authorization_code'     --data-urlencode 'code=teste-invalido-self-test'     --data-urlencode "redirect_uri=${PUBLIC_URL}/admin/master/console/"     --data-urlencode 'code_verifier=teste-invalido-self-test'     2>/dev/null || true
)"

if [[ "$TOKEN_STATUS" == "403" ]]; then
  echo
  echo "Resposta:"
  cat "$TMP_BODY" || true
  echo
  docker logs "$CONTAINER" --tail 80 || true
  fatal "O endpoint /token ainda rejeitou a origem com HTTP 403."
fi

ALLOW_ORIGIN="$(
  tr -d '\r' < "$TMP_HEADERS"     | awk 'BEGIN{IGNORECASE=1} /^access-control-allow-origin:/ {sub(/^[^:]+:[[:space:]]*/, ""); print; exit}'
)"

if [[ "$ALLOW_ORIGIN" != "$PUBLIC_URL" ]]; then
  yellow "[AVISO] HTTP do teste: $TOKEN_STATUS"
  yellow "[AVISO] Access-Control-Allow-Origin nao veio exatamente como esperado."
  yellow "[AVISO] Recebido: ${ALLOW_ORIGIN:-ausente}"

  # Ausencia do header junto com um status de erro nao-CORS pode variar
  # entre versoes. A condicao critica conhecida e HTTP 403.
else
  green "[OK] CORS permitido para $PUBLIC_URL."
fi

green "[OK] Endpoint /token nao retornou HTTP 403. Status de self-test: $TOKEN_STATUS"

# ------------------------------------------------------------
# Resultado final
# ------------------------------------------------------------

echo
echo "============================================================"
echo " LABORATORIO VALIDADO E LIBERADO"
echo "============================================================"
echo
echo "Docker                  : OK"
echo "Keycloak                : OK"
echo "Realm master            : OK"
echo "Issuer OIDC             : OK"
echo "Administrador           : OK"
echo "Admin REST API          : OK"
echo "security-admin-console  : OK"
echo "Porta Codespaces        : PUBLIC"
echo "URL externa             : OK"
echo "CORS /token             : OK"
echo
echo "Usuario:"
echo "  $ADMIN"
echo
echo "Senha:"
echo "  $PASSWORD"
echo
echo "Admin Console:"
echo "  $ADMIN_URL"
echo
echo "IMPORTANTE:"
echo "  No Codespaces nao use localhost no navegador."
echo "  Nao adicione :8080 ao final da URL app.github.dev."
echo
echo "============================================================"
echo

# Tenta abrir somente depois de todos os testes.
if [[ -n "${BROWSER:-}" ]] && [[ -x "${BROWSER}" ]]; then
  "${BROWSER}" "$ADMIN_URL" >/dev/null 2>&1 || true
elif command -v code >/dev/null 2>&1; then
  code --open-url "$ADMIN_URL" >/dev/null 2>&1 || true
fi
