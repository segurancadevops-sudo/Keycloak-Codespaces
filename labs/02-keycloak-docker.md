# Laboratorio 02 - Keycloak com Docker

> Laboratorio pratico da Keycloak Training Academy.

# Laboratório 02 - Keycloak com Docker

Neste laboratório você irá executar o Keycloak utilizando Docker.

## Objetivo

Ao final deste laboratório você será capaz de:

- verificar se o Docker está disponível;
- iniciar um container do Keycloak;
- verificar se o container está funcionando;
- compreender como o Keycloak pode ser executado em um ambiente containerizado.

Clique em **Start** para iniciar.

---

# Passo 1 - Verificar o Docker

Antes de executar o Keycloak, vamos verificar se o Docker está disponível.

Execute:

`docker --version`

Depois execute:

`docker ps`

O primeiro comando apresenta a versão instalada.

O segundo apresenta os containers atualmente em execução.

Quando terminar, avance para o próximo passo.

---

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

---

# Passo 3 - Validar o Keycloak

Vamos verificar se o Keycloak iniciou corretamente.

Execute:

`docker logs keycloak`

Procure nos logs uma indicação de que o servidor foi iniciado.

Depois teste localmente:

`curl -I http://localhost:8080`

Uma resposta HTTP confirma que o serviço está acessível.

Você acaba de executar sua primeira instância do Keycloak em Docker.

---

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

