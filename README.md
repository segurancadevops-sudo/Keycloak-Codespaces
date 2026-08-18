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
