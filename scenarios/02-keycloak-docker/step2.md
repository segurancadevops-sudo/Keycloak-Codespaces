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
