#!/usr/bin/env bash
set -Eeuo pipefail

REPO_EXPECTED="segurancadevops-sudo/Keycloak-Codespaces"
BRANCH_EXPECTED="main"
ADMIN_DEFAULT="admin"
PASSWORD_DEFAULT="Treinamento@2026"
KEYCLOAK_IMAGE_DEFAULT="quay.io/keycloak/keycloak:latest"

info(){ printf '\n[INFO] %s\n' "$*"; }
ok(){ printf '[OK] %s\n' "$*"; }
warn(){ printf '[AVISO] %s\n' "$*"; }
fail(){ printf '[ERRO] %s\n' "$*" >&2; exit 1; }

trap 'printf "\n"; fail "Falha na linha $LINENO. Nada será apagado automaticamente."' ERR

command -v git >/dev/null 2>&1 || fail "git não encontrado."
command -v python3 >/dev/null 2>&1 || fail "python3 não encontrado."

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "Execute dentro do repositório Keycloak-Codespaces."
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

BRANCH="$(git branch --show-current)"
[[ "$BRANCH" == "$BRANCH_EXPECTED" ]] || fail "Branch atual: $BRANCH. Esperado: main."
ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
[[ -n "$ORIGIN" ]] || fail "Remote origin não encontrado."

info "Repositório: $ROOT"
info "Branch: $BRANCH"
info "Origin: $ORIGIN"

if [[ -n "$(git status --porcelain)" ]]; then
  warn "Há mudanças locais. Criando commit de segurança antes da correção."
  git add -A
  git commit -m "Backup automatico antes da correcao do Codespaces $(date '+%Y-%m-%d %H:%M:%S')" || true
fi

info "Atualizando branch..."
git pull --ff-only origin "$BRANCH"

mkdir -p .devcontainer scripts labs

cat > .devcontainer/devcontainer.json <<'JSON'
{
  "name": "Keycloak Training Codespace",
  "image": "mcr.microsoft.com/devcontainers/base:noble",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:4": {
      "moby": false,
      "version": "latest",
      "installDockerBuildx": true,
      "dockerDashComposeVersion": "latest"
    }
  },
  "forwardPorts": [8080],
  "portsAttributes": {
    "8080": {
      "label": "Keycloak",
      "onAutoForward": "notify"
    }
  },
  "hostRequirements": {
    "cpus": 2
  },
  "postCreateCommand": "bash .devcontainer/post-create.sh"
}
JSON

cat > .devcontainer/post-create.sh <<'EOF2'
#!/usr/bin/env bash
set -u

echo "============================================================"
echo " KEYCLOAK TRAINING ACADEMY - PREPARAÇÃO DO AMBIENTE"
echo "============================================================"
. /etc/os-release
echo "Sistema: ${PRETTY_NAME:-Linux}"

if command -v docker >/dev/null 2>&1; then
  echo "[OK] Docker CLI encontrado:"
  docker --version || true
  echo "[INFO] Aguardando Docker Engine..."
  for i in $(seq 1 30); do
    if docker info >/dev/null 2>&1; then
      echo "[OK] Docker Engine disponível."
      break
    fi
    sleep 2
  done
else
  echo "[ERRO] Docker não foi instalado no Dev Container."
fi

echo "Próximo comando: ./scripts/iniciar-keycloak.sh"
EOF2
chmod +x .devcontainer/post-create.sh

cat > scripts/diagnosticar-lab.sh <<'EOF2'
#!/usr/bin/env bash
set +e
PASS=0; FAIL=0; WARN=0
pass(){ echo "[OK] $*"; PASS=$((PASS+1)); }
fail(){ echo "[ERRO] $*"; FAIL=$((FAIL+1)); }
warn(){ echo "[AVISO] $*"; WARN=$((WARN+1)); }

echo "============================================================"
echo " DIAGNÓSTICO - KEYCLOAK TRAINING ACADEMY"
echo "============================================================"

if [[ -n "${CODESPACE_NAME:-}" ]]; then pass "Codespace: ${CODESPACE_NAME}"; else warn "CODESPACE_NAME ausente."; fi

