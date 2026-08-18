#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# KEYCLOAK CODESPACES - ABERTURA ROBUSTA PARA ALUNOS
# ============================================================
#
# Execute NA SUA MÁQUINA LOCAL, dentro do repositório:
#
#   cd ~/Projetos/Keycloak-Codespaces
#   chmod +x corrigir_abertura_keycloak_alunos.sh
#   ./corrigir_abertura_keycloak_alunos.sh
#
# O script:
# 1. fixa Ubuntu 24.04 (noble);
# 2. instala Docker-in-Docker e GitHub CLI no Codespace;
# 3. encaminha a porta 8080 sem abrir cedo demais;
# 4. tenta tornar a porta 8080 PUBLIC automaticamente;
# 5. configura KC_HOSTNAME para a URL real do Codespace;
# 6. espera Docker + Keycloak ficarem realmente prontos;
# 7. valida a URL pública antes de apresentá-la;
# 8. tenta abrir o Admin Console só depois de tudo pronto;
# 9. cria diagnóstico;
# 10. faz commit e push.
#
# IMPORTANTE:
# Porta PUBLIC elimina a camada de autenticação do proxy do GitHub.
# O Keycloak continua exigindo login próprio.
# ============================================================

BRANCH_EXPECTED="main"

info(){ printf '\n[INFO] %s\n' "$*"; }
ok(){ printf '\n[OK] %s\n' "$*"; }
warn(){ printf '\n[AVISO] %s\n' "$*"; }
die(){ printf '\n[ERRO] %s\n' "$*" >&2; exit 1; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "Execute este script dentro do repositório Git."

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

BRANCH="$(git branch --show-current)"
[[ "$BRANCH" == "$BRANCH_EXPECTED" ]] \
  || die "Branch atual: $BRANCH. Esperado: $BRANCH_EXPECTED."

if [[ -n "$(git status --porcelain)" ]]; then
  warn "Há alterações locais. Criando commit de segurança."
  git add -A
  git commit -m "Backup antes da correção de abertura do Keycloak" || true
fi

info "Atualizando repositório..."
git pull --ff-only origin "$BRANCH"

mkdir -p .devcontainer scripts

# ------------------------------------------------------------
# Dev Container
# ------------------------------------------------------------

cat > .devcontainer/devcontainer.json <<'EOF'
{
  "name": "Keycloak Training Codespace",
  "image": "mcr.microsoft.com/devcontainers/base:noble",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:4": {
      "moby": false
    },
    "ghcr.io/devcontainers/features/github-cli:1": {}
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
  "postCreateCommand": "bash .devcontainer/post-create.sh",
  "postStartCommand": "bash .devcontainer/post-start.sh"
}
EOF

cat > .devcontainer/post-create.sh <<'EOF'
#!/usr/bin/env bash
set -u

echo
echo "============================================================"
echo " KEYCLOAK TRAINING ACADEMY - PREPARAÇÃO"
echo "============================================================"

if command -v docker >/dev/null 2>&1; then
  echo "[OK] Docker CLI encontrado."
  docker --version || true
else
  echo "[ERRO] Docker não foi instalado."
fi

if command -v gh >/dev/null 2>&1; then
  echo "[OK] GitHub CLI encontrado."
  gh --version | head -n1 || true
else
  echo "[ERRO] GitHub CLI não foi instalado."
fi

echo
echo "Próximo comando:"
echo "  ./scripts/iniciar-keycloak.sh"
echo "============================================================"
EOF

cat > .devcontainer/post-start.sh <<'EOF'
#!/usr/bin/env bash
set +e

# O GitHub reverte portas públicas para privadas quando o Codespace reinicia.
# Por isso tentamos restaurar a visibilidade pública em cada start.

if [[ -z "${CODESPACE_NAME:-}" ]]; then
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  exit 0
fi

# GITHUB_TOKEN é reconhecido pelo gh dentro do Codespace.
export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

for i in $(seq 1 20); do
  gh codespace ports visibility 8080:public \
    -c "${CODESPACE_NAME}" >/dev/null 2>&1 && exit 0
  sleep 2
done

exit 0
EOF

chmod +x .devcontainer/post-create.sh .devcontainer/post-start.sh

# ------------------------------------------------------------
# Script de abertura / startup
# ------------------------------------------------------------

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
  echo "[ERRO] Docker não está disponível."
  echo "[AÇÃO] Este Codespace provavelmente foi criado antes da configuração atual."
  echo "[AÇÃO] Exclua-o e crie um NOVO Codespace a partir da branch main."
  exit 1
fi

echo "[INFO] Aguardando Docker Engine..."

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

# ------------------------------------------------------------
# URL do Codespaces
# ------------------------------------------------------------

if [[ -n "${CODESPACE_NAME:-}" ]]; then
  FORWARD_DOMAIN="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
  KEYCLOAK_URL="https://${CODESPACE_NAME}-8080.${FORWARD_DOMAIN}"
  MODO="codespaces"
