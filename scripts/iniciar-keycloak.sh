#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE="${KEYCLOAK_IMAGE:-quay.io/keycloak/keycloak:latest}"
ADMIN="${KEYCLOAK_ADMIN:-admin}"
PASSWORD="${KEYCLOAK_PASSWORD:-Treinamento@2026}"
CONTAINER_NAME="keycloak"

echo "============================================================"
echo " KEYCLOAK TRAINING ACADEMY"
echo "============================================================"
echo

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERRO] Docker não está disponível."
  echo "[AÇÃO] Este Codespace provavelmente foi criado antes da configuração atual."
  echo "[AÇÃO] Exclua-o e crie um NOVO Codespace a partir da branch main."
  exit 1
fi

echo "[INFO] Aguardando Docker Engine..."

DOCKER_READY=false
for tentativa in $(seq 1 60); do
  if docker info >/dev/null 2>&1; then
    DOCKER_READY=true
    break
  fi
  printf "."
  sleep 2
done
echo

if [[ "$DOCKER_READY" != "true" ]]; then
  echo "[ERRO] Docker Engine não ficou disponível após 120 segundos."
  exit 1
fi

echo "[OK] Docker Engine pronto."

# ------------------------------------------------------------
# URL do Codespaces
# ------------------------------------------------------------

if [[ -n "${CODESPACE_NAME:-}" ]]; then
  FORWARD_DOMAIN="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
  KEYCLOAK_URL="https://${CODESPACE_NAME}-8080.${FORWARD_DOMAIN}"
  MODO="codespaces"
else
  KEYCLOAK_URL="http://localhost:8080"
  MODO="local"
fi

echo "[INFO] Modo: ${MODO}"
echo "[INFO] URL: ${KEYCLOAK_URL}"
echo

# ------------------------------------------------------------
# Porta pública no Codespaces
# ------------------------------------------------------------

if [[ "$MODO" == "codespaces" ]]; then
  echo "[INFO] Preparando porta 8080 para acesso do aluno..."

  if command -v gh >/dev/null 2>&1; then
    export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

    PORT_PUBLIC=false

    for tentativa in $(seq 1 30); do
      if gh codespace ports visibility 8080:public \
           -c "${CODESPACE_NAME}" >/dev/null 2>&1; then
        PORT_PUBLIC=true
        break
      fi
      printf "."
      sleep 2
    done
    echo

    if [[ "$PORT_PUBLIC" == "true" ]]; then
      echo "[OK] Porta 8080 configurada como PUBLIC."
    else
      echo "[AVISO] O GitHub não permitiu tornar a porta pública automaticamente."
      echo "[AVISO] Pode existir uma política da organização bloqueando portas públicas."
      echo "[AÇÃO] Na aba PORTS, altere Port Visibility para Public."
    fi
  else
    echo "[AVISO] GitHub CLI não disponível."
  fi
fi

# ------------------------------------------------------------
# Sobe Keycloak
# ------------------------------------------------------------

echo
echo "[INFO] Removendo container anterior..."
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

echo "[INFO] Iniciando Keycloak..."

DOCKER_ARGS=(
  run -d
  --name "${CONTAINER_NAME}"
  --restart unless-stopped
  -p 8080:8080
  -e KC_BOOTSTRAP_ADMIN_USERNAME="${ADMIN}"
  -e KC_BOOTSTRAP_ADMIN_PASSWORD="${PASSWORD}"
)

if [[ "$MODO" == "codespaces" ]]; then
  DOCKER_ARGS+=(
    -e KC_HOSTNAME="${KEYCLOAK_URL}"
    -e KC_HOSTNAME_STRICT="true"
    -e KC_PROXY_HEADERS="xforwarded"
  )
fi

DOCKER_ARGS+=(
  "${IMAGE}"
  start-dev
)

docker "${DOCKER_ARGS[@]}" >/dev/null

echo "[INFO] Container criado."
echo "[INFO] Aguardando Keycloak ficar pronto..."

KEYCLOAK_READY=false

for tentativa in $(seq 1 120); do
  if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
    KEYCLOAK_READY=true
    break
  fi

  if ! docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
    echo
    echo "[ERRO] Container Keycloak encerrou."
    docker logs "${CONTAINER_NAME}" --tail 120 || true
    exit 1
  fi

  printf "."
  sleep 2
done
echo

if [[ "$KEYCLOAK_READY" != "true" ]]; then
  echo "[ERRO] Keycloak não ficou pronto após 240 segundos."
  docker logs "${CONTAINER_NAME}" --tail 120 || true
  exit 1
fi

echo "[OK] Keycloak respondeu localmente."

# ------------------------------------------------------------
# Valida issuer
# ------------------------------------------------------------

ISSUER="$(
  curl -fsS \
    http://localhost:8080/realms/master/.well-known/openid-configuration \
  | sed -n 's/.*"issuer":"\([^"]*\)".*/\1/p' \
  | head -n1
)"

EXPECTED_ISSUER="${KEYCLOAK_URL}/realms/master"

if [[ "$ISSUER" == "$EXPECTED_ISSUER" ]]; then
  echo "[OK] Issuer correto."
else
  echo "[ERRO] Issuer incorreto."
  echo "Esperado: ${EXPECTED_ISSUER}"
  echo "Recebido: ${ISSUER}"
  exit 1
fi

# ------------------------------------------------------------
# Valida URL remota PUBLIC
# ------------------------------------------------------------

if [[ "$MODO" == "codespaces" ]]; then
  echo "[INFO] Validando acesso externo..."

  REMOTE_READY=false

  for tentativa in $(seq 1 60); do
    HTTP_CODE="$(
      curl -L -sS -o /dev/null -w '%{http_code}' \
        "${KEYCLOAK_URL}/realms/master" 2>/dev/null || true
    )"

    if [[ "$HTTP_CODE" == "200" ]]; then
      REMOTE_READY=true
      break
    fi

    printf "."
    sleep 2
  done
  echo

  if [[ "$REMOTE_READY" == "true" ]]; then
    echo "[OK] URL pública respondendo HTTP 200."
  else
    echo "[AVISO] A URL externa não respondeu HTTP 200 sem autenticação do GitHub."
    echo "[AVISO] Verifique se a porta 8080 está realmente PUBLIC na aba PORTS."
  fi
fi

# ------------------------------------------------------------
# Entrega ao aluno
# ------------------------------------------------------------

echo
echo "============================================================"
echo " LABORATÓRIO PRONTO"
echo "============================================================"
echo
echo "Usuário: ${ADMIN}"
echo "Senha:   ${PASSWORD}"
echo
echo "Keycloak:"
echo "${KEYCLOAK_URL}"
echo
echo "Console administrativo:"
echo "${KEYCLOAK_URL}/admin/"
echo
echo "IMPORTANTE:"
echo "Use a URL app.github.dev exibida acima."
echo "Não use localhost no navegador."
echo "Não acrescente :8080 ao final da URL do Codespaces."
echo "============================================================"
echo

# Tenta abrir somente depois de todos os checks.
if [[ "$MODO" == "codespaces" ]] && command -v code >/dev/null 2>&1; then
  echo "[INFO] Tentando abrir o Admin Console no navegador..."
  code --open-url "${KEYCLOAK_URL}/admin/" >/dev/null 2>&1 || true
fi
