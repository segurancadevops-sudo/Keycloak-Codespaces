# Como abrir o Keycloak no laboratório

1. Crie um Codespace novo a partir da branch `main`.
2. Aguarde o Codespace terminar a preparação.
3. No terminal execute:

```bash
./scripts/iniciar-keycloak.sh
```

O script:

- aguarda o Docker ficar pronto;
- configura a porta 8080;
- inicia o Keycloak;
- aguarda o serviço responder;
- valida o hostname e o issuer;
- valida a URL externa;
- somente então tenta abrir o navegador.

## Regra importante

No Codespaces, use sempre a URL:

```text
https://NOME-DO-CODESPACE-8080.app.github.dev
```

Não utilize `http://localhost:8080` como URL do aluno.

## Se houver problema

Execute:

```bash
./scripts/diagnosticar-abertura.sh
```

A porta 8080 é configurada como pública para evitar que a camada de autenticação
de portas privadas do Codespaces interfira no Admin Console do Keycloak.

O Keycloak continua protegido pela autenticação própria do laboratório.
