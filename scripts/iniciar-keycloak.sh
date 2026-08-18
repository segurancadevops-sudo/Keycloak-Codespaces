#!/usr/bin/env bash
set -euo pipefail

IMAGE="${KEYCLOAK_IMAGE:-quay.io/keycloak/keycloak:latest}"
ADMIN="${KEYCLOAK_ADMIN:-admin}"
PASSWORD="${KEYCLOAK_PASSWORD:-Treinamento@2026}"
CONTAINER_NAME="keycloak"

command -v docker >/dev/null 2>&1 || {
  echo "[ERRO] Docker nao esta disponivel."
  echo "[DICA] Exclua o Codespace antigo e crie um novo a partir da branch main."
  exit 1
}

echo "[INFO] Docker:"
docker --version

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

echo "[INFO] Iniciando Keycloak..."
docker run -d   --name "${CONTAINER_NAME}"   -p 8080:8080   -e KC_BOOTSTRAP_ADMIN_USERNAME="${ADMIN}"   -e KC_BOOTSTRAP_ADMIN_PASSWORD="${PASSWORD}"   "${IMAGE}"   start-dev >/dev/null

echo "[INFO] Aguardando o Keycloak responder..."

for tentativa in $(seq 1 90); do
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
    echo "[OK] Keycloak disponivel."
    echo "Usuario: ${ADMIN}"
    echo "Senha: ${PASSWORD}"
    echo "Acesse: ${KEYCLOAK_URL}"
    echo "Admin: ${KEYCLOAK_URL}/admin/"
    echo "============================================================"
    exit 0
  fi
  printf '.'
  sleep 2
done

echo
echo "[ERRO] O Keycloak nao respondeu no tempo esperado."
docker logs "${CONTAINER_NAME}" --tail 100 || true
exit 1
