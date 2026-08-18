# Laboratorio 04 - Client e OpenID Connect

> Laboratorio pratico da Keycloak Training Academy.

# Laboratório 04 - Client e OpenID Connect

Neste laboratório você irá criar uma aplicação integrada ao Keycloak.

## Objetivo

Ao final você será capaz de:

- compreender o que é um Client;
- criar um Client OpenID Connect;
- configurar o fluxo padrão de autenticação;
- entender a função da Redirect URI.

---

# Passo 1 - Criar o Client

No Realm `semfaz-lab`, acesse:

**Clients**

Crie um novo Client com:

- Client type: `OpenID Connect`
- Client ID: `portal-semfaz`

---

# Passo 2 - Configurar o Client

Configure:

- Standard Flow: habilitado
- Client Authentication: desabilitado

Defina uma Redirect URI de laboratório conforme o endereço utilizado no cenário.

## Conceito

A Redirect URI define para onde o Keycloak pode devolver o usuário após a autenticação.

---

# Passo 3 - Validar a Configuração

Confira no Client `portal-semfaz`:

- protocolo OpenID Connect;
- Standard Flow habilitado;
- Redirect URI cadastrada.

O Client agora representa uma aplicação que poderá utilizar o Keycloak para autenticação.

---

# Laboratório concluído

Você criou um Client OpenID Connect e conheceu os principais parâmetros utilizados na integração de aplicações.

## Próximo laboratório

Vamos conhecer os tokens gerados durante a autenticação e analisar um JWT.

