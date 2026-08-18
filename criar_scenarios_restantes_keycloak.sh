#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Keycloak Training Academy
# Cria os cenários restantes, versiona e envia ao GitHub.
# ============================================================

REPO_DIR="${HOME}/Projetos/keycloak-training"
KILLERCODA_URL="https://killercoda.com/keycloak-training"

log() {
  printf '\n[%s] %s\n' "$1" "$2"
}

write_file() {
  local path="$1"
  shift
  mkdir -p "$(dirname "$path")"
  cat > "$path"
}

if [[ ! -d "${REPO_DIR}/.git" ]]; then
  echo "[ERRO] Repositório não encontrado em: ${REPO_DIR}"
  echo "Ajuste a variável REPO_DIR no início do script, se necessário."
  exit 1
fi

cd "${REPO_DIR}"

log INFO "Atualizando o repositório local..."
git pull --ff-only

# ============================================================
# LAB 03 - Realm, User, Group e Role
# ============================================================

LAB03="scenarios/03-realm-user-group-role"
mkdir -p "${LAB03}"

cat > "${LAB03}/index.json" <<'EOF'
{
  "title": "Realm, Usuário, Grupo e Role",
  "description": "Aprenda os principais componentes administrativos do Keycloak.",
  "details": {
    "intro": {
      "text": "intro.md"
    },
    "steps": [
      {
        "title": "Criar o Realm",
        "text": "step1.md"
      },
      {
        "title": "Criar Grupo e Role",
        "text": "step2.md"
      },
      {
        "title": "Criar Usuário e Associar Permissões",
        "text": "step3.md"
      },
      {
        "title": "Validar a Configuração",
        "text": "step4.md"
      }
    ],
    "finish": {
      "text": "finish.md"
    }
  },
  "backend": {
    "imageid": "ubuntu"
  }
}
EOF

cat > "${LAB03}/intro.md" <<'EOF'
# Laboratório 03 - Realm, Usuário, Grupo e Role

Neste laboratório você irá administrar os principais componentes do Keycloak.

## Objetivo

Ao final você será capaz de:

- criar um Realm;
- criar um Grupo;
- criar uma Role;
- criar um Usuário;
- associar o usuário ao grupo;
- associar permissões;
- validar a configuração.

> O Keycloak deve estar em execução antes de iniciar este laboratório.
EOF

cat > "${LAB03}/step1.md" <<'EOF'
# Passo 1 - Criar o Realm

Acesse o console administrativo do Keycloak.

Crie um novo Realm com o nome:

`semfaz-lab`

Depois confirme se o Realm aparece selecionado no canto superior esquerdo.

## Conceito

Um Realm é um ambiente lógico que organiza usuários, grupos, roles, clients e configurações de autenticação.
EOF

cat > "${LAB03}/step2.md" <<'EOF'
# Passo 2 - Criar Grupo e Role

No Realm `semfaz-lab`:

## Grupo

Crie o grupo:

`Auditores`

## Role

Crie a Realm Role:

`consulta-tributaria`

Depois associe a Role `consulta-tributaria` ao grupo `Auditores`.
EOF

cat > "${LAB03}/step3.md" <<'EOF'
# Passo 3 - Criar Usuário e Associar Permissões

Crie o usuário:

`joao.silva`

Defina uma senha para o usuário.

Depois associe o usuário ao grupo:

`Auditores`

A estrutura deverá ficar assim:

`joao.silva -> Auditores -> consulta-tributaria`
EOF

cat > "${LAB03}/step4.md" <<'EOF'
# Passo 4 - Validar a Configuração

Abra o usuário `joao.silva`.

Acesse:

**Role Mapping**

Confira as roles efetivas do usuário.

A Role abaixo deverá estar disponível:

`consulta-tributaria`

Se estiver presente, a associação foi realizada corretamente.
EOF

cat > "${LAB03}/finish.md" <<'EOF'
# Laboratório concluído

Você criou e relacionou:

- Realm;
- Grupo;
- Role;
- Usuário.

Também validou a herança de permissões.

## Próximo laboratório

No próximo laboratório vamos criar um Client OpenID Connect e entender como uma aplicação se integra ao Keycloak.
EOF


# ============================================================
# LAB 04 - Client e OpenID Connect
# ============================================================

LAB04="scenarios/04-client-openid-connect"
mkdir -p "${LAB04}"

cat > "${LAB04}/index.json" <<'EOF'
{
  "title": "Client e OpenID Connect",
  "description": "Configure uma aplicação cliente no Keycloak utilizando OpenID Connect.",
  "details": {
    "intro": {
      "text": "intro.md"
    },
    "steps": [
      {
        "title": "Criar o Client",
        "text": "step1.md"
      },
      {
        "title": "Configurar o Client",
        "text": "step2.md"
      },
      {
        "title": "Validar a Configuração",
        "text": "step3.md"
      }
    ],
    "finish": {
      "text": "finish.md"
    }
  },
  "backend": {
    "imageid": "ubuntu"
  }
}
EOF

cat > "${LAB04}/intro.md" <<'EOF'
# Laboratório 04 - Client e OpenID Connect

Neste laboratório você irá criar uma aplicação integrada ao Keycloak.

## Objetivo

Ao final você será capaz de:

