#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Keycloak Codespaces - Readiness Fix Automático
# ============================================================
# Corrige:
# - .devcontainer/devcontainer.json
# - scripts/iniciar-keycloak.sh
# - espera ativa do Docker Engine
# - espera ativa do Keycloak
# - evita abrir navegador antes do serviço estar pronto
# - valida JSON e Bash
# - commit + push automáticos
#
# Execute na raiz do projeto:
#   cd ~/Projetos/Keycloak-Codespaces
#   chmod +x corrigir_readiness_keycloak_codespaces.sh
#   ./corrigir_readiness_keycloak_codespaces.sh
# ============================================================

BRANCH_EXPECTED="main"

info() { printf '\n[INFO] %s\n' "$*"; }
ok()   { printf '\n[OK] %s\n' "$*"; }
die()  { printf '\n[ERRO] %s\n' "$*" >&2; exit 1; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "Execute este script dentro do repositório Git."

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

BRANCH="$(git branch --show-current)"
[[ "$BRANCH" == "$BRANCH_EXPECTED" ]] \
  || die "Branch atual: $BRANCH. Esperado: $BRANCH_EXPECTED."

# Se houver mudanças, salva antes
if [[ -n "$(git status --porcelain)" ]]; then
  info "Alterações locais detectadas. Criando commit de segurança..."
  git add -A
  git commit -m "Backup antes do ajuste de readiness do Keycloak" || true
fi

info "Atualizando repositório..."
git pull --ff-only origin "$BRANCH"

mkdir -p .devcontainer scripts

# ------------------------------------------------------------
# devcontainer.json
# ------------------------------------------------------------

info "Atualizando .devcontainer/devcontainer.json..."

cat > .devcontainer/devcontainer.json <<'EOF'
{
  "name": "Keycloak Training Codespace",
  "image": "mcr.microsoft.com/devcontainers/base:noble",
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

# ------------------------------------------------------------
# iniciar-keycloak.sh
# ------------------------------------------------------------

info "Atualizando scripts/iniciar-keycloak.sh..."

cat > scripts/iniciar-keycloak.sh <<'EOF'
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
EOF

chmod +x scripts/iniciar-keycloak.sh

# ------------------------------------------------------------
# Validação
# ------------------------------------------------------------

info "Validando devcontainer.json..."

python3 - <<'PY'
import json
from pathlib import Path

p = Path(".devcontainer/devcontainer.json")
obj = json.loads(p.read_text(encoding="utf-8"))

assert obj["image"] == "mcr.microsoft.com/devcontainers/base:noble"
assert obj["features"]["ghcr.io/devcontainers/features/docker-in-docker:4"]["moby"] is False
assert obj["portsAttributes"]["8080"]["onAutoForward"] == "notify"

print("[OK] devcontainer.json válido.")
PY

info "Validando script Bash..."
bash -n scripts/iniciar-keycloak.sh
ok "Sintaxe Bash válida."

# ------------------------------------------------------------
# Git
# ------------------------------------------------------------

git add .devcontainer/devcontainer.json scripts/iniciar-keycloak.sh

if [[ -n "$(git status --porcelain)" ]]; then
  info "Criando commit..."
  git commit -m "Adiciona readiness checks para Docker e Keycloak"
fi

info "Enviando para o GitHub..."
git push origin "$BRANCH"

echo
echo "============================================================"
echo " AJUSTE CONCLUÍDO"
echo "============================================================"
echo
echo "Agora:"
echo "1. Exclua Codespaces antigos."
echo "2. Crie um Codespace NOVO na branch main."
echo "3. No novo Codespace execute:"
echo
echo "   ./scripts/iniciar-keycloak.sh"
echo
echo "O navegador só deve ser aberto depois de o Keycloak estar pronto."
echo "============================================================"