else
  KEYCLOAK_URL="http://localhost:8080"
  MODO="local"
fi

echo "[INFO] Modo: ${MODO}"
echo "[INFO] URL: ${KEYCLOAK_URL}"
echo

# ------------------------------------------------------------
# Porta pública no Codespaces
# ------------------------------------------------------------

if [[ "$MODO" == "codespaces" ]]; then
  echo "[INFO] Preparando porta 8080 para acesso do aluno..."

  if command -v gh >/dev/null 2>&1; then
    export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

    PORT_PUBLIC=false

    for tentativa in $(seq 1 30); do
      if gh codespace ports visibility 8080:public \
           -c "${CODESPACE_NAME}" >/dev/null 2>&1; then
        PORT_PUBLIC=true
        break
      fi
      printf "."
      sleep 2
    done
    echo

    if [[ "$PORT_PUBLIC" == "true" ]]; then
      echo "[OK] Porta 8080 configurada como PUBLIC."
    else
      echo "[AVISO] O GitHub não permitiu tornar a porta pública automaticamente."
      echo "[AVISO] Pode existir uma política da organização bloqueando portas públicas."
      echo "[AÇÃO] Na aba PORTS, altere Port Visibility para Public."
    fi
  else
    echo "[AVISO] GitHub CLI não disponível."
  fi
fi

# ------------------------------------------------------------
# Sobe Keycloak
# ------------------------------------------------------------

echo
echo "[INFO] Removendo container anterior..."
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

echo "[INFO] Iniciando Keycloak..."

DOCKER_ARGS=(
  run -d
  --name "${CONTAINER_NAME}"
  --restart unless-stopped
  -p 8080:8080
  -e KC_BOOTSTRAP_ADMIN_USERNAME="${ADMIN}"
  -e KC_BOOTSTRAP_ADMIN_PASSWORD="${PASSWORD}"
)

if [[ "$MODO" == "codespaces" ]]; then
  DOCKER_ARGS+=(
    -e KC_HOSTNAME="${KEYCLOAK_URL}"
    -e KC_HOSTNAME_STRICT="true"
    -e KC_PROXY_HEADERS="xforwarded"
  )
fi

DOCKER_ARGS+=(
  "${IMAGE}"
  start-dev
)

docker "${DOCKER_ARGS[@]}" >/dev/null

echo "[INFO] Container criado."
echo "[INFO] Aguardando Keycloak ficar pronto..."

KEYCLOAK_READY=false

for tentativa in $(seq 1 120); do
  if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
    KEYCLOAK_READY=true
    break
  fi

  if ! docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
    echo
    echo "[ERRO] Container Keycloak encerrou."
    docker logs "${CONTAINER_NAME}" --tail 120 || true
    exit 1
  fi

  printf "."
  sleep 2
done
echo

if [[ "$KEYCLOAK_READY" != "true" ]]; then
  echo "[ERRO] Keycloak não ficou pronto após 240 segundos."
  docker logs "${CONTAINER_NAME}" --tail 120 || true
  exit 1
fi

echo "[OK] Keycloak respondeu localmente."

# ------------------------------------------------------------
# Valida issuer
# ------------------------------------------------------------

ISSUER="$(
  curl -fsS \
    http://localhost:8080/realms/master/.well-known/openid-configuration \
  | sed -n 's/.*"issuer":"\([^"]*\)".*/\1/p' \
  | head -n1
)"

EXPECTED_ISSUER="${KEYCLOAK_URL}/realms/master"

if [[ "$ISSUER" == "$EXPECTED_ISSUER" ]]; then
  echo "[OK] Issuer correto."
else
  echo "[ERRO] Issuer incorreto."
  echo "Esperado: ${EXPECTED_ISSUER}"
  echo "Recebido: ${ISSUER}"
  exit 1
fi

# ------------------------------------------------------------
# Valida URL remota PUBLIC
# ------------------------------------------------------------

if [[ "$MODO" == "codespaces" ]]; then
  echo "[INFO] Validando acesso externo..."

  REMOTE_READY=false

  for tentativa in $(seq 1 60); do
    HTTP_CODE="$(
      curl -L -sS -o /dev/null -w '%{http_code}' \
        "${KEYCLOAK_URL}/realms/master" 2>/dev/null || true
    )"

    if [[ "$HTTP_CODE" == "200" ]]; then
      REMOTE_READY=true
      break
    fi

    printf "."
    sleep 2
  done
  echo

  if [[ "$REMOTE_READY" == "true" ]]; then
    echo "[OK] URL pública respondendo HTTP 200."
  else
    echo "[AVISO] A URL externa não respondeu HTTP 200 sem autenticação do GitHub."
    echo "[AVISO] Verifique se a porta 8080 está realmente PUBLIC na aba PORTS."
  fi
fi

# ------------------------------------------------------------
# Entrega ao aluno
# ------------------------------------------------------------

