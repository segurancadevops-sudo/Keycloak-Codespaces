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
  echo "[AÇÃO] Execute: ./scripts/diagnosticar-lab.sh"
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
  echo "[ERRO] Docker Engine não ficou disponível."
  exit 1
fi

echo "[OK] Docker Engine pronto."
docker --version
echo

# ------------------------------------------------------------
# Define URL externa correta
# ------------------------------------------------------------

if [[ -n "${CODESPACE_NAME:-}" ]]; then
  KEYCLOAK_URL="https://${CODESPACE_NAME}-8080.app.github.dev"
  HOSTNAME_MODE="codespaces"
else
  KEYCLOAK_URL="http://localhost:8080"
  HOSTNAME_MODE="local"
fi

echo "[INFO] Modo: ${HOSTNAME_MODE}"
echo "[INFO] URL esperada: ${KEYCLOAK_URL}"
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

if [[ "$HOSTNAME_MODE" == "codespaces" ]]; then
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

echo "[INFO] Aguardando o Keycloak ficar pronto..."

KEYCLOAK_READY=false
for tentativa in $(seq 1 120); do
  if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
    KEYCLOAK_READY=true
    break
  fi

  if ! docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
    echo
    echo "[ERRO] O container Keycloak encerrou."
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
echo

# ------------------------------------------------------------
# Validação do issuer
# ------------------------------------------------------------

ISSUER="$(
  curl -fsS http://localhost:8080/realms/master/.well-known/openid-configuration \
  | python3 -c 'import sys,json; print(json.load(sys.stdin).get("issuer",""))' \
  2>/dev/null || true
)"

if [[ -n "$ISSUER" ]]; then
  echo "[INFO] Issuer informado pelo Keycloak:"
  echo "$ISSUER"
  echo

  if [[ "$HOSTNAME_MODE" == "codespaces" ]]; then
    EXPECTED_ISSUER="${KEYCLOAK_URL}/realms/master"

    if [[ "$ISSUER" != "$EXPECTED_ISSUER" ]]; then
      echo "[ERRO] Issuer incorreto."
      echo "Esperado:"
      echo "$EXPECTED_ISSUER"
      echo
      echo "Recebido:"
      echo "$ISSUER"
      echo
      echo "[INFO] Logs do Keycloak:"
      docker logs "${CONTAINER_NAME}" --tail 120 || true
      exit 1
    fi

    echo "[OK] Issuer aponta para a URL pública do Codespaces."
  else
    echo "[OK] Issuer disponível no modo local."
  fi
else
  echo "[AVISO] Não foi possível extrair o issuer."
fi

echo
echo "============================================================"
echo " SERVIÇO PRONTO"
echo "============================================================"
echo
echo "Usuário: ${ADMIN}"
echo "Senha:   ${PASSWORD}"
echo
echo "Acesse:"
echo "${KEYCLOAK_URL}"
echo
echo "Console administrativo:"
echo "${KEYCLOAK_URL}/admin/"
echo

if [[ "$HOSTNAME_MODE" == "codespaces" ]]; then
  echo "IMPORTANTE:"
  echo "Não adicione :8080 ao final da URL do Codespaces."
  echo "Cada aluno deve usar a URL do próprio Codespace."
  echo
fi

echo "============================================================"