if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  echo "Sistema: ${PRETTY_NAME:-desconhecido}"
  [[ "${VERSION_CODENAME:-}" == "noble" ]] && pass "Ubuntu 24.04 noble." || warn "Codename atual: ${VERSION_CODENAME:-desconhecido}."
fi

if [[ -f .devcontainer/devcontainer.json ]]; then
  pass "devcontainer.json encontrado."
  python3 - <<'PY' >/dev/null 2>&1
import json
json.load(open('.devcontainer/devcontainer.json'))
PY
  [[ $? -eq 0 ]] && pass "devcontainer.json válido." || fail "devcontainer.json inválido."
  grep -q 'base:noble' .devcontainer/devcontainer.json && pass "Base fixada em noble." || fail "Base não está fixada em noble."
  grep -q '"moby": false' .devcontainer/devcontainer.json && pass "moby=false configurado." || fail "moby=false ausente."
else
  fail "devcontainer.json não encontrado."
fi

if command -v docker >/dev/null 2>&1; then
  pass "Docker CLI: $(docker --version 2>/dev/null)"
  docker info >/dev/null 2>&1 && pass "Docker Engine respondendo." || fail "Docker Engine não responde."
else
  fail "docker: command not found"
fi

command -v curl >/dev/null 2>&1 && pass "curl disponível." || fail "curl não encontrado."

if command -v docker >/dev/null 2>&1 && docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx keycloak; then
  pass "Container keycloak existe."
else
  warn "Container keycloak ainda não existe."
fi

curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1 && pass "Keycloak responde em localhost:8080." || warn "Keycloak ainda não responde em localhost:8080."

if [[ -n "${CODESPACE_NAME:-}" ]]; then
  echo "URL esperada: https://${CODESPACE_NAME}-8080.app.github.dev"
fi

echo "============================================================"
echo "RESULTADO: $PASS OK | $WARN AVISOS | $FAIL ERROS"
echo "============================================================"

[[ "$FAIL" -gt 0 ]] && exit 1 || exit 0
EOF2
chmod +x scripts/diagnosticar-lab.sh

cat > scripts/iniciar-keycloak.sh <<EOF2
#!/usr/bin/env bash
set -Eeuo pipefail
IMAGE="\${KEYCLOAK_IMAGE:-$KEYCLOAK_IMAGE_DEFAULT}"
ADMIN="\${KEYCLOAK_ADMIN:-$ADMIN_DEFAULT}"
PASSWORD="\${KEYCLOAK_PASSWORD:-$PASSWORD_DEFAULT}"
CONTAINER_NAME="keycloak"

command -v docker >/dev/null 2>&1 || { echo "[ERRO] Docker não disponível. Rode ./scripts/diagnosticar-lab.sh"; exit 1; }
docker info >/dev/null 2>&1 || { echo "[ERRO] Docker Engine não responde."; exit 1; }

echo "[INFO] Docker:"
docker --version

docker rm -f "\${CONTAINER_NAME}" >/dev/null 2>&1 || true

echo "[INFO] Iniciando Keycloak..."
docker run -d \
  --name "\${CONTAINER_NAME}" \
  --restart unless-stopped \
  -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME="\${ADMIN}" \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD="\${PASSWORD}" \
  "\${IMAGE}" \
  start-dev >/dev/null

echo "[INFO] Aguardando o Keycloak responder..."
for tentativa in \$(seq 1 120); do
  if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
    if [[ -n "\${CODESPACE_NAME:-}" ]]; then
      KEYCLOAK_URL="https://\${CODESPACE_NAME}-8080.app.github.dev"
    else
      KEYCLOAK_URL="http://localhost:8080"
    fi
    echo
    echo "============================================================"
    echo " KEYCLOAK TRAINING ACADEMY"
    echo "============================================================"
    echo "[OK] Keycloak disponível."
    echo "Usuário: \${ADMIN}"
    echo "Senha:   \${PASSWORD}"
    echo "Acesso:  \${KEYCLOAK_URL}"
    echo "Admin:   \${KEYCLOAK_URL}/admin/"
    [[ -n "\${CODESPACE_NAME:-}" ]] && echo "IMPORTANTE: não acrescente :8080 ao final da URL do Codespaces."
    echo "============================================================"
    exit 0
  fi
  if ! docker ps --format '{{.Names}}' | grep -qx "\${CONTAINER_NAME}"; then
    echo "[ERRO] Container Keycloak encerrou durante a inicialização."
    docker logs "\${CONTAINER_NAME}" --tail 120 || true
    exit 1
  fi
  printf '.'
  sleep 2