echo
echo "============================================================"
echo " LABORATÓRIO PRONTO"
echo "============================================================"
echo
echo "Usuário: ${ADMIN}"
echo "Senha:   ${PASSWORD}"
echo
echo "Keycloak:"
echo "${KEYCLOAK_URL}"
echo
echo "Console administrativo:"
echo "${KEYCLOAK_URL}/admin/"
echo
echo "IMPORTANTE:"
echo "Use a URL app.github.dev exibida acima."
echo "Não use localhost no navegador."
echo "Não acrescente :8080 ao final da URL do Codespaces."
echo "============================================================"
echo

# Tenta abrir somente depois de todos os checks.
if [[ "$MODO" == "codespaces" ]] && command -v code >/dev/null 2>&1; then
  echo "[INFO] Tentando abrir o Admin Console no navegador..."
  code --open-url "${KEYCLOAK_URL}/admin/" >/dev/null 2>&1 || true
fi
EOF

chmod +x scripts/iniciar-keycloak.sh

# ------------------------------------------------------------
# Diagnóstico para professor/aluno
# ------------------------------------------------------------

cat > scripts/diagnosticar-abertura.sh <<'EOF'
#!/usr/bin/env bash
set +e

echo "============================================================"
echo " DIAGNÓSTICO DE ABERTURA DO KEYCLOAK"
echo "============================================================"

echo
echo "Codespace:"
echo "${CODESPACE_NAME:-não detectado}"

echo
echo "Docker:"
docker --version 2>&1
docker ps 2>&1

echo
echo "Variáveis Keycloak:"
docker inspect keycloak \
  --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null \
  | grep '^KC_' | sort

echo
echo "Teste local:"
curl -sS -o /dev/null -w 'HTTP %{http_code}\n' \
  http://localhost:8080/realms/master

if [[ -n "${CODESPACE_NAME:-}" ]]; then
  DOMAIN="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
  URL="https://${CODESPACE_NAME}-8080.${DOMAIN}"

  echo
  echo "URL pública:"
  echo "$URL"

  echo
  echo "Teste remoto sem token:"
  curl -L -sS -o /dev/null -w 'HTTP %{http_code}\n' \
    "${URL}/realms/master"

  echo
  echo "Issuer:"
  curl -sS \
    http://localhost:8080/realms/master/.well-known/openid-configuration \
    | grep -o '"issuer":"[^"]*"' || true

  if command -v gh >/dev/null 2>&1; then
    echo
    echo "Portas Codespaces:"
    export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
    gh codespace ports \
      -c "${CODESPACE_NAME}" \
      --json sourcePort,visibility,browseUrl 2>&1
  fi
fi

echo
echo "============================================================"
EOF

chmod +x scripts/diagnosticar-abertura.sh

# ------------------------------------------------------------
# README operacional curto
# ------------------------------------------------------------

cat > ABRIR-KEYCLOAK.md <<'EOF'
# Como abrir o Keycloak no laboratório

1. Crie um Codespace novo a partir da branch `main`.
2. Aguarde o Codespace terminar a preparação.
3. No terminal execute:

```bash
./scripts/iniciar-keycloak.sh
```

O script:

- aguarda o Docker ficar pronto;
- configura a porta 8080;
- inicia o Keycloak;
- aguarda o serviço responder;
- valida o hostname e o issuer;
- valida a URL externa;
- somente então tenta abrir o navegador.

## Regra importante

No Codespaces, use sempre a URL:

```text
https://NOME-DO-CODESPACE-8080.app.github.dev
```

Não utilize `http://localhost:8080` como URL do aluno.

## Se houver problema

Execute:

```bash
./scripts/diagnosticar-abertura.sh
```

A porta 8080 é configurada como pública para evitar que a camada de autenticação
de portas privadas do Codespaces interfira no Admin Console do Keycloak.

O Keycloak continua protegido pela autenticação própria do laboratório.
EOF

# ------------------------------------------------------------
# Validação e Git
# ------------------------------------------------------------

info "Validando arquivos..."

python3 - <<'PY'
import json
json.load(open(".devcontainer/devcontainer.json"))
print("[OK] devcontainer.json válido")
PY

for f in \
  .devcontainer/post-create.sh \
  .devcontainer/post-start.sh \
  scripts/iniciar-keycloak.sh \
  scripts/diagnosticar-abertura.sh
do
  bash -n "$f"
done

ok "Scripts validados."

git add -A

if [[ -n "$(git status --porcelain)" ]]; then
  git commit -m "Estabiliza abertura do Keycloak para alunos no Codespaces"
fi

info "Enviando para o GitHub..."
git push origin "$BRANCH"

echo
echo "============================================================"
echo " CONFIGURAÇÃO CONCLUÍDA"
echo "============================================================"
echo
echo "Agora faça o teste correto:"
echo
echo "1. Exclua Codespaces antigos."
echo "2. Crie um Codespace NOVO na branch main."
echo "3. Execute:"
echo
echo "   ./scripts/iniciar-keycloak.sh"
echo
echo "4. Se houver problema:"
echo
echo "   ./scripts/diagnosticar-abertura.sh"
echo
echo "============================================================"
