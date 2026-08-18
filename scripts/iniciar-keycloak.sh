#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE="${KEYCLOAK_IMAGE:-quay.io/keycloak/keycloak:latest}"
ADMIN="${KEYCLOAK_ADMIN:-admin}"
PASSWORD="${KEYCLOAK_PASSWORD:-Treinamento@2026}"
CONTAINER_NAME="keycloak"

echo "[INFO] Validando Docker..."

for tentativa in $(seq 1 60); do
    if docker info >/dev/null 2>&1; then
        echo "[OK] Docker Engine pronto."
        break
    fi

    if [[ "$tentativa" -eq 60 ]]; then
        echo "[ERRO] Docker não ficou disponível."
        exit 1
    fi

    sleep 2
done

echo "[INFO] Removendo container anterior..."
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

echo "[INFO] Iniciando Keycloak..."

docker run -d \
    --name "${CONTAINER_NAME}" \
    -p 8080:8080 \
    -e KC_BOOTSTRAP_ADMIN_USERNAME="${ADMIN}" \
    -e KC_BOOTSTRAP_ADMIN_PASSWORD="${PASSWORD}" \
    "${IMAGE}" \
    start-dev >/dev/null

echo "[INFO] Aguardando o Keycloak ficar pronto..."

for tentativa in $(seq 1 120); do

    if curl -fsS \
        http://localhost:8080/realms/master \
        >/dev/null 2>&1; then

        echo
        echo "[OK] Keycloak respondeu."

        if [[ -n "${CODESPACE_NAME:-}" ]]; then
            KEYCLOAK_URL="https://${CODESPACE_NAME}-8080.app.github.dev"
        else
            KEYCLOAK_URL="http://localhost:8080"
        fi

        echo
        echo "============================================================"
        echo " KEYCLOAK TRAINING ACADEMY"
        echo "============================================================"
        echo
        echo "Serviço pronto para utilização."
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
        echo "============================================================"

        exit 0
    fi

    if ! docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
        echo
        echo "[ERRO] O container Keycloak encerrou."

        docker logs "${CONTAINER_NAME}" --tail 100 || true
        exit 1
    fi

    printf "."
    sleep 2
done

echo
echo "[ERRO] Keycloak não ficou pronto após 240 segundos."
docker logs "${CONTAINER_NAME}" --tail 100 || true
exit 1