done

echo "[ERRO] Timeout aguardando Keycloak."
docker logs "\${CONTAINER_NAME}" --tail 120 || true
exit 1
EOF2
chmod +x scripts/iniciar-keycloak.sh

cat > scripts/status-keycloak.sh <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
command -v docker >/dev/null 2>&1 || { echo "[ERRO] Docker não encontrado."; exit 1; }
docker --version
docker ps -a --filter name='^keycloak$'
if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
  echo "[OK] Keycloak respondendo em localhost:8080"
  [[ -n "${CODESPACE_NAME:-}" ]] && echo "URL: https://${CODESPACE_NAME}-8080.app.github.dev"
else
  echo "[AVISO] Keycloak não está respondendo."
fi
EOF2

cat > scripts/parar-keycloak.sh <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
docker stop keycloak >/dev/null 2>&1 || true
echo "[OK] Keycloak parado."
EOF2

cat > scripts/logs-keycloak.sh <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
docker logs -f --tail 150 keycloak
EOF2

cat > scripts/resetar-laboratorio.sh <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker rm -f keycloak >/dev/null 2>&1 || true
"${DIR}/iniciar-keycloak.sh"
EOF2
chmod +x scripts/*.sh

find scripts .devcontainer -maxdepth 1 -type f -name '*~' -delete || true
touch .gitignore
grep -qxF '*~' .gitignore || echo '*~' >> .gitignore
grep -qxF '*.swp' .gitignore || echo '*.swp' >> .gitignore

info "Validando configuração..."
python3 - <<'PY'
import json
obj=json.load(open('.devcontainer/devcontainer.json'))
assert obj['image']=='mcr.microsoft.com/devcontainers/base:noble'
assert obj['features']['ghcr.io/devcontainers/features/docker-in-docker:4']['moby'] is False
assert obj['portsAttributes']['8080']['onAutoForward']=='notify'
print('[OK] devcontainer.json validado.')
PY

for f in .devcontainer/post-create.sh scripts/diagnosticar-lab.sh scripts/iniciar-keycloak.sh scripts/status-keycloak.sh scripts/parar-keycloak.sh scripts/logs-keycloak.sh scripts/resetar-laboratorio.sh; do
  bash -n "$f"
done
ok "Sintaxe Bash validada."

git add -A
if [[ -n "$(git status --porcelain)" ]]; then
  git commit -m "Estabiliza Codespaces com Ubuntu Noble e Docker CE"
fi

git push origin "$BRANCH"
ok "GitHub sincronizado."

echo
echo "============================================================"
echo " MATADOR DE BUGS CONCLUÍDO"
echo "============================================================"
echo "✓ Ubuntu 24.04 / noble"
echo "✓ docker-in-docker com moby=false"
echo "✓ porta 8080 com notify"
echo "✓ diagnóstico automático"
echo "✓ inicialização robusta do Keycloak"
echo "✓ commit e push"
echo
echo "IMPORTANTE: crie um CODESPACE NOVO. Não reutilize os antigos."
echo "Depois rode:"
echo "  ./scripts/diagnosticar-lab.sh"
echo "  ./scripts/iniciar-keycloak.sh"
echo "============================================================"

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  read -r -p "Deseja abrir o repositório no navegador agora? [S/n] " RESP
  RESP="${RESP:-S}"
  if [[ "${RESP,,}" =~ ^(s|sim|y|yes)$ ]]; then
    gh repo view "$REPO_EXPECTED" --web
  fi
fi
