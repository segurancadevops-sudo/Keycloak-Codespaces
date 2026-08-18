if [[ -n "${CODESPACE_NAME:-}" ]]; then
    KEYCLOAK_URL="https://${CODESPACE_NAME}-8080.app.github.dev"

    echo
    echo "[OK] Keycloak disponível."
    echo
    echo "Usuário: ${ADMIN}"
    echo "Senha: ${PASSWORD}"
    echo
    echo "Acesse:"
    echo "${KEYCLOAK_URL}"
    echo
    echo "Console administrativo:"
    echo "${KEYCLOAK_URL}/admin/"
else
    echo
    echo "[OK] Keycloak disponível em:"
    echo "http://localhost:8080"
fi