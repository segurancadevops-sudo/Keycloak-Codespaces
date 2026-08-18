#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="Keycloak-Codespaces"
KEYCLOAK_IMAGE="${KEYCLOAK_IMAGE:-quay.io/keycloak/keycloak:latest}"
KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN:-admin}"
KEYCLOAK_PASSWORD="${KEYCLOAK_PASSWORD:-Treinamento@2026}"
AUTO_PUSH="${AUTO_PUSH:-true}"

log() {
  printf '\n[%s] %s\n' "$1" "$2"
}

die() {
  printf '\n[ERRO] %s\n' "$1" >&2
  exit 1
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Execute este script dentro do repositorio Git."

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

log INFO "Atualizando o repositorio..."
git pull --ff-only

[[ -d "scenarios" ]] || die "A pasta scenarios/ nao foi encontrada."

log INFO "Criando estrutura Codespaces..."
mkdir -p .devcontainer labs scripts

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

if [[ -f devcontainer.json ]]; then
  rm -f devcontainer.json
fi

cat > scripts/iniciar-keycloak.sh <<EOF
#!/usr/bin/env bash
set -euo pipefail

IMAGE="\${KEYCLOAK_IMAGE:-${KEYCLOAK_IMAGE}}"
ADMIN="\${KEYCLOAK_ADMIN:-${KEYCLOAK_ADMIN}}"
PASSWORD="\${KEYCLOAK_PASSWORD:-${KEYCLOAK_PASSWORD}}"

docker rm -f keycloak >/dev/null 2>&1 || true

echo "[INFO] Iniciando Keycloak..."
docker run -d \
  --name keycloak \
  -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME="\${ADMIN}" \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD="\${PASSWORD}" \
  "\${IMAGE}" \
  start-dev

echo "[INFO] Aguardando o Keycloak responder..."

for tentativa in \$(seq 1 90); do
  if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
    echo
    echo "[OK] Keycloak disponivel."
    echo "Usuario: \${ADMIN}"
    echo "Senha: \${PASSWORD}"
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
EOF

cat > scripts/parar-keycloak.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if docker ps -a --format '{{.Names}}' | grep -qx keycloak; then
  docker stop keycloak >/dev/null
  echo "[OK] Keycloak parado."
else
  echo "[INFO] Container keycloak nao encontrado."
fi
EOF

cat > scripts/status-keycloak.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "=== CONTAINER ==="
docker ps -a --filter name='^keycloak$'

echo
echo "=== HTTP ==="
if curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1; then
  echo "[OK] Keycloak respondendo em http://localhost:8080"
else
  echo "[AVISO] Keycloak ainda nao esta respondendo na porta 8080."
fi
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

convert_scenario() {
  local scenario_dir="$1"
  local lab_file="$2"
  local title="$3"

  {
    echo "# ${title}"
    echo
    echo "> Laboratorio pratico da Keycloak Training Academy."
    echo

    if [[ -f "${scenario_dir}/intro.md" ]]; then
      cat "${scenario_dir}/intro.md"
      echo
      echo "---"
      echo
    fi

    while IFS= read -r step; do
      cat "$step"
      echo
      echo "---"
      echo
    done < <(find "$scenario_dir" -maxdepth 1 -type f -name 'step*.md' | sort -V)

    if [[ -f "${scenario_dir}/finish.md" ]]; then
      cat "${scenario_dir}/finish.md"
      echo
    fi
  } > "$lab_file"
}

log INFO "Convertendo cenarios em labs..."

convert_scenario "scenarios/01-introduction" "labs/01-primeiros-passos.md" "Laboratorio 01 - Primeiros Passos"
convert_scenario "scenarios/02-keycloak-docker" "labs/02-keycloak-docker.md" "Laboratorio 02 - Keycloak com Docker"
convert_scenario "scenarios/03-realm-user-group-role" "labs/03-realm-user-group-role.md" "Laboratorio 03 - Realm, Usuario, Grupo e Role"
convert_scenario "scenarios/04-client-openid-connect" "labs/04-client-openid-connect.md" "Laboratorio 04 - Client e OpenID Connect"
convert_scenario "scenarios/05-tokens-jwt" "labs/05-tokens-jwt.md" "Laboratorio 05 - Tokens e JWT"

cat > README.md <<'EOF'
# Keycloak Training Academy - GitHub Codespaces

Laboratorios praticos de Keycloak executados inteiramente no navegador utilizando GitHub Codespaces.

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

Depois abra a aba **PORTAS** e acesse a porta `8080`.

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

log INFO "Estrutura final:"
find .devcontainer labs scripts -maxdepth 2 -type f | sort

echo
echo "=== GIT STATUS ==="
git status --short

if [[ -n "$(git status --porcelain)" ]]; then
  git add .devcontainer labs scripts README.md
  git add -u

  git commit -m "Adapta treinamento Keycloak para GitHub Codespaces"

  if [[ "$AUTO_PUSH" == "true" ]]; then
    git push origin "$CURRENT_BRANCH"
  fi
else
  log INFO "Nenhuma alteracao nova encontrada."
fi

echo
echo "============================================================"
echo " CONFIGURACAO CONCLUIDA"
echo "============================================================"
echo
echo "Repositorio:"
git remote get-url origin 2>/dev/null || true
echo
echo "Branch: $CURRENT_BRANCH"
echo
echo "Para iniciar o Keycloak:"
echo "./scripts/iniciar-keycloak.sh"
echo
echo "Os cenarios originais permanecem preservados em scenarios/."
echo "============================================================"
