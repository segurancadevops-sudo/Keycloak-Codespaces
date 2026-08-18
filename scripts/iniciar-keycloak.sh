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
  echo "[ERRO] Docker não está disponível neste ambiente."
  echo "[AÇÃO] Crie um Codespace novo a partir da branch main."
  exit 1
fi

echo "[INFO] Aguardando Docker Engine ficar pronto..."

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
docker --version
echo

echo "[INFO] Removendo container anterior, se existir..."
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

echo "[INFO] Iniciando Keycloak..."

docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME="${ADMIN}" \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD="${PASSWORD}" \
  "${IMAGE}" \
  start-dev >/dev/null

echo "[INFO] Container criado."
echo "[INFO] Aguardando o Keycloak ficar pronto..."

KEYCLOAK_READY=false

for tentativa in $(seq 1 120); do

  if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
    KEYCLOAK_READY=true
    break
  fi

  if ! docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
    echo
    echo "[ERRO] O container Keycloak encerrou durante a inicialização."
    echo
    echo "[INFO] Últimos logs:"
    docker logs "${CONTAINER_NAME}" --tail 120 || true
    exit 1
  fi

  printf "."
  sleep 2
done

echo

if [[ "$KEYCLOAK_READY" != "true" ]]; then
  echo "[ERRO] Keycloak não ficou pronto após 240 segundos."
  echo
  echo "[INFO] Últimos logs:"
  docker logs "${CONTAINER_NAME}" --tail 120 || true
  exit 1
fi

echo "[OK] Keycloak respondeu ao health check funcional."
echo "[OK] Serviço pronto para utilização."
echo

if [[ -n "${CODESPACE_NAME:-}" ]]; then
  KEYCLOAK_URL="https://${CODESPACE_NAME}-8080.app.github.dev"
else
  KEYCLOAK_URL="http://localhost:8080"
fi

echo "============================================================"
echo " ACESSO AO LABORATÓRIO"
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

if [[ -n "${CODESPACE_NAME:-}" ]]; then
  echo "IMPORTANTE:"
  echo "Não adicione :8080 ao final da URL do GitHub Codespaces."
  echo
fi

echo "============================================================"
