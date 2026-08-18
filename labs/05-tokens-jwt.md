# Laboratorio 05 - Tokens e JWT

> Laboratorio pratico da Keycloak Training Academy.

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

---

# Passo 1 - Conhecer os Tokens

## Access Token

Usado para acessar recursos protegidos.

## Refresh Token

Usado para obter um novo Access Token sem exigir novo login.

## ID Token

Contém informações sobre a identidade do usuário autenticado.

---

# Passo 2 - Analisar um JWT

Um JWT é normalmente composto por três partes:

`Header.Payload.Signature`

## Header

Informa o tipo do token e o algoritmo de assinatura.

## Payload

Contém as informações, chamadas de claims.

## Signature

Permite verificar a integridade do token.

---

# Passo 3 - Identificar Claims

Em um token do Keycloak, procure claims como:

- `preferred_username`
- `email`
- `groups`
- `roles`

Essas informações podem ser utilizadas pelas aplicações para identificar o usuário e tomar decisões de autorização.

---

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

