#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Ajuste recomendado para Keycloak no GitHub Codespaces
#
# O que este script faz:
# 1. Valida que esta sendo executado dentro de um repositorio Git.
# 2. Exige working tree limpo para evitar sobrescrever alteracoes.
# 3. Atualiza .devcontainer/devcontainer.json.
# 4. Atualiza scripts/iniciar-keycloak.sh.
# 5. Atualiza README.md com a orientacao correta de URL.
# 6. Faz git add, commit e push automaticamente.
#
# Uso:
#   chmod +x aplicar_ajuste_codespaces_keycloak.sh
#   ./aplicar_ajuste_codespaces_keycloak.sh
#
# Opcional:
#   AUTO_PUSH=false ./aplicar_ajuste_codespaces_keycloak.sh
# ============================================================

AUTO_PUSH="${AUTO_PUSH:-true}"

log() {
  printf '\n[%s] %s\n' "$1" "$2"
}

die() {
  printf '\n[ERRO] %s\n' "$1" >&2
  exit 1
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "Execute este script dentro do repositorio Git."

ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"

log INFO "Repositorio detectado: $ROOT_DIR"

CURRENT_BRANCH="$(git branch --show-current)"
[[ -n "$CURRENT_BRANCH" ]] || die "Nao foi possivel identificar a branch atual."

if [[ -n "$(git status --porcelain)" ]]; then
  echo
  git status --short
  die "Existem alteracoes locais nao commitadas. Commit ou stash antes de executar."
fi

log INFO "Atualizando repositorio..."
git pull --ff-only

mkdir -p .devcontainer scripts

log INFO "Atualizando .devcontainer/devcontainer.json..."

cat > .devcontainer/devcontainer.json <<'EOF'
{
  "name": "Keycloak Training Codespace",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:4": {}
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

log INFO "Atualizando scripts/iniciar-keycloak.sh..."

cat > scripts/iniciar-keycloak.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

IMAGE="${KEYCLOAK_IMAGE:-quay.io/keycloak/keycloak:latest}"
ADMIN="${KEYCLOAK_ADMIN:-admin}"
PASSWORD="${KEYCLOAK_PASSWORD:-Treinamento@2026}"
CONTAINER_NAME="keycloak"

echo "[INFO] Removendo container anterior, se existir..."
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

echo "[INFO] Iniciando Keycloak..."

docker run -d \
  --name "${CONTAINER_NAME}" \
  -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME="${ADMIN}" \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD="${PASSWORD}" \
  "${IMAGE}" \
  start-dev

echo "[INFO] Aguardando o Keycloak responder..."

for tentativa in $(seq 1 90); do
  if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
    echo
    echo "[OK] Keycloak disponivel."
    echo

    if [[ -n "${CODESPACE_NAME:-}" ]]; then
      KEYCLOAK_URL="https://${CODESPACE_NAME}-8080.app.github.dev"
    else
      KEYCLOAK_URL="http://localhost:8080"
    fi

    echo "============================================================"
    echo " KEYCLOAK TRAINING ACADEMY"
    echo "============================================================"
    echo
    echo "Acesse:"
    echo "${KEYCLOAK_URL}"
    echo
    echo "Console administrativo:"
    echo "${KEYCLOAK_URL}/admin/"
    echo
    echo "Usuario:"
    echo "${ADMIN}"
    echo
    echo "Senha:"
    echo "${PASSWORD}"
    echo
    echo "============================================================"
    echo
    echo "[DICA] No GitHub Codespaces, nao adicione :8080 ao final da URL."
    echo

    exit 0
  fi

  printf '.'
  sleep 2
done

echo
echo "[ERRO] O Keycloak nao respondeu no tempo esperado."
echo
echo "[INFO] Ultimos logs do container:"
docker logs "${CONTAINER_NAME}" --tail 100 || true

exit 1
EOF

chmod +x scripts/iniciar-keycloak.sh

log INFO "Atualizando README.md..."

cat > README.md <<'EOF'
# Keycloak Training Academy - GitHub Codespaces

Laboratorios praticos de Keycloak executados no navegador utilizando GitHub Codespaces.

## Como iniciar

1. Entre no GitHub com sua conta.
2. Abra este repositorio.
3. Clique em **Code**.
4. Abra a aba **Codespaces**.
5. Clique em **Create codespace on main**.
6. Aguarde o ambiente abrir no navegador.

Nenhuma instalacao local de Docker, Java ou Keycloak e necessaria.

## Iniciar o Keycloak

No terminal do Codespaces:

```bash
./scripts/iniciar-keycloak.sh
```

O script exibira automaticamente a URL correta do Keycloak para o Codespace atual.

Exemplo:

```text
https://NOME-DO-CODESPACE-8080.app.github.dev
```

Importante:

```text
NAO use :8080 ao final da URL externa do Codespaces.
```

O console administrativo sera:

```text
https://NOME-DO-CODESPACE-8080.app.github.dev/admin/
```

Credenciais padrao:

```text
Usuario: admin
Senha: Treinamento@2026
```

## Laboratorios

1. [Primeiros Passos](labs/01-primeiros-passos.md)
2. [Keycloak com Docker](labs/02-keycloak-docker.md)
3. [Realm, Usuario, Grupo e Role](labs/03-realm-user-group-role.md)
4. [Client e OpenID Connect](labs/04-client-openid-connect.md)
5. [Tokens e JWT](labs/05-tokens-jwt.md)

## Comandos uteis

### Status

```bash
./scripts/status-keycloak.sh
```

### Logs

```bash
./scripts/logs-keycloak.sh
```

### Parar

```bash
./scripts/parar-keycloak.sh
```

### Resetar

```bash
./scripts/resetar-laboratorio.sh
```

## Estrutura

```text
.devcontainer/   Configuracao do GitHub Codespaces
labs/            Roteiros dos laboratorios
scripts/         Automacao do ambiente
scenarios/       Conteudo original preservado do Killercoda
```
EOF

log INFO "Alteracoes detectadas:"
git status --short

if [[ -z "$(git status --porcelain)" ]]; then
  log INFO "Nenhuma alteracao nova encontrada."
  exit 0
fi

log INFO "Criando commit..."
git add .devcontainer/devcontainer.json scripts/iniciar-keycloak.sh README.md
git commit -m "Corrige acesso ao Keycloak no GitHub Codespaces"

if [[ "$AUTO_PUSH" == "true" ]]; then
  log INFO "Enviando para o GitHub..."
  git push origin "$CURRENT_BRANCH"
else
  log INFO "AUTO_PUSH=false: push nao executado."
fi

echo
echo "============================================================"
echo " AJUSTE CONCLUIDO"
echo "============================================================"
echo
echo "Depois, dentro do Codespace:"
echo
echo "  git pull"
echo "  ./scripts/iniciar-keycloak.sh"
echo
echo "O script mostrara a URL correta do Keycloak."
echo "============================================================"
