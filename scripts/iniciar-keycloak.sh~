#!/usr/bin/env bash
set -euo pipefail

docker rm -f keycloak 2>/dev/null || true

docker run -d \
  --name keycloak \
  -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD='Treinamento@2026' \
  quay.io/keycloak/keycloak:latest \
  start-dev

echo "Aguardando o Keycloak..."

until curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; do
  sleep 2
done

echo
echo "Keycloak disponível na porta 8080."
echo "Usuário: admin"
echo "Senha: Treinamento@2026"
