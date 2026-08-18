# Passo 3 - Validar o Keycloak

Vamos verificar se o Keycloak iniciou corretamente.

Execute:

`docker logs keycloak`

Procure nos logs uma indicação de que o servidor foi iniciado.

Depois teste localmente:

`curl -I http://localhost:8080`

Uma resposta HTTP confirma que o serviço está acessível.

Você acaba de executar sua primeira instância do Keycloak em Docker.
