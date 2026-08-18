#!/usr/bin/env bash
set -Eeuo pipefail
IMAGE="${KEYCLOAK_IMAGE:-quay.io/keycloak/keycloak:latest}"
ADMIN="${KEYCLOAK_ADMIN:-admin}"
PASSWORD="${KEYCLOAK_PASSWORD:-Treinamento@2026}"
CONTAINER_NAME="keycloak"

command -v docker >/dev/null 2>&1 || { echo "[ERRO] Docker não disponível. Rode ./scripts/diagnosticar-lab.sh"; exit 1; }
docker info >/dev/null 2>&1 || { echo "[ERRO] Docker Engine não responde."; exit 1; }

echo "[INFO] Docker:"
docker --version

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

echo "[INFO] Iniciando Keycloak..."
docker run -d   --name "${CONTAINER_NAME}"   --restart unless-stopped   -p 8080:8080   -e KC_BOOTSTRAP_ADMIN_USERNAME="${ADMIN}"   -e KC_BOOTSTRAP_ADMIN_PASSWORD="${PASSWORD}"   "${IMAGE}"   start-dev >/dev/null

echo "[INFO] Aguardando o Keycloak responder..."
for tentativa in $(seq 1 120); do
  if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
    if [[ -n "${CODESPACE_NAME:-}" ]]; then
      KEYCLOAK_URL="https://${CODESPACE_NAME}-8080.app.github.dev"
    else
      KEYCLOAK_URL="http://localhost:8080"
    fi
    echo
    echo "============================================================"
    echo " KEYCLOAK TRAINING ACADEMY"
    echo "============================================================"
    echo "[OK] Keycloak disponível."
    echo "Usuário: ${ADMIN}"
    echo "Senha:   ${PASSWORD}"
    echo "Acesso:  ${KEYCLOAK_URL}"
    echo "Admin:   ${KEYCLOAK_URL}/admin/"
    [[ -n "${CODESPACE_NAME:-}" ]] && echo "IMPORTANTE: não acrescente :8080 ao final da URL do Codespaces."
    echo "============================================================"
    exit 0
  fi
  if ! docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
    echo "[ERRO] Container Keycloak encerrou durante a inicialização."
    docker logs "${CONTAINER_NAME}" --tail 120 || true
    exit 1
  fi
  printf '.'
  sleep 2
done

echo "[ERRO] Timeout aguardando Keycloak."
docker logs "${CONTAINER_NAME}" --tail 120 || true
exit 1
