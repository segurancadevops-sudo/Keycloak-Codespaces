#!/usr/bin/env bash
set -euo pipefail

REPO_EXPECTED="segurancadevops-sudo/Keycloak-Codespaces"
BRANCH_EXPECTED="main"

log(){ printf '\n[%s] %s\n' "$1" "$2"; }
die(){ printf '\n[ERRO] %s\n' "$1" >&2; exit 1; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Execute dentro do repositorio Git."
ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"

CURRENT_BRANCH="$(git branch --show-current)"
[[ "$CURRENT_BRANCH" == "$BRANCH_EXPECTED" ]] || die "Branch atual: $CURRENT_BRANCH"

if [[ -n "$(git status --porcelain)" ]]; then
  git status --short
  die "Existem alteracoes locais nao commitadas."
fi

log INFO "Atualizando repositorio..."
git pull --ff-only origin "$CURRENT_BRANCH"

mkdir -p .devcontainer scripts labs

cat > .devcontainer/devcontainer.json <<'EOF'
{
  "name": "Keycloak Training Codespace",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:4": {
      "moby": false
    }
  },
  "forwardPorts": [8080],
  "portsAttributes": {
    "8080": {
      "label": "Keycloak",
      "onAutoForward": "notify"
    }
  },
  "postCreateCommand": "docker --version && echo 'Ambiente Keycloak Training pronto.'"
}
EOF

cat > scripts/iniciar-keycloak.sh <<'EOF'
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
EOF

cat > scripts/status-keycloak.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
docker ps -a --filter name='^keycloak$'
if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
  echo "[OK] Keycloak respondendo em http://localhost:8080"
else
  echo "[AVISO] Keycloak nao responde na porta 8080."
fi
EOF

cat > scripts/parar-keycloak.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
docker stop keycloak >/dev/null 2>&1 || true
echo "[OK] Keycloak parado."
EOF

cat > scripts/resetar-laboratorio.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker rm -f keycloak >/dev/null 2>&1 || true
"${SCRIPT_DIR}/iniciar-keycloak.sh"
EOF

cat > scripts/logs-keycloak.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
docker logs -f --tail 100 keycloak
EOF

chmod +x scripts/*.sh
find scripts -maxdepth 1 -type f -name '*~' -delete

touch .gitignore
grep -qxF '*~' .gitignore || echo '*~' >> .gitignore
grep -qxF '*.swp' .gitignore || echo '*.swp' >> .gitignore

python3 - <<'PY'
import json
json.load(open(".devcontainer/devcontainer.json"))
print("[OK] devcontainer.json valido")
PY

bash -n scripts/iniciar-keycloak.sh
bash -n scripts/status-keycloak.sh
bash -n scripts/parar-keycloak.sh
bash -n scripts/resetar-laboratorio.sh
bash -n scripts/logs-keycloak.sh

git add .devcontainer scripts .gitignore
git add -u

if [[ -n "$(git status --porcelain)" ]]; then
  git commit -m "Corrige Docker e Keycloak no GitHub Codespaces"
  git push origin "$CURRENT_BRANCH"
fi

echo
echo "============================================================"
echo "REPOSITORIO PRONTO"
echo "============================================================"
echo 'Correcao aplicada: "moby": false'
echo
echo "Crie um NOVO Codespace a partir da branch main."
echo
echo "No novo Codespace, rode:"
echo "  docker --version"
echo "  docker ps"
echo "  ./scripts/iniciar-keycloak.sh"
echo

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  read -r -p "Deseja abrir a criacao de um novo Codespace no navegador agora? [s/N] " RESP
  case "${RESP,,}" in
    s|sim|y|yes)
      gh codespace create -R "$REPO_EXPECTED" -b "$CURRENT_BRANCH" -w
      ;;
  esac
fi
