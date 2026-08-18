#!/usr/bin/env bash

set -euo pipefail

BASE_DIR="scenarios/02-keycloak-docker"

echo "[INFO] Criando estrutura do Lab 02 em: ${BASE_DIR}"

mkdir -p "${BASE_DIR}"

cat > "${BASE_DIR}/index.json" <<'EOF'
{
  "title": "Keycloak com Docker",
  "description": "Execute o Keycloak em um container Docker e conheça seu funcionamento.",
  "details": {
    "intro": {
      "text": "intro.md"
    },
    "steps": [
      {
        "title": "Verificar o Docker",
        "text": "step1.md"
      },
      {
        "title": "Executar o Keycloak",
        "text": "step2.md"
      },
      {
        "title": "Validar o Keycloak",
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

cat > "${BASE_DIR}/intro.md" <<'EOF'
# Laboratório 02 - Keycloak com Docker

Neste laboratório você irá executar o Keycloak utilizando Docker.

## Objetivo

Ao final deste laboratório você será capaz de:

- verificar se o Docker está disponível;
- iniciar um container do Keycloak;
- verificar se o container está funcionando;
- compreender como o Keycloak pode ser executado em um ambiente containerizado.

Clique em **Start** para iniciar.
EOF

cat > "${BASE_DIR}/step1.md" <<'EOF'
# Passo 1 - Verificar o Docker

Antes de executar o Keycloak, vamos verificar se o Docker está disponível.

Execute:

`docker --version`

Depois execute:

`docker ps`

O primeiro comando apresenta a versão instalada.

O segundo apresenta os containers atualmente em execução.

Quando terminar, avance para o próximo passo.
EOF

cat > "${BASE_DIR}/step2.md" <<'EOF'
# Passo 2 - Executar o Keycloak

Agora vamos iniciar o Keycloak em um container Docker.

Execute:

`docker run -d --name keycloak -p 8080:8080 -e KC_BOOTSTRAP_ADMIN_USERNAME=admin -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin quay.io/keycloak/keycloak:latest start-dev`

A imagem poderá levar alguns instantes para ser baixada.

Depois execute:

`docker ps`

Localize o container chamado:

`keycloak`

Se ele estiver com status **Up**, o container está em execução.
EOF

cat > "${BASE_DIR}/step3.md" <<'EOF'
# Passo 3 - Validar o Keycloak

Vamos verificar se o Keycloak iniciou corretamente.

Execute:

`docker logs keycloak`

Procure nos logs uma indicação de que o servidor foi iniciado.

Depois teste localmente:

`curl -I http://localhost:8080`

Uma resposta HTTP confirma que o serviço está acessível.

Você acaba de executar sua primeira instância do Keycloak em Docker.
EOF

cat > "${BASE_DIR}/finish.md" <<'EOF'
# Laboratório concluído

Parabéns!

Neste laboratório você:

- verificou o Docker;
- baixou a imagem do Keycloak;
- iniciou o Keycloak em um container;
- verificou o container;
- consultou os logs;
- testou o serviço.

## Próximo laboratório

No próximo laboratório utilizaremos o Keycloak para trabalhar com:

- Realm;
- User;
- Group;
- Role.

Esses componentes formam a base da administração de identidades no Keycloak.
EOF

echo
echo "[OK] Lab 02 criado com sucesso."

echo
echo "[INFO] Estrutura criada:"
find "${BASE_DIR}" -maxdepth 1 -type f | sort

echo
echo "[INFO] Git status:"
git status --short