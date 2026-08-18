#!/usr/bin/env bash
set -euo pipefail

IMAGE="${KEYCLOAK_IMAGE:-quay.io/keycloak/keycloak:latest}"
ADMIN="${KEYCLOAK_ADMIN:-admin}"
PASSWORD="${KEYCLOAK_PASSWORD:-Treinamento@2026}"

docker rm -f keycloak >/dev/null 2>&1 || true

echo "[INFO] Iniciando Keycloak..."
docker run -d   --name keycloak   -p 8080:8080   -e KC_BOOTSTRAP_ADMIN_USERNAME="${ADMIN}"   -e KC_BOOTSTRAP_ADMIN_PASSWORD="${PASSWORD}"   "${IMAGE}"   start-dev

echo "[INFO] Aguardando o Keycloak responder..."

for tentativa in $(seq 1 90); do
  if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
    echo
    echo "[OK] Keycloak disponivel."
    echo "Usuario: ${ADMIN}"
    echo "Senha: ${PASSWORD}"
    echo "No Codespaces, abra a aba PORTAS e clique na URL da porta 8080."
    exit 0
  fi
  printf '.'
  sleep 2
done

echo
echo "[ERRO] O Keycloak nao respondeu no tempo esperado."
docker logs keycloak --tail 100 || true
exit 1