- compreender o que é um Client;
- criar um Client OpenID Connect;
- configurar o fluxo padrão de autenticação;
- entender a função da Redirect URI.
EOF

cat > "${LAB04}/step1.md" <<'EOF'
# Passo 1 - Criar o Client

No Realm `semfaz-lab`, acesse:

**Clients**

Crie um novo Client com:

- Client type: `OpenID Connect`
- Client ID: `portal-semfaz`
EOF

cat > "${LAB04}/step2.md" <<'EOF'
# Passo 2 - Configurar o Client

Configure:

- Standard Flow: habilitado
- Client Authentication: desabilitado

Defina uma Redirect URI de laboratório conforme o endereço utilizado no cenário.

## Conceito

A Redirect URI define para onde o Keycloak pode devolver o usuário após a autenticação.
EOF

cat > "${LAB04}/step3.md" <<'EOF'
# Passo 3 - Validar a Configuração

Confira no Client `portal-semfaz`:

- protocolo OpenID Connect;
- Standard Flow habilitado;
- Redirect URI cadastrada.

O Client agora representa uma aplicação que poderá utilizar o Keycloak para autenticação.
EOF

cat > "${LAB04}/finish.md" <<'EOF'
# Laboratório concluído

Você criou um Client OpenID Connect e conheceu os principais parâmetros utilizados na integração de aplicações.

## Próximo laboratório

Vamos conhecer os tokens gerados durante a autenticação e analisar um JWT.
EOF


# ============================================================
# LAB 05 - Tokens e JWT
# ============================================================

LAB05="scenarios/05-tokens-jwt"
mkdir -p "${LAB05}"

cat > "${LAB05}/index.json" <<'EOF'
{
  "title": "Tokens e JWT",
  "description": "Conheça Access Token, Refresh Token, ID Token e a estrutura de um JWT.",
  "details": {
    "intro": {
      "text": "intro.md"
    },
    "steps": [
      {
        "title": "Conhecer os Tokens",
        "text": "step1.md"
      },
      {
        "title": "Analisar um JWT",
        "text": "step2.md"
      },
      {
        "title": "Identificar Claims",
        "text": "step3.md"
      }
    ],
    "finish": {
      "text": "finish.md"
    }
  },
  "backend": {
    "imageid": "ubuntu"
  }
}
EOF

cat > "${LAB05}/intro.md" <<'EOF'
# Laboratório 05 - Tokens e JWT

Neste laboratório você irá compreender os principais tokens usados por OAuth2 e OpenID Connect.

## Objetivo

Ao final você será capaz de identificar:

- Access Token;
- Refresh Token;
- ID Token;
- Header;
- Payload;
- Signature;
- Claims.
EOF

cat > "${LAB05}/step1.md" <<'EOF'
# Passo 1 - Conhecer os Tokens

## Access Token

Usado para acessar recursos protegidos.

## Refresh Token

Usado para obter um novo Access Token sem exigir novo login.

## ID Token

Contém informações sobre a identidade do usuário autenticado.
EOF

cat > "${LAB05}/step2.md" <<'EOF'
# Passo 2 - Analisar um JWT

Um JWT é normalmente composto por três partes:

`Header.Payload.Signature`

## Header

Informa o tipo do token e o algoritmo de assinatura.

## Payload

Contém as informações, chamadas de claims.

## Signature

Permite verificar a integridade do token.
EOF

cat > "${LAB05}/step3.md" <<'EOF'
# Passo 3 - Identificar Claims

Em um token do Keycloak, procure claims como:

- `preferred_username`
- `email`
- `groups`
- `roles`

Essas informações podem ser utilizadas pelas aplicações para identificar o usuário e tomar decisões de autorização.
EOF

cat > "${LAB05}/finish.md" <<'EOF'
# Treinamento prático concluído

Parabéns!

Você concluiu a trilha prática introdutória de Keycloak.

## Você praticou

- ambiente de laboratório;
- Docker;
- execução do Keycloak;
- Realm;
- User;
- Group;
- Role;
- Client;
- OpenID Connect;
- Tokens;
- JWT;
- Claims.

Agora você já possui uma base prática para continuar estudando administração, integração e troubleshooting no Keycloak.
EOF


# ============================================================
# Git
# ============================================================

log INFO "Arquivos criados."
git status --short

if [[ -z "$(git status --porcelain)" ]]; then
  log INFO "Nenhuma alteração encontrada."
else
  log INFO "Adicionando arquivos ao Git..."
  git add scenarios/03-realm-user-group-role \
          scenarios/04-client-openid-connect \
          scenarios/05-tokens-jwt

  log INFO "Criando commit..."
  git commit -m "Adiciona laboratorios 03 04 e 05"

  log INFO "Enviando para o GitHub..."
  git push origin main
fi

echo
echo "============================================================"
echo " PRONTO"
echo "============================================================"
echo
echo "GitHub:"
echo "https://github.com/segurancadevops-sudo/keycloak-training"
echo
echo "Killercoda:"
echo "${KILLERCODA_URL}"
echo
echo "Cenários criados:"
echo "03 - Realm, Usuário, Grupo e Role"
echo "04 - Client e OpenID Connect"
echo "05 - Tokens e JWT"
echo
echo "Abra o Killercoda após alguns segundos para validar a sincronização."
echo "============================================================"
